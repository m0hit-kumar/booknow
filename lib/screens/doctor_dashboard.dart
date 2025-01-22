import 'package:booknow/models/user_model.dart';
import 'package:booknow/screens/doctor_appointments.dart';
import 'package:booknow/screens/doctor_profile_page.dart';
import 'package:booknow/screens/doctor_slots_page.dart';
import 'package:booknow/services/offline_store.dart';
import 'package:flutter/material.dart';

class DoctorDashboard extends StatefulWidget {
 const DoctorDashboard({super.key});

 @override
 State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
 String? userId;
 int _selectedIndex = 0;
 late Future<void> _initFuture;

 @override
 void initState() {
   super.initState();
   _initFuture = fetchCurrentUserId();
 }

 Future<void> fetchCurrentUserId() async {
   final sharedPrefs = SharedPrefsUtil();
   await sharedPrefs.init();
   final User? currentUser = sharedPrefs.get<User>('user', 
     fromJson: (json) => User.fromJson(json));
   
   if (currentUser != null) {
     setState(() {
       userId = currentUser.userId;
     });
   }
 }

 void _onItemTapped(int index) {
   setState(() {
     _selectedIndex = index;
   });
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     backgroundColor: Colors.blueGrey.shade50,
     body: FutureBuilder(
       future: _initFuture,
       builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting || userId == null) {
           return const Center(child: CircularProgressIndicator());
         }

         final pages = [
           DoctorAppointments(doctorId: userId!),
           DoctorWeeklySlotPage(userId: userId!),
           DoctorProfilePage(userId: userId!),
         ];

         return pages[_selectedIndex];
       },
     ),
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