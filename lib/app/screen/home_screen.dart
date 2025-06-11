import 'package:flutter/material.dart';
import 'package:vsga/app/models/User.dart';
import 'package:vsga/app/screen/accelerometer_screen.dart';
import 'package:vsga/app/screen/gmaps_screen.dart';
import 'package:vsga/app/screen/gyroscope_screen.dart';

import 'login_screen.dart';
// Import screen yang diperlukan sesuai path Anda
// import 'package:vsga/app/screen/accelerometer_screen.dart';
// import 'package:vsga/app/screen/gmaps_screen.dart';
// import 'package:vsga/app/screen/gyroscope_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ini Halaman Home'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade600, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                user.username.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.email, 'Email', user.email),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Bergabung',
                          DateTime.parse(
                            user.createdAt,
                          ).toString().split(' ')[0],
                        ),
                      ],
                    ),
                  ),
                ),

                // Sensor Buttons
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSensorButton(
                        context,
                        Icons.vibration,
                        'Accelerometer',
                        Colors.blue,
                        () {
                          // Uncomment dan sesuaikan path import
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SensorAccelerometerScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSensorButton(
                        context,
                        Icons.rotate_right,
                        'Gyroscope',
                        Colors.green,
                        () {
                          // Uncomment dan sesuaikan path import
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SensorGyroscopeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSensorButton(
                        context,
                        Icons.map,
                        'Google Maps',
                        Colors.orange,
                        () {
                          // Uncomment dan sesuaikan path import
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GpsAndMapScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildSensorButton(
    BuildContext context,
    IconData icon,
    String title,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          shadowColor: color.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}
