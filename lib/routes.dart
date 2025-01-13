import 'package:booknow/screens/auth_screen.dart';
import 'package:booknow/screens/patient_dashboard.dart';
import 'package:flutter/material.dart';
 

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => AuthScreen(),
  '/patient-dashboard': (context) => PatientDashboard(),
  // '/doctor-dashboard': (context) => DoctorDashboard(),
};
