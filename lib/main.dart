 
import 'package:booknow/firebase_options.dart';
import 'package:booknow/models/user_model.dart';
import 'package:booknow/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/offline_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

 final sharedPrefs = SharedPrefsUtil();
await sharedPrefs.init();
 String initialRoute = '/login';

  final User? currentUser = sharedPrefs.get<User>('user',fromJson: (json) => User.fromJson(json) );
  if (currentUser != null) {
     final String role = currentUser.role;
    if (role == 'patient') {
      initialRoute = '/patient-dashboard';
    } else if (role == 'doctor') {
      initialRoute = '/doctor-dashboard';
    }
  }
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
 final String initialRoute;
  const MyApp({super.key, required this.initialRoute});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
    routes: appRoutes,
    );
  }
}
 