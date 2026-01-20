import 'package:flutter/material.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const BlindLearningApp());
}

class BlindLearningApp extends StatelessWidget {
  const BlindLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assistive Learning',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
