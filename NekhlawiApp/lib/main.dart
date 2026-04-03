import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nekhlawi_app/pages/home_page.dart'; // تأكدي من استيراد صفحة الهوم
import 'package:nekhlawi_app/pages/welcome_page.dart';
import 'package:nekhlawi_app/pages/wrapper.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. إعداد سوبابيس مع تفعيل الـ PKCE لدعم الروابط السحرية (Magic Links)
  await Supabase.initialize(
    url: "https://kywgxfkbyvczxerjogxf.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt5d2d4ZmtieXZjenhlcmpvZ3hmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2NTk4MjgsImV4cCI6MjA4NjIzNTgyOH0.5tgrLScwnld4mrxMCcVsu1bEHQaxHoYUasA9ciBDneA",
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // 👈 هذا التعديل ضروري لعمل الـ Session مع الروابط
    ),
  );

  // ملاحظة: قمت بتعطيل signOut التلقائي لكي لا يخرج المستخدم في كل مرة يفتح فيها التطبيق
  // await Supabase.instance.client.auth.signOut();

  runApp(const NekhlawiApp());
}

class NekhlawiApp extends StatefulWidget {
  const NekhlawiApp({super.key});

  @override
  State<NekhlawiApp> createState() => _NekhlawiAppState();
}

class _NekhlawiAppState extends State<NekhlawiApp> {

  @override
  void initState() {
    super.initState();

    // 2. الاستماع لتغيرات حالة الدخول (عندما يعود المستخدم من الرابط السحري)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        // إذا تم التقاط الجلسة بنجاح، نتوجه فوراً لصفحة الهوم/الورابر
        Get.offAll(() => const Wrapper());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // التحقق المبدئي من وجود جلسة مخزنة
    final session = Supabase.instance.client.auth.currentSession;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // إذا كان هناك جلسة نشطة يذهب للـ Wrapper، وإلا لصفحة الترحيب
      home: session != null ? const Wrapper() : const WelcomePage(),
    );
  }
}