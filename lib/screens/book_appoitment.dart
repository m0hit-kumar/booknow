import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookAppointment extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String patientPhone;

  const BookAppointment({
    super.key, 
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
  });

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late DateTime selectedDate = DateTime.now();
  late List<DateTime> weekDates;
  String? selectedDoctor;
  int bufferTime = 15; 
  Map<String, Map<String, int>> slotBuffers = {};

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

  void _setBufferTime(String dateStr, String slot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempBuffer = slotBuffers[dateStr]?[slot] ?? bufferTime;
        return AlertDialog(
          title: const Text('Set Buffer Time'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Buffer time in minutes: $tempBuffer'),
                  Slider(
                    value: tempBuffer.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 12,
                    onChanged: (value) {
                      setState(() {
                        tempBuffer = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  if (slotBuffers[dateStr] == null) {
                    slotBuffers[dateStr] = {};
                  }
                  slotBuffers[dateStr]![slot] = tempBuffer;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookAppointment(String doctorId, String dateStr, String time) async {
    try {
      DocumentReference docRef = _firestore.collection('appointments').doc(doctorId);
      
      // Get the current document data
      DocumentSnapshot doc = await docRef.get();
      
      // If document doesn't exist, create initial structure
      if (!doc.exists) {
        await docRef.set({
          'slots': {
            dateStr: []
          }
        });
        doc = await docRef.get();
      }
      
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> slots = data['slots'] as Map<String, dynamic>;
      
      // If no slots for this date, initialize empty array
      if (!slots.containsKey(dateStr)) {
        slots[dateStr] = [];
      }
      
      List<dynamic> dateSlots = slots[dateStr] as List<dynamic>;
      int slotIndex = dateSlots.indexWhere((slot) => slot['time'] == time);
      
      if (slotIndex != -1) {
        dateSlots[slotIndex]['isBooked'] = true;
        dateSlots[slotIndex]['patientId'] = widget.patientId;
        dateSlots[slotIndex]['patientName'] = widget.patientName;
        dateSlots[slotIndex]['patientPhone'] = widget.patientPhone;
        dateSlots[slotIndex]['bufferTime'] = slotBuffers[dateStr]?[time] ?? bufferTime;
      } else {
        // Add new slot if it doesn't exist
        dateSlots.add({
          'time': time,
          'isBooked': true,
          'patientId': widget.patientId,
          'patientName': widget.patientName,
          'patientPhone': widget.patientPhone,
          'bufferTime': slotBuffers[dateStr]?[time] ?? bufferTime,
        });
      }
      
      // Update Firestore
      await docRef.update({
        'slots': slots
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    bool isPastDate = selectedDate.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Book Appointment',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Doctor Selection
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users')
                  .where('role', isEqualTo: 'doctor')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                List<DropdownMenuItem<String>> doctorItems = [];
                for (var doc in snapshot.data!.docs) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  doctorItems.add(DropdownMenuItem(
                    value: doc.id,
                    child: Text('${data['fullName']} - ${data['title']}'),
                  ));
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedDoctor,
                  items: doctorItems,
                  onChanged: (value) {
                    setState(() {
                      selectedDoctor = value;
                    });
                  },
                );
              },
            ),
          ),

          // Calendar Strip
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: Colors.white,
            child: SingleChildScrollView(
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
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                          const SizedBox(height: 5),
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
          ),

          // Time Slots
          if (selectedDoctor != null)
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('appointments')
                    .doc(selectedDoctor)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // If no data exists for this doctor
                  if (!snapshot.data!.exists) {
                    return const Center(
                      child: Text('No available slots'),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final slots = data['slots'] as Map<String, dynamic>?;

                  // If no slots exist for this date
                  if (slots == null || !slots.containsKey(dateStr)) {
                    return const Center(
                      child: Text('No available slots for selected date'),
                    );
                  }

                  List<dynamic> dateSlots = slots[dateStr] as List<dynamic>;
                  dateSlots.sort((a, b) => a['time'].compareTo(b['time']));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: dateSlots.length,
                      itemBuilder: (context, index) {
                        final slot = dateSlots[index];
                        final time = slot['time'] as String;
                        // final isBooked = slot['isBooked'] ?? false;
                        // final isAvailable = !isBooked && !isPastDate;
                        final bufferTime = slot['bufferTime'] ?? this.bufferTime;
final isBooked = slot['isBooked'] ?? false;
final isAvailable = slot['isAvailable'] ?? false;

// Determine slot state and color
bool isBookedSlot = isAvailable && isBooked;
bool isUnavailableSlot = !isAvailable;
bool isOpenSlot = isAvailable && !isBooked;
                        return GestureDetector(
                          onTap: isBooked || isPastDate ? null : () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Booking'),
                                  content: Text(
                                    'Book appointment for $time?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Book'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _bookAppointment(
                                          selectedDoctor!,
                                          dateStr,
                                          time,
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onLongPress: isBooked || isPastDate ? null : () => _setBufferTime(dateStr, time),
                          child: 
                          Container(
    decoration: BoxDecoration(
      color: isBookedSlot 
          ? Colors.grey.withValues(alpha:0.1)  // Grey when booked
          : isUnavailableSlot 
              ? Colors.red.withValues(alpha:0.1)  // Red when unavailable
              : Colors.green.withValues(alpha:0.1),  // Green when available
      border: Border.all(
        color: isBookedSlot 
            ? Colors.grey 
            : isUnavailableSlot 
                ? Colors.red 
                : Colors.green,
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          time,
          style: TextStyle(
            color: isBookedSlot 
                ? Colors.grey.shade700
                : isUnavailableSlot 
                    ? Colors.red.shade700 
                    : Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isBookedSlot 
              ? 'Booked'
              : isUnavailableSlot 
                  ? 'Unavailable' 
                  : 'Buffer: ${bufferTime}min',
          style: TextStyle(
            color: isBookedSlot 
                ? Colors.grey.shade700
                : isUnavailableSlot 
                    ? Colors.red.shade700 
                    : Colors.green.shade700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
                        );
                      },
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