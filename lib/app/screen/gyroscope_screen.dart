import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorGyroscopeScreen extends StatefulWidget {
  const SensorGyroscopeScreen({super.key});

  @override
  State<SensorGyroscopeScreen> createState() => _SensorGyroscopeScreenState();
}

class _SensorGyroscopeScreenState extends State<SensorGyroscopeScreen> {
  StreamSubscription? _subGyro;
  double _gyroX = 0;
  double _gyroY = 0;
  double _gyroZ = 0;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subGyro?.cancel();
    super.dispose();
  }

  void _bacaSensor() {
    _subGyro = gyroscopeEventStream(samplingPeriod: Duration(milliseconds: 500))
        .listen((GyroscopeEvent event) {
          print("Gyroscope: x=${event.x}, y=${event.y}, z=${event.z}");
          setState(() {
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sensor Gyroscope")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isListening == false)
              const Text("Tekan tombol untuk mulai membaca sensor"),

            Text('X (Roll): ${_gyroX.toStringAsFixed(2)}'),
            Text('Y (Pitch): ${_gyroY.toStringAsFixed(2)}'),
            Text('Z (Yaw): ${_gyroZ.toStringAsFixed(2)}'),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Gerakkan perangkat untuk melihat perubahan nilai. '
                'Nilai positif menunjukkan rotasi berlawanan arah jarum jam '
                'di sekitar sumbu terkait dari perspektif perangkat.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _bacaSensor();
              },
              child: const Text("Mulai"),
            ),
          ],
        ),
      ),
    );
  }
}
