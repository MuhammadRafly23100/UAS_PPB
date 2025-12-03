import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'launch_screen.dart';
import 'login.dart';
import 'cart_manager.dart'; // Import CartManager

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: LaunchScreen(), 
    );
  }
}
