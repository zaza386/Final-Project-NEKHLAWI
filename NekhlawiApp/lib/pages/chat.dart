import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nekhlawi_app/pages/expert_profile.dart';

class ChatPage extends StatefulWidget {
  final String expertId;
  final String userId;

  const ChatPage({super.key, required this.expertId, required this.userId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final supabase = Supabase.instance.client;

  String? expertName;
  String? expertImage;

  @override
  void initState() {
    super.initState();
    _loadExpert();
  }

  Future<void> _loadExpert() async {
    try {
      final res = await supabase
          .from('User')
          .select('Name, ProfilePicturePath')
          .eq('UserID', widget.expertId)
          .single();

      final imagePath = res['ProfilePicturePath'];

      final imageUrl = imagePath != null
          ? supabase.storage.from('pic').getPublicUrl(imagePath)
          : null;

      setState(() {
        expertName = res['Name'];
        expertImage = imageUrl;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpertProfilePage(expertId: widget.expertId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,

        /// 🔥 HEADER الجديد
        appBar: AppBar(
          backgroundColor: AppColors.header,
          elevation: 0,

          title: GestureDetector(
            onTap: _openProfile,
            child: Row(
              children: [
                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 22,
                  backgroundImage: expertImage != null
                      ? NetworkImage(expertImage!)
                      : null,
                  child: expertImage == null ? const Icon(Icons.person) : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    expertName ?? '...',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.darkGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildReceived("Hi 👋"),
                  _buildSent("اهلا"),
                  _buildDate("اليوم"),
                  _buildReceived("كيف أقدر أساعدك؟"),
                  _buildFile(),
                  _buildSent("تمام شكراً"),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSent(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.white)),
      ),
    );
  }

  Widget _buildReceived(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: expertImage != null
                ? NetworkImage(expertImage!)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              text,
              style: const TextStyle(color: AppColors.darkGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDate(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(text, style: const TextStyle(color: AppColors.grey)),
      ),
    );
  }

  Widget _buildFile() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: expertImage != null
                ? NetworkImage(expertImage!)
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Icon(Icons.insert_drive_file, color: AppColors.grey),
                SizedBox(width: 8),
                Text(
                  "project_report.pdf",
                  style: TextStyle(color: AppColors.darkGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: AppColors.white,
      child: Row(
        children: [
          const Icon(Icons.mic, color: AppColors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "اكتب رسالة...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.attach_file, color: AppColors.grey),
          const SizedBox(width: 8),
          const Icon(Icons.camera_alt, color: AppColors.grey),
          const SizedBox(width: 8),
          const Icon(Icons.emoji_emotions_outlined, color: AppColors.grey),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.send, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
