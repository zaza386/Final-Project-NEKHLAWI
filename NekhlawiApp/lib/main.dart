import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
// import 'package:nekhlawi_app/pages/welcome_page.dart';
import 'core/theme/app_theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const  NekhlawiApp());
}

class NekhlawiApp extends StatelessWidget {
  const NekhlawiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Wrapper(),
    );
  }
}