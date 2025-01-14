import 'package:booknow/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfilePage extends StatefulWidget {
  final String userId;

  const DoctorProfilePage({super.key, required this.userId});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
final _authService = AuthService();
  String fullName = '';
  String phoneNumber = '';
  String post = '';
  String title = '';

  late Stream<DocumentSnapshot> _doctorStream;

  @override
  void initState() {
    super.initState();
    _doctorStream = _firestore.collection('users').doc(widget.userId).snapshots();
  }

  Future<void> _updateDoctorData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await _firestore.collection('users').doc(widget.userId).update({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'post': post,
          'title': title,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.green, content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        print("Error updating doctor data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text('Failed to update profile!')),
        );
      }
    }
  }

  void _handleLogout() {
   _authService.signOut();
    Navigator.of(context).pushReplacementNamed('/login'); // Adjust according to your route name
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Profile'),
        backgroundColor: Colors.white,
        elevation: 4.0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _doctorStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error fetching profile data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          fullName = data['fullName'] ?? '';
          phoneNumber = data['phoneNumber'] ?? '';
          post = data['post'] ?? '';
          title = data['title'] ?? '';

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/doctor_avatar.png'),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Center(
                        child: Text(
                          'Doctor Profile',
                          style: TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),
                      _buildInputField(
                        label: 'Full Name',
                        initialValue: fullName,
                        icon: Icons.person,
                        onChanged: (value) => fullName = value,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Full Name cannot be empty' : null,
                      ),
                      SizedBox(height: 16.0),
                      _buildInputField(
                        label: 'Phone Number',
                        initialValue: phoneNumber,
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) => phoneNumber = value,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Phone Number cannot be empty' : null,
                      ),
                      SizedBox(height: 16.0),
                      _buildInputField(
                        label: 'Post',
                        initialValue: post,
                        icon: Icons.work,
                        onChanged: (value) => post = value,
                      ),
                      SizedBox(height: 16.0),
                      _buildInputField(
                        label: 'Title',
                        initialValue: title,
                        icon: Icons.title,
                        onChanged: (value) => title = value,
                      ),
                      SizedBox(height: 120.0), // Increased to accommodate both buttons
                    ],
                  ),
                ),
              ),
              
              Positioned(
                bottom: 0.0,
                left: 16.0,
                right: 16.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateDoctorData,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.green,
                          side: BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogout,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String initialValue,
    required IconData icon,
    required ValueChanged<String> onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }
}