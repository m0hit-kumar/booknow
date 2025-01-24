import 'dart:convert';

import 'package:booknow/models/user_model.dart';
import 'package:booknow/screens/book_appoitment.dart';
import 'package:booknow/services/auth_service.dart';
import 'package:booknow/services/offline_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final _authService = AuthService();

  String? patientId;
  User? user;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = fetchCurrentUserId();
  }

  Future<void> fetchCurrentUserId() async {
    try {
      final sharedPrefs = SharedPrefsUtil();
      await sharedPrefs.init();
      final User? currentUser = sharedPrefs.get<User>('user',
          fromJson: (json) => User.fromJson(json));

      if (currentUser != null) {
        setState(() {
          user = currentUser;
          patientId = currentUser.userId;
        });
      } else {
        print('No user data found in SharedPreferences');
        // Handle the case where no user data is found
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Handle any errors that occur during data fetching
    }
  }
 
  void _launchDialer(String number) async {
    final Uri dialerUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(dialerUri)) {
      await launchUrl(dialerUri);
    } else {
      throw 'Could not launch $number';
    }
  }

  Future<Map<String, dynamic>> fetchDoctorDetails(String doctorId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      print("Error fetching doctor details: $e");
    }
    return {};
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      // Find the specific document for the appointment
      DocumentReference appointmentDocRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.doctorId); // Using doctorName as the document ID

      // Get the current document
      DocumentSnapshot docSnapshot = await appointmentDocRef.get();

      // Parse the slots
      Map<String, dynamic> slots = docSnapshot.get('slots') ?? {};
       // Format the date key
      String dateKey =
          '${appointment.dateTime.year}-${appointment.dateTime.month.toString().padLeft(2, '0')}-${appointment.dateTime.day.toString().padLeft(2, '0')}';

      // Find the specific slot to update
      List<dynamic> daySlots = slots[dateKey] ?? [];

      // Find the index of the slot to update
      int slotIndex = daySlots.indexWhere((slot) =>
          slot['time'] ==
              appointment
                  .slotTime && // Assuming you add slotTime to Appointment
          slot['patientId'] == patientId);

      if (slotIndex != -1) {
        // Update the specific slot
        daySlots[slotIndex] = {
          ...daySlots[slotIndex],
          'isBooked': false,
          'isAvailable': true,
          'patientId': null,
          'patientName': '',
          'patientPhone': ''
        };

        // Update the document
        await appointmentDocRef.update({'slots.$dateKey': daySlots});

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Appointment cancelled successfully')),
        );
      }
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to cancel appointment')),
      );
    }
  }

  Stream<List<Appointment>> getAppointments() async* {
    final snapshots =
        FirebaseFirestore.instance.collection('appointments').snapshots();
    await for (var snapshot in snapshots) {
      List<Appointment> appointments = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final slots = data['slots'] as Map<String, dynamic>?;
        if (slots == null) continue;

        final doctorDetails = await fetchDoctorDetails(doc.id);

        slots.forEach((dateKey, slotList) {
          final DateTime appointmentDate = DateTime.parse(dateKey);
          final filteredSlots =
              slotList.where((slot) => slot['patientId'] == patientId).toList();

          for (final slot in filteredSlots) {
             final timeRange = slot['time'].split(' - ');
            final startTime = timeRange[0];
            final startDateTime = DateTime(
              appointmentDate.year,
              appointmentDate.month,
              appointmentDate.day,
              int.parse(startTime.split(':')[0]),
              int.parse(startTime.split(':')[1]),
            );

            appointments.add(Appointment(
              doctorId: doc.id,
              doctorName: doctorDetails['fullName'] ?? 'Unknown',
              specialty: doctorDetails['title'] ?? 'Unknown',
              dateTime: startDateTime,
              status: _determineStatus(slot, startDateTime),
              phoneNumber: doctorDetails['phoneNumber'] ?? 'N/A',
              slotTime: slot['time'],
            ));
          }
        });
      }
      yield appointments;
    }
  }

  String _determineStatus(Map<String, dynamic> slot, DateTime appointmentTime) {
    if (slot['isAvailable'] == false) return 'Cancelled';
    if (slot['isBooked'] == true) {
      if (appointmentTime.isBefore(DateTime.now())) return 'Completed';
      return 'Scheduled';
    }
    return 'Unknown';
  }

  Future<void> _showBookAppointmentModal(BuildContext context) async {
    print("00000000000000000000000000000000${user?.name}");
    SharedPreferences prefs = await SharedPreferences.getInstance();
String? userString = prefs.getString('user');
if (userString != null) {
  Map<String, dynamic> userMap = json.decode(userString);
  User retrievedUser = User.fromJson(userMap);
  print("00000000000000000000000011 ${retrievedUser.name}");
}
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookAppointment(
          patientId: patientId ?? '',
          patientName: user?.name ?? '',
          patientPhone: 'N/A',
        ),
      ),
    );
  }

  void _handleLogout() {
    _authService.signOut();
    Navigator.of(context)
        .pushReplacementNamed('/login'); // Adjust according to your route name
  }

bool showBanner = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildBanner(showBanner),
                    const SizedBox(height: 24),
                    Expanded(
                      child: StreamBuilder<List<Appointment>>(
                        stream: getAppointments(),

                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading appointments.'));
                          }
                          final appointments = snapshot.data ?? [];
                             showBanner = appointments.any((a) => a.status == 'Cancelled');
                         

                          if (appointments.isEmpty) {
                            return const Center(
                                child: Text('No appointments found.'));
                          }
                          return ListView.separated(
                            itemCount: appointments.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) =>
                                _buildAppointmentCard(appointments[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookAppointmentModal(context),
        label: const Text('Book Appointment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${user?.name ?? 'there'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage your appointments',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

 Widget _buildBanner(bool showBanner) {
  if (!showBanner) return const SizedBox(); // Return empty widget if no cancelled appointments

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.red[100]!),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'One or more appointments have been canceled. Check your schedule.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildAppointmentCard(Appointment appointment) {
    print("0000000000000000000${appointment.status}");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    appointment.specialty,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              _buildStatusChip(appointment.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${appointment.dateTime.hour}:${appointment.dateTime.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  onPressed: () {
                    _launchDialer(appointment.phoneNumber);
                  },
                ),
              ),
              const SizedBox(width: 12),
             appointment.status!="Cancelled"? Expanded(
                child: ElevatedButton.icon(
                   icon: const Icon(Icons.close),
                  label: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appointment.status=="Cancelled"?Colors.grey : Colors.red,
                  ),
                  onPressed: () {
                    _cancelAppointment(appointment);
                  },
                ),
              ):SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Scheduled':
        chipColor = Colors.green;
        break;
      case 'Completed':
        chipColor = Colors.blue;
        break;
      case 'Cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class Appointment {
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final String status;
  final String phoneNumber;
  final String doctorId;
  final String slotTime;

  Appointment({
    required this.slotTime,
    required this.phoneNumber,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.status,
  });
}
