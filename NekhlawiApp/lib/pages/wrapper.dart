import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'welcome_page.dart';
import 'complete_profile_page.dart';
import 'Expert_Homepage.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 استخدام StreamBuilder هو السر في جعل الماجك لينك يعمل تلقائياً
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        final user = session?.user;

        // إذا لا توجد جلسة نشطة
        if (session == null || user == null) {
          return const WelcomePage();
        }

        // إذا نجح الدخول (سواء بكلمة مرور أو ماجك لينك) نمر لمرحلة فحص الملف الشخصي
        return _ProfileGate(userId: user.id, email: user.email ?? '');
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  final String userId;
  final String email;

  const _ProfileGate({required this.userId, required this.email});

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveUserRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data ?? const WelcomePage();
      },
    );
  }

  Future<Widget> _resolveUserRoute() async {
    final supabase = Supabase.instance.client;

    final userData = await supabase
        .from('User')
        .select('Name, Phone, Role')
        .eq('UserID', widget.userId)
        .maybeSingle();

    final role = userData?['Role'] ?? 'user';
    final hasBasicProfile =
        userData != null &&
        userData['Name'] != null &&
        userData['Phone'] != null;

    if (!hasBasicProfile) {
      return CompleteProfilePage(
        userId: widget.userId,
        email: widget.email,
        role: role,
      );
    }

    if (role == 'expert') {
      final expertProfile = await supabase
          .from('ExpertProfile')
          .select()
          .eq('ExpertID', widget.userId)
          .maybeSingle();
      if (expertProfile == null) {
        await supabase.from('ExpertProfile').insert({
          'ExpertID': widget.userId,
          'Specialization': '',
          'ExperienceYears': 0,
          'Bio': '',
          'RatingAvg': 0,
        });
      }
    }

    if (role == 'expert') {
      return ExpertHomePage(userId: widget.userId);
    }
    return HomePage(userId: widget.userId);
  }
}
