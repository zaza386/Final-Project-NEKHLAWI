import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nekhlawi_app/pages/welcome_page.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://kywgxfkbyvczxerjogxf.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5d2d4ZmtieXZjenhlcmpvZ3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NTk4MjgsImV4cCI6MjA4NjIzNTgyOH0.5tgrLScwnld4mrxMCcVsu1bEHQaxHoYUasA9ciBDneA",
  );

  // فحص حالة الجلسة قبل تشغيل التطبيق
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) {
    print("✅ المستخدم مسجل دخوله: ${session.user.email}");
  } else {
    print("❌ لا يوجد مستخدم مسجل حالياً");
  }

  runApp(const NekhlawiApp());
}

class NekhlawiApp extends StatelessWidget {
  const NekhlawiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديد الصفحة الأولى بناءً على حالة تسجيل الدخول
    final session = Supabase.instance.client.auth.currentSession;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // إذا كان مسجل دخول، اذهبي لـ Wrapper (أو الصفحة الرئيسية)، وإذا لا، WelcomePage
      home: session != null ? const Wrapper() : const WelcomePage(),
    );
  }
}