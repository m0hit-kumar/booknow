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

  late DateTime selectedDate=DateTime.now();
  late List<DateTime> weekDates;
  Map<String, List<String>> bookedSlots = {};

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

  // bool _isPastDate(String dateStr) {
  //   final date = DateFormat('yyyy-MM-dd').parse(dateStr);
  //   final today = DateTime.now();
  //   return date.isBefore(DateTime(today.year, today.month, today.day));
  // }

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

          // Booked Slots Display
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('appointments').doc(widget.doctorId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...');
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final slots = data['slots'] as Map<String, dynamic>;

                // Update bookedSlots based on the snapshot
                bookedSlots = {};
                slots.forEach((date, slotList) {
                  if (slotList is List) {
                    bookedSlots[date] = slotList
                        .where((slotData) => slotData['isBooked'] == true)
                        .map((slotData) => slotData['time'] as String)
                        .toList();
                  }
                });

                return Padding(
                  padding: EdgeInsets.all(20),
                  child: bookedSlots[dateStr] == null || bookedSlots[dateStr]!.isEmpty
                      ? Center(
                          child: Text('No booked slots for this day'),
                        )
                      : ListView.builder(
                          itemCount: bookedSlots[dateStr]!.length,
                          itemBuilder: (context, index) {
                            String slot = bookedSlots[dateStr]![index];
                            return Card(
                              elevation: 2,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(slot),
                                subtitle: Text('Booked'),
                                leading: Icon(Icons.check_circle, color: Colors.green),
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
