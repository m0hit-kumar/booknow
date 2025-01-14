import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DoctorWeeklySlotPage extends StatefulWidget {
  final String doctorId;

  const DoctorWeeklySlotPage({super.key, required this.doctorId});

  @override
  _DoctorWeeklySlotPageState createState() => _DoctorWeeklySlotPageState();
}

class _DoctorWeeklySlotPageState extends State<DoctorWeeklySlotPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late DateTime selectedDate;
  late List<DateTime> weekDates;
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);
  int slotDuration = 30;
  int bufferTime = 10;
  
  Map<String, List<String>> generatedSlots = {};
  Map<String, Map<String, bool>> slotAvailability = {};
  Map<String, Map<String, int>> slotBuffers = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _generateWeekDates();
    _loadExistingSlots();
  }

  Future<void> _loadExistingSlots() async {
    try {
      final doc = await _firestore.collection('appointments').doc(widget.doctorId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Load existing configuration if available
        if (data.containsKey('settings')) {
          final settings = data['settings'] as Map<String, dynamic>;
          setState(() {
            slotDuration = settings['slotDuration'] ?? 30;
            bufferTime = settings['defaultBuffer'] ?? 10;
            // Parse time strings back to TimeOfDay
            final startTimeStr = settings['startTime']?.split(':');
            final endTimeStr = settings['endTime']?.split(':');
            if (startTimeStr != null && startTimeStr.length == 2) {
              startTime = TimeOfDay(
                hour: int.parse(startTimeStr[0]),
                minute: int.parse(startTimeStr[1]),
              );
            }
            if (endTimeStr != null && endTimeStr.length == 2) {
              endTime = TimeOfDay(
                hour: int.parse(endTimeStr[0]),
                minute: int.parse(endTimeStr[1]),
              );
            }
          });
        }
        _generateTimeSlots();
      }
    } catch (e) {
      print('Error loading existing slots: $e');
    }
  }

  void _generateWeekDates() {
    DateTime monday = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );
    weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _generateTimeSlots() {
    generatedSlots.clear();
    slotAvailability.clear();
    slotBuffers.clear();

    for (DateTime date in weekDates) {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      List<String> dailySlots = [];
      Map<String, bool> dailyAvailability = {};
      Map<String, int> dailyBuffers = {};

      int startMinutes = startTime.hour * 60 + startTime.minute;
      int endMinutes = endTime.hour * 60 + endTime.minute;

      while (startMinutes + slotDuration <= endMinutes) {
        int endSlotMinutes = startMinutes + slotDuration;
        String slot = '${_minutesToTimeString(startMinutes)} - ${_minutesToTimeString(endSlotMinutes)}';
        
        dailySlots.add(slot);
        dailyAvailability[slot] = true;
        dailyBuffers[slot] = bufferTime;
        
        startMinutes = endSlotMinutes + bufferTime;
      }

      generatedSlots[dateStr] = dailySlots;
      slotAvailability[dateStr] = dailyAvailability;
      slotBuffers[dateStr] = dailyBuffers;
    }
    setState(() {});
  }

  String _minutesToTimeString(int minutes) {
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTimeRange() async {
    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (newStartTime != null) {
      final TimeOfDay? newEndTime = await showTimePicker(
        context: context,
        initialTime: endTime,
      );
      if (newEndTime != null) {
        setState(() {
          startTime = newStartTime;
          endTime = newEndTime;
          _generateTimeSlots();
        });
      }
    }
  }

  Future<void> _configureSlotSettings() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure Slot Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Slot Duration (minutes)',
                hintText: slotDuration.toString(),
              ),
              onChanged: (value) {
                if (int.tryParse(value) != null) {
                  setState(() {
                    slotDuration = int.parse(value);
                  });
                }
              },
            ),
            SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Default Buffer Time (minutes)',
                hintText: bufferTime.toString(),
              ),
              onChanged: (value) {
                if (int.tryParse(value) != null) {
                  setState(() {
                    bufferTime = int.parse(value);
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _generateTimeSlots();
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _setBufferTime(String date, String slot) async {
    final controller = TextEditingController(
      text: slotBuffers[date]?[slot].toString(),
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Buffer Time'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Buffer Time (minutes)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                slotBuffers[date]?[slot] = int.tryParse(controller.text) ?? bufferTime;
              });
              Navigator.pop(context);
            },
            child: Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishSlots() async {
    try {
      final slots = {};
      for (String date in generatedSlots.keys) {
        slots[date] = generatedSlots[date]?.map((slot) => {
          'time': slot,
          'isAvailable': slotAvailability[date]?[slot] ?? false,
          'bufferTime': slotBuffers[date]?[slot] ?? bufferTime,
        }).toList();
      }

      await _firestore.collection('appointments').doc(widget.doctorId).set({
        'slots': slots,
        'settings': {
          'slotDuration': slotDuration,
          'defaultBuffer': bufferTime,
          'startTime': _timeOfDayToString(startTime),
          'endTime': _timeOfDayToString(endTime),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Schedule published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish schedule: $e'),
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
          'Weekly Schedule',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black87),
            onPressed: _configureSlotSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Strip
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.access_time),
                            onPressed: _selectTimeRange,
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                selectedDate = selectedDate.subtract(Duration(days: 7));
                                _generateWeekDates();
                                _generateTimeSlots();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                selectedDate = selectedDate.add(Duration(days: 7));
                                _generateWeekDates();
                                _generateTimeSlots();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
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

          // Time Range Display
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time Slots (${startTime.format(context)} - ${endTime.format(context)})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${slotDuration}min slots',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Time Slots Grid
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: generatedSlots[dateStr] == null
                  ? Center(child: Text('No slots generated for this date'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: generatedSlots[dateStr]?.length ?? 0,
                      itemBuilder: (context, index) {
                        String slot = generatedSlots[dateStr]![index];
                        bool isAvailable = slotAvailability[dateStr]?[slot] ?? true;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              slotAvailability[dateStr]?[slot] = !isAvailable;
                            });
                          },
                          onLongPress: () => _setBufferTime(dateStr, slot),
                          child: Container(
                            decoration: BoxDecoration(
                              color:  isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              border: Border.all(
                                color: isAvailable ? Colors.green : Colors.red,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot,
                                  style: TextStyle(
                                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Buffer: ${slotBuffers[dateStr]?[slot] ?? bufferTime}min',
                                  style: TextStyle(
                                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Publish Button
          Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _publishSlots,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Publish Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}