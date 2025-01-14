import 'package:flutter/material.dart';
 

class DoctorAppointments extends StatefulWidget {
  const DoctorAppointments({super.key});

  @override
  _DoctorAppointmentsState createState() => _DoctorAppointmentsState();
}

class _DoctorAppointmentsState extends State<DoctorAppointments> {
   
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(child: Text("appoitments") ));
  }
}