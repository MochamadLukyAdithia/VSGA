import 'package:flutter/material.dart';
import 'package:vsga/app/screen/auth/login_screen.dart';
import 'package:vsga/app/screen/auth/role_selection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RoleSelectionScreen(),
    );
  }
}
