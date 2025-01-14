import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorAppointments extends StatefulWidget {
  final String doctorId;

  const DoctorAppointments({super.key, required this.doctorId});

  @override
  State<DoctorAppointments> createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DateTime selectedDate = DateTime.now();
  late List<DateTime> weekDates;
  // Changed the type definition here
  Map<String, List<dynamic>> bookedSlots = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _generateWeekDates();
  }

  void _generateWeekDates() {
    DateTime monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  Future<void> _cancelAppointment(String dateStr, String time) async {
    try {
      DocumentReference docRef = _firestore.collection('appointments').doc(widget.doctorId);
      
      // Get the current document data
      DocumentSnapshot doc = await docRef.get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> slots = data['slots'] as Map<String, dynamic>;
      
      // Find and update the specific slot
      List<dynamic> dateSlots = slots[dateStr] as List<dynamic>;
      int slotIndex = dateSlots.indexWhere((slot) => slot['time'] == time);
      
      if (slotIndex != -1) {
        dateSlots[slotIndex]['isBooked'] = false;
        dateSlots[slotIndex]['isAvailable'] = false;
        
        // Update Firestore
        await docRef.update({
          'slots': slots
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Booked Slots',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Calendar Strip
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.white,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      bool isSelected = weekDates[index].day == selectedDate.day;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = weekDates[index];
                          });
                        },
                        child: Container(
                          width: 65,
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE').format(weekDates[index]),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                DateFormat('d').format(weekDates[index]),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Booked Slots Display
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('appointments').doc(widget.doctorId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading appointments',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final slots = data['slots'] as Map<String, dynamic>;

                // Update bookedSlots based on the snapshot
                bookedSlots.clear();
                slots.forEach((date, slotList) {
                  if (slotList is List) {
                    bookedSlots[date] = (slotList as List<dynamic>)
                        .where((slotData) => slotData['isBooked'] == true)
                        .toList();
                  }
                });

                return Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointments for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: bookedSlots[dateStr] == null || bookedSlots[dateStr]!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No appointments scheduled for this day',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: bookedSlots[dateStr]!.length,
                                itemBuilder: (context, index) {
                                  final slot = bookedSlots[dateStr]![index] as Map<String, dynamic>;
                                  return Card(
                                    elevation: 3,
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          colors: [Colors.white, Colors.blue.withOpacity(0.1)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue.withOpacity(0.2),
                                          child: Icon(
                                            Icons.access_time,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        title: Text(
                                          slot['time'] ?? 'No time specified',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 4),
                                            Text(
                                              'Patient: ${slot['patientName'] ?? 'Unknown'}',
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                            Text(
                                              'Phone: ${slot['patientPhone'] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                        trailing: TextButton.icon(
                                          icon: Icon(Icons.cancel, color: Colors.red),
                                          label: Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Cancel Appointment'),
                                                  content: Text(
                                                    'Are you sure you want to cancel this appointment?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      child: Text('No'),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                    ),
                                                    TextButton(
                                                      child: Text(
                                                        'Yes',
                                                        style: TextStyle(color: Colors.red),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                        _cancelAppointment(dateStr, slot['time']);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}