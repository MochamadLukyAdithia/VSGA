import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  var _cameraStateStr = "Menyiapkan kamera...";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  _initCamera() async {
    try {
      var cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController?.initialize();

      setState(() {
        _cameraStateStr = "Kamera siap digunakan";
      });
    } catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        _cameraStateStr = "Kamera tidak tersedia";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kamera")),
      body: Column(
        children: [
          Expanded(
            child: _cameraController != null
                ? CameraPreview(_cameraController!)
                : Text(_cameraStateStr),
          ),
        ],
      ),
    );
  }
}
