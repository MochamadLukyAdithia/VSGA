import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vsga/app/models/Accellerator.dart';
import 'package:vsga/app/service/accelerator_service.dart';

class SensorAccelerometerScreen extends StatefulWidget {
  const SensorAccelerometerScreen({super.key});

  @override
  State<SensorAccelerometerScreen> createState() =>
      _SensorAccelerometerScreenState();
}

class _SensorAccelerometerScreenState extends State<SensorAccelerometerScreen> {
  double _accX = 0;
  double _accY = 0;
  double _accZ = 0;
  bool _isListening = false;

  StreamSubscription<AccelerometerEvent>? _subAcc;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subAcc?.cancel();
    super.dispose();
  }

  void _bacaSensor() {
    setState(() {
      _isListening = true;
    });
    _subAcc =
        accelerometerEventStream(
          samplingPeriod: Duration(milliseconds: 500),
        ).listen((AccelerometerEvent event) {
          setState(() {
            _accX = event.x;
            _accY = event.y;
            _accZ = event.z;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sensor Accelerometer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: $_accX"),
            Text("Y: $_accY"),
            Text("Z: $_accZ"),
            SizedBox(height: 20),
            if (_isListening == false)
              Text("Tekan tombol untuk mulai membaca sensor"),
            ElevatedButton(
              onPressed: () {
                _bacaSensor();
                AcceleratorService().insertAacceleratorData(
                  Accellerator(
                    x: _accX,
                    y: _accY,
                    z: _accZ,
                    timestamp: DateTime.now(),
                  ),
                );
              },
              child: Text("Mulai Baca Sensor"),
            ),
          ],
        ),
      ),
    );
  }
}
