import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nekhlawi_app/pages/home_page.dart';
import 'package:nekhlawi_app/pages/welcome_page.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // المستخدم مسجل دخول
      return const HomePage();
    } else {
      // المستخدم غير مسجل
      return const WelcomePage();
    }
  }
}