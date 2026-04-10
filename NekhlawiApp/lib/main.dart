import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nekhlawi_app/pages/welcome_page.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
import 'package:nekhlawi_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// تهيئة Supabase
  await Supabase.initialize(
    url: "https://kywgxfkbyvczxerjogxf.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5d2d4ZmtieXZjenhlcmpvZ3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NTk4MjgsImV4cCI6MjA4NjIzNTgyOH0.5tgrLScwnld4mrxMCcVsu1bEHQaxHoYUasA9ciBDneA",
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const NekhlawiApp());
}

class NekhlawiApp extends StatefulWidget {
  const NekhlawiApp({super.key});

  @override
  State<NekhlawiApp> createState() => _NekhlawiAppState();
}

class _NekhlawiAppState extends State<NekhlawiApp> {
  final supabase = Supabase.instance.client;

  Session? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    /// ✅ استرجاع الجلسة المحفوظة عند تشغيل التطبيق
    _session = supabase.auth.currentSession;

    /// إنهاء شاشة التحميل
    _isLoading = false;

    /// ✅ الاستماع لأي تغيير في حالة تسجيل الدخول
    supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    /// شاشة تحميل أولية
    if (_isLoading) {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    /// تحديد الصفحة حسب وجود Session
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _session != null
          ? const Wrapper()
          : const WelcomePage(),
    );
  }
}