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
  String? dbDeclineReason; // 🔹 متغير لتخزين سبب الرفض القادم من الداتابيز

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) _fetchCurrentStatus();
  }

  Future<void> _fetchCurrentStatus() async {
    try {
      // 🔹 تم إضافة DeclineReason هنا في الـ select لجلب النص من سوبابيس
      final data = await supabase
          .from('ExpertSession')
          .select('Status, DeclineReason')
          .eq('ExpertSessionID', widget.sessionId!)
          .maybeSingle();

      if (mounted) {
        setState(() {
          currentStatus = data != null ? data['Status'] : null;
          dbDeclineReason = data != null ? data['DeclineReason'] : null; // 🔹 تخزين السبب المجلوب
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
    final TextEditingController reasonController = TextEditingController();

    // إظهار نافذة منبثقة للخبير لكتابة سبب الرفض
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text(
              'سبب رفض الاستشارة',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4C3D19)),
            ),
            content: TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب سبب الرفض هنا ليظهر للمزارع...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4C3D19)),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final String reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء كتابة سبب الرفض أولاً')),
                    );
                    return;
                  }

                  Navigator.pop(context); // إغلاق الـ Dialog
                  _executeDecline(reason); // تنفيذ الرفع لقاعدة البيانات
                },
                child: const Text('تأكيد الرفض'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeDecline(String reason) async {
    setState(() => isLoading = true);
    try {
      final sessionData = await supabase
          .from('ExpertSession')
          .select('StartAt, ExpertID')
          .eq('ExpertSessionID', widget.sessionId!)
          .single();

      final String? startTime = sessionData['StartAt'];
      final String? expertId = sessionData['ExpertID'];

      // تحديث الحالة وحفظ نص الرفض في سوبابيس
      await supabase
          .from('ExpertSession')
          .update({
        'Status': 'مرفوضة',
        'DeclineReason': reason,
      })
          .eq('ExpertSessionID', widget.sessionId!);

      if (startTime != null && expertId != null) {
        await supabase
            .from('time_slots')
            .update({'is_available': true})
            .eq('slot_time', startTime)
            .eq('ExpertID', expertId);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error details: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في العملية: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpert = widget.userRole?.toLowerCase() == 'expert' || widget.userRole == 'خبير';
    final bool canDecide = isExpert && (currentStatus == 'تحت المعاينة');

    const Color customGreen = Color(0xFFCFD1AA);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4C3D19),
            ),
          ),
          backgroundColor: customGreen,
          centerTitle: false,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF4C3D19)),
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

                  // 🔹 السطر المستهدف: تم دمج عرض المتغير الديناميكي بنجاح هنا
                  Text(
                    (currentStatus == 'لم تبدأ' || currentStatus == 'بدأت' || currentStatus == 'أنتهت')
                        ? (isExpert ? 'تم قبول هذه الاستشارة بنجاح' : 'وافق الخبير على طلب الاستشارة')
                        : (currentStatus == 'مرفوضة')
                        ? 'تم رفض هذه الاستشارة بسبب: ${dbDeclineReason ?? "لم يذكر الخبير سبباً"}'
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