import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  var label = "koordinat lokasi saat ini: ";

  _bacaLokasi() async {
    var isEnabled = await Geolocator.isLocationServiceEnabled();
    if (isEnabled == false) {
      setState(() {
        label = "lokasi tidak aktif";
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          label = "izin lokasi ditolak";
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          label = "izin lokasi ditolak selamanya";
        });
        return;
      }
    }

    var position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    // Geolocator.

    setState(() {
      label =
          "koordinat lokasi saat ini: ${position.latitude}, ${position.longitude}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Membaca Koordinat GPS")),
      body: Center(
        child: Column(
          children: [
            Text(label),
            ElevatedButton(
              onPressed: () {
                _bacaLokasi();
              },
              child: Text('baca lokasi saat ini'),
            ),
          ],
        ),
      ),
    );
  }
}
