import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Menampilkan Peta")),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-8.13, 113.729),
                initialZoom: 10,
              ),
              children: [
                TileLayer(
                  // Bring your own tiles
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
                  userAgentPackageName:
                      'com.example.app', // Add your app identifier
                  // And many more recommended properties!
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(-8.13, 113.729),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
                // RichAttributionWidget(
                //   // Include a stylish prebuilt attribution widget that meets all requirments
                //   attributions: [
                //     TextSourceAttribution(
                //       'OpenStreetMap contributors',
                //       onTap: () {},
                //       // onTap: () => launchUrl(
                //       //   Uri.parse('https://openstreetmap.org/copyright'),
                //       // ), // (external)
                //     ),
                //     // Also add images...
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
