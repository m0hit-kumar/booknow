
import 'package:flutter/material.dart';
class MenuItem {
  final String title;
  final String description;
  final Color backgroundColor;
  final Color iconColor;
  final String routeName;
  final IconData icon;

  MenuItem({
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.iconColor,
    required this.routeName,
    required this.icon,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  final String userName = "Sarah";

  List<MenuItem> get menuItems => [
        MenuItem(
          title: "Appointments",
          description: "Schedule and manage your upcoming medical visits",
          backgroundColor: const Color(0xFF6C63FF).withValues(alpha:0.1),
          iconColor: const Color(0xFF6C63FF), // Bright indigo
          routeName: "/appointments",
          icon: Icons.calendar_today_rounded,
        ),
        MenuItem(
          title: "Medical Records",
          description: "Access your complete health history and documents",
          backgroundColor: const Color(0xFF00D9F5).withValues(alpha:0.1),
          iconColor: const Color(0xFF00D9F5), // Bright cyan
          routeName: "/records",
          icon: Icons.folder_outlined,
        ),
        MenuItem(
          title: "Medications",
          description: "Track your prescriptions and set reminders",
          backgroundColor: const Color(0xFFFF6B6B).withValues(alpha:0.1),
          iconColor: const Color(0xFFFF6B6B), // Bright coral
          routeName: "/medications",
          icon: Icons.medical_services_outlined,
        ),
        MenuItem(
          title: "Lab Results",
          description: "View and track your test results over time",
          backgroundColor: const Color(0xFF4CD964).withValues(alpha:0.1),
          iconColor: const Color(0xFF4CD964), // Bright green
          routeName: "/lab_results",
          icon: Icons.science_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGreeting(),
              const SizedBox(height: 12),
              _buildUpcomingAppointment(),
              const SizedBox(height: 32),
              Expanded(
                child: _buildMenuGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
            iconSize: 28,
            color: Colors.black87,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            iconSize: 28,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.black,
        ),
        children: [
          const TextSpan(
            text: 'Hi, ',
            style: TextStyle(
              fontWeight: FontWeight.w300,
            ),
          ),
          TextSpan(
            text: userName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Upcoming Appointment: March 15, 2024',
        style: TextStyle(
          color: const Color(0xFF6C63FF),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: menuItems.map((item) => _buildMenuItem(context, item)).toList(),
    );
  }

  Widget _buildMenuItem(BuildContext context, MenuItem item) {
    return GestureDetector(
      onTap: () {
        print('Navigating to: ${item.routeName}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.iconColor.withValues(alpha:0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: item.iconColor.withValues(alpha:0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.icon,
                size: 26,
                color: item.iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}