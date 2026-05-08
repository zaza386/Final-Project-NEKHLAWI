import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AcceptDeclineSessionPage extends StatefulWidget {
  final String title;
  final String? sessionId;
  final String? userRole;

  const AcceptDeclineSessionPage({
    super.key,
    required this.title,
    this.sessionId,
    this.userRole,
  });

  @override
  State<AcceptDeclineSessionPage> createState() => _AcceptDeclineSessionPageState();
}

class _AcceptDeclineSessionPageState extends State<AcceptDeclineSessionPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  String? currentStatus;

  @override
  void initState() {
    super.initState();
    // هنا فقط "نجلب" الحالة، ما نغير أي شيء في الداتابيز
    if (widget.sessionId != null) {
      _fetchCurrentStatus();
    }
  }

  Future<void> _fetchCurrentStatus() async {
    try {
      final data = await supabase
          .from('ExpertSession')
          .select('Status')
          .eq('ExpertSessionID', widget.sessionId!)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() => currentStatus = data['Status']);
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
    }
  }

// دالة القبول داخل صفحة القرار
  Future<void> _onAcceptPressed() async {
    setState(() => isLoading = true);
    await supabase.from('ExpertSession').update({'Status': 'لم تبدأ'}).eq('ExpertSessionID', widget.sessionId!);
    if (mounted) Navigator.pop(context, true);
  }

// دالة الرفض داخل صفحة القرار
  Future<void> _onDeclinePressed() async {
    setState(() => isLoading = true);
    // ✅ الرفض يقوم بحذف السجل نهائياً من الداتابيز
    await supabase.from('ExpertSession').delete().eq('ExpertSessionID', widget.sessionId!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpert = widget.userRole?.toLowerCase() == 'expert' || widget.userRole == 'خبير';

    // شرط ظهور الأزرار: لازم يكون خبير والحالة الحالية هي حالة "الطلب الجديد"
    // تأكدي من مسمى الحالة في الداتابيز (مثلاً 'قيد الانتظار')
    final bool canDecide = isExpert && (currentStatus == 'قيد الانتظار' || currentStatus == 'تحت المعاينة');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color(0xFF4C3D19),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4C3D19)))
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  canDecide ? Icons.help_outline : Icons.info_outline,
                  size: 100,
                  color: const Color(0xFF4C3D19),
                ),
                const SizedBox(height: 30),

                if (canDecide) ...[
                  const Text('إدارة الطلب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('أهلاً بك يا خبير، هل ترغب في قبول هذه الاستشارة؟', textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _onAcceptPressed, // ربط مباشر للضغط
                          child: const Text('قبول'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _onDeclinePressed, // ربط مباشر للضغط
                          child: const Text('رفض'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // هذه تظهر للمزارع أو للخبير إذا خلص قرر
                  Text(
                    currentStatus == 'لم تبدأ' || currentStatus == 'بدأت'
                        ? 'الاستشارة مقبولة'
                        : 'حالة الاستشارة: $currentStatus',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}