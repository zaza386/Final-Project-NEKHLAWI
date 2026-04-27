import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/widgets/header_background.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

final supabase = Supabase.instance.client;

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class ExpertModel {
  final String id;
  final String name;
  final String title;
  final String location;
  final String priceLabel;
  final String? avatarUrl;

  ExpertModel({
    required this.id,
    required this.name,
    required this.title,
    this.location = '',
    this.priceLabel = '',
    this.avatarUrl,
  });

factory ExpertModel.fromMap(Map<String, dynamic> map) {
  final userData = map['User'] ?? {}; 
  
  return ExpertModel(
    id: map['ExpertID'].toString(),
    name: userData['Name'] ?? 'خبير غير معروف',
    title: map['Specialization'] ?? '',
    avatarUrl: userData['ProfilePicturePath'],
  );
}
}

class TimeSlot {
  final String? id;
  final DateTime dateTime;
  final bool isAvailable;

  TimeSlot({
    this.id,
    required this.dateTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'].toString(),
      dateTime: DateTime.parse(map['slot_time']),
      isAvailable: map['is_available'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────
// BOOKING PAGE
// ─────────────────────────────────────────────

class BookingPage extends StatefulWidget {
  final String expertId;

  const BookingPage({
    super.key,
    required this.expertId,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _isLoading = true;
  ExpertModel? _expert;
  List<TimeSlot> _dbSlots = [];
  List<TimeSlot> _displaySlots = [];

  DateTime _selectedMonth = DateTime(DateTime.now().year, 1, 1);
  DateTime _selectedDay = DateTime.now();
  String? _selectedSlotId;
  DateTime? _selectedSlotTime;

  final List<DateTime> _months = List.generate(12, (index) {
    return DateTime(DateTime.now().year, 1 + index, 1);
  });

  static const Color kPrimary = Color(0xFF797F3D);
  static const Color kBackground = Color(0xFFF2F0E8);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kSlotAvailable = Color(0xFFD4D0C4);
  static const Color kSlotUnavailable = Color(0xFF8E8E8E);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final expertResponse = await supabase
          .from('ExpertProfile')
          .select('ExpertID, Specialization, User ( Name, ProfilePicturePath )')
          .eq('ExpertID', widget.expertId)
          .maybeSingle();

      if (expertResponse == null) return;

      final start = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      final end = start.add(const Duration(days: 1));

      final slotsResponse = await supabase
          .from('time_slots')
          .select('id, slot_time, is_available')
          .eq('ExpertID', widget.expertId)
          .gte('slot_time', start.toIso8601String())
          .lt('slot_time', end.toIso8601String())
          .order('slot_time');

      if (mounted) {
        setState(() {
          _expert = ExpertModel.fromMap(expertResponse);
          _dbSlots = (slotsResponse as List)
              .map((r) => TimeSlot.fromMap(r))
              .toList();
          _generateHalfHourSlots();
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateHalfHourSlots() {
    List<TimeSlot> tempSlots = [];
    for (int hour = 8; hour <= 19; hour++) {
      for (int minute in [0, 30]) {
        final slotTime = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
        
        final dbMatch = _dbSlots.firstWhere(
          (s) => s.dateTime.hour == hour && s.dateTime.minute == minute,
          orElse: () => TimeSlot(dateTime: slotTime, isAvailable: false),
        );

        bool existsInDb = _dbSlots.any((s) => s.dateTime.hour == hour && s.dateTime.minute == minute);

        tempSlots.add(TimeSlot(
          id: existsInDb ? dbMatch.id : null,
          dateTime: slotTime,
          isAvailable: existsInDb ? dbMatch.isAvailable : false,
        ));
      }
    }
    _displaySlots = tempSlots;
  }

  Future<int> _fetchAvailableCountForDay(DateTime day) async {
    final start = DateTime.utc(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    
    final response = await supabase
        .from('time_slots')
        .select('id')
        .eq('ExpertID', widget.expertId)
        .eq('is_available', true)
        .gte('slot_time', start.toIso8601String())
        .lt('slot_time', end.toIso8601String());
    
    return (response as List).length;
  }

  Future<void> _confirmBooking() async {
  if (_selectedSlotId == null) return;

  // Find the actual DateTime object for the selected slot
  final selectedSlot = _dbSlots.firstWhere((s) => s.id == _selectedSlotId);

  try {
    // حساب StartAt و EndAt (30 دقيقة لكل جلسة)
    final startAt = selectedSlot.dateTime;
    final endAt = startAt.add(const Duration(minutes: 30));

    // SUPABASE: Insert booking in ExpertSession table
    await supabase.from('ExpertSession').insert({
      'ExpertID': widget.expertId,
      'UserID': supabase.auth.currentUser?.id,
      'BookedAt': DateTime.now().toIso8601String(),
      'StartAt': startAt.toIso8601String(),
      'EndAt': endAt.toIso8601String(),
      'Status': 'لم تبدأ',
    });

    // SUPABASE: Mark the slot as unavailable
    await supabase
        .from('time_slots')
        .update({'is_available': false})
        .eq('id', _selectedSlotId!);

    // عرض dialog بمعلومات الحجز
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تم الحجز بنجاح!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الخبير: ${_expert?.name ?? 'غير محدد'}'),
                  const SizedBox(height: 8),
                  Text('التخصص: ${_expert?.title ?? 'غير محدد'}'),
                  const SizedBox(height: 8),
                  Text('تاريخ الموعد: ${startAt.day}/${startAt.month}/${startAt.year}'),
                  const SizedBox(height: 8),
                  Text('وقت الموعد: ${startAt.hour}:${startAt.minute.toString().padLeft(2, '0')} - ${endAt.hour}:${endAt.minute.toString().padLeft(2, '0')}'),
                  const SizedBox(height: 8),
                  const Text('الحالة: لم تبدأ'),
                  const SizedBox(height: 8),
                  Text('تاريخ الحجز: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // إغلاق الـ dialog
                    // الرجوع للـ home page وتحديثها
                    Future.delayed(Duration.zero, () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => HomePage(userId: supabase.auth.currentUser?.id),
                        ),
                        (route) => false, // إزالة جميع الصفحات السابقة من الـ stack
                      );
                    });
                  },
                  child: const Text('تمام'),
                ),
              ],
            ),
          );
        },
      );
    }
  } catch (e) {
    debugPrint('Booking error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء الحجز'), backgroundColor: Colors.red),
      );
    }
  }
}

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  String _arabicWeekday(DateTime date) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  String _arabicMonth(DateTime date) {
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSlotTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${dt.hour >= 12 ? 'م' : 'ص'}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.header,
        body: _isLoading && _expert == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
            : Column(
                children: [
                  SafeArea(bottom: false, child: SizedBox(height: 90, child: HeaderBackground(title: 'اختر التاريخ و الوقت'))),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kBackground,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildExpertCard(),
                            const SizedBox(height: 16),
                            _buildMonthScrollSelector(),
                            const SizedBox(height: 12),
                            _buildDayScrollSelector(),
                            const SizedBox(height: 16), // Restored some space for breathing
                            _buildTimeSlotsGrid(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildExpertCard() {
    if (_expert == null) return const SizedBox();
    return Container(
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFD9D5C5),
                backgroundImage: _expert!.avatarUrl != null && _expert!.avatarUrl!.isNotEmpty
                    ? NetworkImage(supabase.storage.from('pic').getPublicUrl(_expert!.avatarUrl!))
                    : AssetImage('images/nekhlawi_icon.png'),
                child: null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_expert!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_expert!.title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip(Icons.monetization_on_outlined, 'الاستشارة تبدأ من ٣٠٠ ريال'),
              _infoChip(Icons.location_on_outlined, 'السعودية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: kPrimary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMonthScrollSelector() {
    return SizedBox(
      height: 42, // Slightly taller for cleaner padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected = month.month == _selectedMonth.month && month.year == _selectedMonth.year;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
                _selectedDay = DateTime(month.year, month.month, 1);
              });
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? kPrimary : kCard, borderRadius: BorderRadius.circular(20)),
              child: Center(child: Text(_arabicMonth(month), style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayScrollSelector() {
    final days = _getDaysInMonth(_selectedMonth);
    return SizedBox(
      height: 95, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day.day == _selectedDay.day && day.month == _selectedDay.month;
          
          return FutureBuilder<int>(
            future: _fetchAvailableCountForDay(day),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _selectedSlotId = null;
                    _selectedSlotTime = null;
                  });
                  _loadData();
                },
                child: Container(
                  width: 78,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? kPrimary : Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(day.day.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                      Text(_arabicWeekday(day), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 5),
                      Text('متاح: $count', style: TextStyle(fontSize: 9, color: isSelected ? Colors.white60 : kPrimary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsGrid() {
    if (_displaySlots.isEmpty) return const SizedBox();
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        childAspectRatio: 2.2, 
        crossAxisSpacing: 10, 
        mainAxisSpacing: 10
      ),
      itemCount: _displaySlots.length,
      itemBuilder: (context, index) {
        final slot = _displaySlots[index];
        final isSelected = _selectedSlotTime == slot.dateTime;
        return GestureDetector(
          onTap: slot.isAvailable ? () => setState(() {
            _selectedSlotId = slot.id;
            _selectedSlotTime = slot.dateTime;
          }) : null,
          child: Container(
            decoration: BoxDecoration(
              color: !slot.isAvailable ? kSlotUnavailable : (isSelected ? Colors.white : kSlotAvailable),
              borderRadius: BorderRadius.circular(10),
              border: isSelected ? Border.all(color: kPrimary, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(_formatSlotTime(slot.dateTime), style: TextStyle(fontSize: 11, color: isSelected ? kPrimary : Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 20), // Increased padding for comfort
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _legendItem('غير متاح', kSlotUnavailable),
              const SizedBox(width: 16),
              _legendItem('متاح', kSlotAvailable),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(_selectedSlotTime != null ? _formatSlotTime(_selectedSlotTime!) : '--:--', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              const Icon(Icons.alarm, size: 18, color: Colors.black54),
              const SizedBox(width: 20),
              Text('${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlotId != null ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('تأكيد الحجز', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('© 2025-2026', style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }
}