import 'package:booknow/screens/doctor_appointments.dart';
import 'package:booknow/screens/doctor_profile_page.dart';
import 'package:booknow/screens/doctor_slots_page.dart';
import 'package:flutter/material.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;

  // List of pages corresponding to each navigation item
  final List<Widget> _pages = [
    DoctorAppointments(doctorId: "rWIkaskKuabnDEBfCjjPixgpm4g1", ),
    DoctorWeeklySlotPage(doctorId: "rWIkaskKuabnDEBfCjjPixgpm4g1"),
    DoctorProfilePage(userId: "rWIkaskKuabnDEBfCjjPixgpm4g1"),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Slots',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}