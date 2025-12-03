import 'package:flutter/material.dart';
import 'login.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _launchScreenState();
}

class _launchScreenState extends State<LaunchScreen> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 160,
          height: 160,
        ),
      ),
    );
  }
}
