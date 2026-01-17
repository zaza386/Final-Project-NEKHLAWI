import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/welcome_page.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const  NekhlawiApp());
}

class NekhlawiApp extends StatelessWidget {
  const NekhlawiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomePage(),
    );
  }
}