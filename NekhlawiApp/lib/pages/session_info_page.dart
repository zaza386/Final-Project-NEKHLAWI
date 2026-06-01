import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';
import '../services/session_reminder_service.dart';

class SessionInfoPage extends StatefulWidget {
  final String sessionId;
  final String title;
  final bool isExpert; // ← added

  const SessionInfoPage({
    super.key,
    required this.sessionId,
    required this.title,
    this.isExpert = false, // ← default false so existing calls don't break
  });

  @override
  State<SessionInfoPage> createState() => _SessionInfoPageState();
}

class _SessionInfoPageState extends State<SessionInfoPage> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? sessionData;
  String? paymentAmount;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchSessionInfo();
  }

  Future<void> _fetchSessionInfo() async {
    try {
      // ── Fetch session + expert info ───────────────────────────────
      final data = await supabase
          .from('ExpertSession')
          .select(
        'ExpertSessionID, StartAt, EndAt, Status, BookedAt, DeclineReason, '
            'ExpertProfile!ExpertID(Specialization, User!ExpertID(Name, ProfilePicturePath))',
      )
          .eq('ExpertSessionID', widget.sessionId)
          .single();

      // ── Calculate amount from session duration x expert price ───
      String? amount;
      try {
        final startRaw = data['StartAt'] as String?;
        final endRaw   = data['EndAt']   as String?;
        const pricePerHour = 300;
        if (startRaw != null && endRaw != null) {
          final start    = DateTime.tryParse(startRaw);
          final end      = DateTime.tryParse(endRaw);
          if (start != null && end != null) {
            final minutes  = end.difference(start).inMinutes;
            final slots    = (minutes / 30).ceil();
            final total    = slots * (pricePerHour ~/ 2);
            amount = total.toString();
          }
        }
      } catch (e) {
        debugPrint('Error calculating amount: $e');
      }

      if (mounted) {
        setState(() {
          sessionData   = data;
          paymentAmount = amount;
          isLoading     = false;
        });

        // ── Reminder: only for confirmed sessions in the future ───────
        final String? startAtRaw = data['StartAt'] as String?;
        final String? status     = data['Status']  as String?;
        if (startAtRaw != null && status == 'لم تبدأ') {
          final sessionStart = DateTime.tryParse(startAtRaw);
          if (sessionStart != null &&
              sessionStart.isAfter(DateTime.now())) {
            SessionReminderService().scheduleReminders(
              sessionStart: sessionStart,
              sessionId:    widget.sessionId,
              isExpert:     widget.isExpert,
            );
          }
        }
        // ─────────────────────────────────────────────────────────────
      }
    } catch (e) {
      debugPrint('Error fetching session info: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── Expert only: accept session (تحت المعاينة → لم تبدأ) ─────────
  Future<void> _acceptSession() async {
    setState(() => _isUpdatingStatus = true);
    try {
      await supabase
          .from('ExpertSession')
          .update({'Status': 'لم تبدأ'})
          .eq('ExpertSessionID', widget.sessionId);
      await _fetchSessionInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('✅ تم قبول الجلسة'),
            backgroundColor: Colors.green,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('_acceptSession: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  // ── Expert only: decline session (تحت المعاينة → مرفوضة) ────────
  Future<void> _declineSession() async {
    setState(() => _isUpdatingStatus = true);
    try {
      await supabase
          .from('ExpertSession')
          .update({'Status': 'مرفوضة'})
          .eq('ExpertSessionID', widget.sessionId);
      await _fetchSessionInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('تم رفض الجلسة'),
            backgroundColor: Colors.red,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('_declineSession: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }
  // ─────────────────────────────────────────────────────────────────

  String _formatDateTime(String? iso) {
    if (iso == null) return '--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--:--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--:--';
    final hour   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $period';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'تحت المعاينة': return 'قيد المراجعة';
      case 'لم تبدأ':      return 'مؤكدة';
      case 'بدأت':         return 'جارية';
      case 'أنتهت':        return 'منتهية';
      case 'مرفوضة':       return 'مرفوضة';
      default:             return status ?? '--';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'لم تبدأ':  return const Color(0xFF797F3D);
      case 'بدأت':     return Colors.blue;
      case 'أنتهت':    return Colors.grey;
      case 'مرفوضة':   return Colors.red;
      default:         return Colors.orange;
    }
  }

  Widget _invoiceRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF797F3D), size: 16),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      Color(0xFF43321A),
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary   = Color(0xFF797F3D);
    const Color kDarkBrown = Color(0xFF43321A);
    const Color kBeige     = Color(0xFFF5F3EE);
    const Color kBorder    = Color(0xFFE0DDD6);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Container(color: Colors.white),
            HeaderBackground(title: widget.title),
            Positioned(
              top: 140, left: 0, right: 0, bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:  Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF797F3D)),
                )
                    : sessionData == null
                    ? const Center(
                  child: Text(
                    'لا توجد بيانات لهذه الجلسة',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 16),
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 28),
                  child: _buildContent(
                      kPrimary, kDarkBrown, kBeige, kBorder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      Color kPrimary, Color kDarkBrown, Color kBeige, Color kBorder) {
    final expert =
        sessionData?['ExpertProfile'] as Map<String, dynamic>? ?? {};
    final user = expert['User'] as Map<String, dynamic>? ?? {};

    final String  expertName  = user['Name']             ?? 'خبير';
    final String  expertTitle = expert['Specialization'] ?? '';
    final String? avatarPath  = user['ProfilePicturePath'];
    final String? avatarUrl   =
    (avatarPath != null && avatarPath.isNotEmpty)
        ? supabase.storage.from('pic').getPublicUrl(avatarPath)
        : null;

    final String  startAt  = sessionData?['StartAt'];
    final String  endAt    = sessionData?['EndAt'];
    final String? status   = sessionData?['Status'];
    final String? bookedAt = sessionData?['BookedAt'];

    final String priceLabel =
    paymentAmount != null ? '$paymentAmount ريال' : '--';

    final String date      = _formatDateTime(startAt);
    final String timeRange =
        '${_formatTime(startAt)} - ${_formatTime(endAt)}';

    return Column(
      children: [
        // ── Title ─────────────────────────────────────────────────────
        const Text(
          'تفاصيل الجلسة',
          style: TextStyle(
            fontSize:   20,
            fontWeight: FontWeight.bold,
            color:      Color(0xFF43321A),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width:  64,
          height: 64,
          decoration: BoxDecoration(
            color: _statusColor(status),
            shape: BoxShape.circle,
          ),
          child: Icon(
            status == 'مرفوضة'
                ? Icons.cancel_rounded
                : Icons.check_rounded,
            color: Colors.white,
            size:  36,
          ),
        ),
        const SizedBox(height: 8),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color:        _statusColor(status).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(
              color:      _statusColor(status),
              fontWeight: FontWeight.bold,
              fontSize:   14,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Invoice card ──────────────────────────────────────────────
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Expert row
              Row(
                children: [
                  CircleAvatar(
                    radius:          22,
                    backgroundColor: const Color(0xFFD9D5C5),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('images/nekhlawi_icon.png')
                    as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expertName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color:      Color(0xFF43321A),
                            fontSize:   15,
                          ),
                        ),
                        if (expertTitle.isNotEmpty)
                          Text(
                            expertTitle,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.person_pin_outlined,
                      color: Color(0xFF797F3D), size: 20),
                ],
              ),
              const Divider(height: 24),

              // Date row
              _invoiceRow(
                  Icons.calendar_today_outlined, 'التاريخ', date),
              const SizedBox(height: 12),

              // Time row
              _invoiceRow(
                  Icons.access_time_outlined, 'الوقت', timeRange),
              const SizedBox(height: 12),

              // Booked at row
              if (bookedAt != null) ...[
                _invoiceRow(
                  Icons.bookmark_added_outlined,
                  'تاريخ الحجز',
                  _formatDateTime(bookedAt),
                ),
                const SizedBox(height: 12),
              ],

              // Decline reason row
              if (status == '\u0645\u0631\u0641\u0648\u0636\u0629' && sessionData?['DeclineReason'] != null && (sessionData!['DeclineReason'] as String).isNotEmpty) ...[  
                _invoiceRow(
                  Icons.info_outline,
                  '\u0633\u0628\u0628 \u0627\u0644\u0631\u0641\u0636',
                  sessionData!['DeclineReason'] as String,
                ),
                const SizedBox(height: 12),
              ],

              // Amount row
              const Divider(height: 8),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'المبلغ الإجمالي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:      Color(0xFF43321A),
                      fontSize:   14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF797F3D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priceLabel,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize:   13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Info note ─────────────────────────────────────────────────
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        kBeige,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: kBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF797F3D), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  // ── Info note text differs for expert vs user ─────
                  widget.isExpert
                      ? (status == 'تحت المعاينة'
                      ? 'يوجد طلب جلسة جديد بانتظار مراجعتك، يمكنك القبول أو الرفض.'
                      : status == 'لم تبدأ'
                      ? 'تم تأكيد الجلسة، ستبدأ في موعدها المحدد.'
                      : status == 'بدأت'
                      ? 'الجلسة جارية حالياً.'
                      : status == 'أنتهت'
                      ? 'انتهت الجلسة بنجاح.'
                      : 'تم رفض الجلسة.')
                      : (status == 'تحت المعاينة'
                      ? 'جلستك قيد المراجعة من قبل الخبير، سيتم إشعارك عند القبول أو الرفض.'
                      : status == 'لم تبدأ'
                      ? 'تم تأكيد جلستك، يمكنك متابعتها في موعدها المحدد.'
                      : status == 'بدأت'
                      ? 'الجلسة جارية حالياً.'
                      : status == 'أنتهت'
                      ? 'انتهت الجلسة بنجاح.'
                      : 'تم رفض الجلسة من قبل الخبير.'),
                  style: const TextStyle(
                    fontSize: 13,
                    color:    Color(0xFF43321A),
                    height:   1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        const Center(
          child: Text(
            '©️ 2025 - 2026 نخلاوي',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}