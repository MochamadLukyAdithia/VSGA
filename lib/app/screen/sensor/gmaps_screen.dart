import 'package:flutter/material.dart';
import 'package:vsga/app/screen/sensor/gps_screen.dart';
import 'package:vsga/app/screen/sensor/map_screen.dart';

class GpsAndMapScreen extends StatelessWidget {
  const GpsAndMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("GPS dan Peta")),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) {
                      return GpsScreen();
                    },
                  ),
                );
              },
              child: Text("GPS"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) {
                      return MapScreen();
                    },
                  ),
                );
              },
              child: Text("Peta"),
            ),
          ],
        ),
      ),
    );
  }
}
