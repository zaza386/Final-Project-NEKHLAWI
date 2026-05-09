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
  bool isLoading = true;
  String? currentStatus;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _fetchCurrentStatus();
  }

  Future<void> _fetchCurrentStatus() async {
    try {
      final data = await supabase.from('ExpertSession').select('Status').eq('ExpertSessionID', widget.sessionId!).maybeSingle();
      if (mounted) {
        setState(() {
          currentStatus = data != null ? data['Status'] : null;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching status: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _onAcceptPressed() async {
    setState(() => isLoading = true);
    try {
      await supabase.from('ExpertSession').update({'Status': 'لم تبدأ'}).eq('ExpertSessionID', widget.sessionId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في القبول: $e')));
      }
    }
  }

  Future<void> _onDeclinePressed() async {
    setState(() => isLoading = true);
    try {
      await supabase.from('ExpertSession').update({'Status': 'مرفوضة'}).eq('ExpertSessionID', widget.sessionId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الرفض: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpert = widget.userRole?.toLowerCase() == 'expert' || widget.userRole == 'خبير';
    final bool canDecide = isExpert && (currentStatus == 'تحت المعاينة');

    // اللون المطلوب CFD1AAFF
    const Color customGreen = Color(0xFFCFD1AA);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C3D19), // لون الخط بني غامق ليتناسب مع الخلفية الفاتحة
            ),
          ),
          backgroundColor: customGreen, // الدرجة المطلوبة
          centerTitle: false, // النص لجهة اليمين
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF4C3D19)), // لون سهم الرجوع بني
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: customGreen))
            : Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canDecide) ...[
                  const Icon(Icons.help_outline_rounded, size: 100, color: customGreen),
                  const SizedBox(height: 30),
                  const Text('طلب استشارة جديد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('هل ترغب في قبول هذا الطلب الموجه إليك كخبير؟', textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _onAcceptPressed,
                          child: const Text('قبول الطلب'),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: _onDeclinePressed,
                          child: const Text('رفض'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Icon(
                    (currentStatus == 'لم تبدأ' || currentStatus == 'بدأت' || currentStatus == 'أنتهت') ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 100,
                    color: customGreen,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    (currentStatus == 'لم تبدأ' || currentStatus == 'بدأت' || currentStatus == 'أنتهت')
                        ? (isExpert ? 'تم قبول هذه الاستشارة بنجاح' : 'وافق الخبير على طلب الاستشارة')
                        : (currentStatus == 'مرفوضة')
                        ? 'تم رفض هذه الاستشارة'
                        : 'حالة الاستشارة الحالية: ${currentStatus ?? "غير معروفة"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    (currentStatus == 'لم تبدأ' && !isExpert) ? 'يمكنك الآن متابعة الجلسة في موعدها المحدد.' : 'يمكنك متابعة حالة الاستشارة من الصفحة الرئيسية.',
                    textAlign: TextAlign.center,
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