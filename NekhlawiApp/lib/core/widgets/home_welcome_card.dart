import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:nekhlawi_app/pages/Expert_Account_Page.dart';
import 'package:nekhlawi_app/pages/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeWelcomeCard extends StatefulWidget {
  final String? userId;
  final String greeting;

  const HomeWelcomeCard({
    super.key,
    required this.userId,
    required this.greeting,
  });

  @override
  State<HomeWelcomeCard> createState() => _HomeWelcomeCardState();
}

class _HomeWelcomeCardState extends State<HomeWelcomeCard> {
  String? userName;
  String? userRole;

  @override
  void initState() {
    super.initState();

    if (widget.userId != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) return;

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('User')
          .select('Name, Role')
          .eq('UserID', widget.userId!)
          .single();

      if (mounted) {
        setState(() {
          userName = response['Name'] ?? 'المستخدم';
          userRole = response['Role'] ?? 'user';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = 'المستخدم';
          userRole = 'user';
        });
      }
    }
  }

  Future<void> _goToProfile(BuildContext context) async {
    if (userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل البيانات، حاول مرة أخرى')),
      );

      return;
    }

    late final result;

    if (userRole!.toLowerCase() == 'expert') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExpertAccountPage()),
      );
    } else {
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserProfilePage()),
      );
    }

    if (result == true) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpert = userRole?.toLowerCase() == 'expert';

    final roleLabel = isExpert ? 'خبير نخيل' : 'مزارع';

    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: () => _goToProfile(context),

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.header.withOpacity(0.6),
              AppColors.header.withOpacity(0.3),
            ],
          ),

          borderRadius: BorderRadius.circular(20),

          border: Border.all(color: AppColors.header.withOpacity(0.5)),
        ),

        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    '${widget.greeting} يا ${userName ?? 'المستخدم'} 👋',

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'الدور: $roleLabel • اضغط لتعديل ملفك',

                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.darkBrown,
            ),
          ],
        ),
      ),
    );
  }
}
