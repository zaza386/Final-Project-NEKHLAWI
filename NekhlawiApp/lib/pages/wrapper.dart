import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'welcome_page.dart';
import 'complete_profile_page.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    /// لا يوجد تسجيل دخول
    if (session == null || user == null) {
      return const WelcomePage();
    }

    return _ProfileGate(
      userId: user.id,
      email: user.email ?? '',
    );
  }
}

class _ProfileGate extends StatefulWidget {
  final String userId;
  final String email;

  const _ProfileGate({
    required this.userId,
    required this.email,
  });

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<Widget> _pageFuture;

  @override
  void initState() {
    super.initState();
    _pageFuture = _resolveUserRoute();
  }

  Future<Widget> _resolveUserRoute() async {
    final supabase = Supabase.instance.client;

    /// =========================
    /// قراءة جدول User
    /// =========================
    final userData = await supabase
        .from('User')
        .select('Name, Phone, Role')
        .eq('UserID', widget.userId)
        .maybeSingle();

    final role = userData?['Role'] ?? 'farmer';

    final hasBasicProfile =
        userData != null &&
        userData['Name'] != null &&
        userData['Phone'] != null;

    /// المستخدم لم يكمل بياناته
    if (!hasBasicProfile) {
      return CompleteProfilePage(
        userId: widget.userId,
        email: widget.email,
        role: role,
      );
    }

    /// =========================
    /// إذا Expert → تأكد من وجود ExpertProfile
    /// =========================
    if (role == 'expert') {
      final expertProfile = await supabase
          .from('ExpertProfile')
          .select()
          .eq('ExpertID', widget.userId)
          .maybeSingle();

      /// إنشاء صف فارغ أول مرة فقط
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

    /// كل شيء مكتمل
    return HomePage(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _pageFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data!;
      },
    );
  }
}