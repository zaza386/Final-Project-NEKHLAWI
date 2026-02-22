import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nekhlawi_app/pages/home_page.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
import 'package:nekhlawi_app/pages/welcome_page.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://kywgxfkbyvczxerjogxf.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5d2d4ZmtieXZjenhlcmpvZ3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NTk4MjgsImV4cCI6MjA4NjIzNTgyOH0.5tgrLScwnld4mrxMCcVsu1bEHQaxHoYUasA9ciBDneA",
  );
  runApp(const  NekhlawiApp());
}

class NekhlawiApp extends StatelessWidget {
  const NekhlawiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}