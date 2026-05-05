import 'package:flutter/material.dart';
import 'package:nekhlawi_app/core/widgets/header_background.dart';
import 'package:nekhlawi_app/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'stripe_payment_sheet.dart';

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
  final int pricePerHour;

  ExpertModel({
    required this.id,
    required this.name,
    required this.title,
    this.location = '',
    this.priceLabel = '',
    this.avatarUrl,
    this.pricePerHour = 300,
  });

  factory ExpertModel.fromMap(Map<String, dynamic> map) {
    final userData = map['User'] ?? {};
    return ExpertModel(
      id: map['ExpertID'].toString(),
      name: userData['Name'] ?? 'خبير غير معروف',
      title: map['Specialization'] ?? '',
      location: userData['Location'] ?? '',
      priceLabel: 'الاستشارة تبدأ من ٣٠٠ ريال',
      avatarUrl: userData['ProfilePicturePath'],
      pricePerHour: 300,
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
      id: map['id']?.toString(),
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

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  // DateTime _selectedMonth = DateTime(DateTime.now().year, 1, 1);
  // DateTime _selectedDay = DateTime.now();
  List<TimeSlot> _selectedSlots = [];

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

      final start = DateTime.utc(
          _selectedDay.year, _selectedDay.month, _selectedDay.day);
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
          _dbSlots =
              (slotsResponse as List).map((r) => TimeSlot.fromMap(r)).toList();
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
        final slotTime = DateTime(
            _selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);

        final dbMatch = _dbSlots.firstWhere(
          (s) => s.dateTime.hour == hour && s.dateTime.minute == minute,
          orElse: () => TimeSlot(dateTime: slotTime, isAvailable: false),
        );

        bool existsInDb = _dbSlots
            .any((s) => s.dateTime.hour == hour && s.dateTime.minute == minute);

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

  bool isAdjacent(TimeSlot a, TimeSlot b) {
    final diff = b.dateTime.difference(a.dateTime);
    return diff == const Duration(minutes: 30) ||
        diff == const Duration(minutes: -30);
  }

  bool _isSelectedSlot(TimeSlot slot) {
    return _selectedSlots.any((selected) => selected.id == slot.id);
  }

  void _showSelectionError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _toggleSlotSelection(TimeSlot slot) {
    if (!slot.isAvailable) return;

    final isSelected = _isSelectedSlot(slot);
    if (isSelected) {
      if (_selectedSlots.length == 1) {
        setState(() => _selectedSlots.clear());
        return;
      }
      final first = _selectedSlots.first;
      final last = _selectedSlots.last;
      if (slot.id == first.id) {
        setState(() => _selectedSlots.removeAt(0));
        return;
      }
      if (slot.id == last.id) {
        setState(() => _selectedSlots.removeLast());
        return;
      }
      _showSelectionError(
          'لا يمكن إزالة خانة من المنتصف. احذف من البداية أو النهاية.');
      return;
    }

    if (_selectedSlots.isEmpty) {
      setState(() => _selectedSlots.add(slot));
      return;
    }

    final first = _selectedSlots.first;
    final last = _selectedSlots.last;

    if (isAdjacent(slot, first)) {
      setState(() => _selectedSlots.insert(0, slot));
      return;
    }
    if (isAdjacent(last, slot)) {
      setState(() => _selectedSlots.add(slot));
      return;
    }

    _showSelectionError('يجب اختيار الأوقات بشكل متتابع بدون فراغ.');
  }

  int get _selectedSlotCount => _selectedSlots.length;
  double get _selectedDurationHours => _selectedSlotCount * 0.5;
  int get _pricePerHour => _expert?.pricePerHour ?? 300;
  int get _pricePerSlot => _pricePerHour ~/ 2;
  int get _totalPrice => _selectedSlotCount * _pricePerSlot;

  String get _totalDurationLabel {
    final hours = _selectedDurationHours;
    if (hours == hours.toInt()) return '${hours.toInt()} ساعة';
    return '${hours.toStringAsFixed(1)} ساعات';
  }

  DateTime? get _selectedStart =>
      _selectedSlots.isNotEmpty ? _selectedSlots.first.dateTime : null;
  DateTime? get _selectedEnd => _selectedSlots.isNotEmpty
      ? _selectedSlots.last.dateTime.add(const Duration(minutes: 30))
      : null;

  // ─────────────────────────────────────────────
  // CONFIRM BOOKING → Stripe payment sheet first,
  // then save to Supabase only after payment succeeds
  // ─────────────────────────────────────────────

  Future<void> _confirmBooking() async {
    if (_selectedSlots.isEmpty) return;

    final selectedSlots = List<TimeSlot>.from(_selectedSlots);
    selectedSlots.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final startAt = selectedSlots.first.dateTime;
    final endAt =
        selectedSlots.last.dateTime.add(const Duration(minutes: 30));

    final bookedSlotIds = selectedSlots
        .map((slot) => slot.id)
        .whereType<String>()
        .toList();

    if (bookedSlotIds.length != selectedSlots.length) {
      _showSelectionError('حدث خطأ في تحديد الأوقات. حاول مرة أخرى.');
      return;
    }

    // ── 1. Open Stripe payment sheet ─────────────────────────────────────────
    final success = await StripePaymentSheet.show(
      context,
      booking: BookingSummary(
        expertName: _expert?.name ?? 'الخبير',
        expertTitle: _expert?.title ?? '',
        date: '${startAt.day}/${startAt.month}/${startAt.year}',
        time: '${_formatSlotTime(startAt)} - ${_formatSlotTime(endAt)}',
        amountSAR: _totalPrice,
      ),
    );

    // ── 2. Only save to Supabase if payment succeeded ─────────────────────────
    if (success == true && mounted) {
      try {
        await supabase.from('ExpertSession').insert({
          'ExpertID': widget.expertId,
          'UserID': supabase.auth.currentUser?.id,
          'BookedAt': DateTime.now().toIso8601String(),
          'StartAt': startAt.toIso8601String(),
          'EndAt': endAt.toIso8601String(),
          'Status': 'لم تبدأ',
        });

        await supabase
            .from('time_slots')
            .update({'is_available': false})
            .filter('id', 'in', bookedSlotIds);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  HomePage(userId: supabase.auth.currentUser?.id),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint('Booking save error: $e');
        if (mounted) {
          _showSelectionError(
              'تم الدفع لكن حدث خطأ في حفظ الحجز. تواصل معنا.');
        }
      }
    }
    // success == false/null → user cancelled, stay on page, nothing happens
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(
        lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  String _arabicWeekday(DateTime date) {
    const days = [
      'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
      'الجمعة', 'السبت', 'الأحد'
    ];
    return days[date.weekday - 1];
  }

  String _arabicMonth(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSlotTime(DateTime dt) {
    final hour =
        dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${dt.hour >= 12 ? 'م' : 'ص'}';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.header,
        body: _isLoading && _expert == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.darkBrown))
            : Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 90,
                      child: HeaderBackground(title: 'اختر التاريخ و الوقت'),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: kBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildExpertCard(),
                            const SizedBox(height: 16),
                            _buildMonthScrollSelector(),
                            const SizedBox(height: 12),
                            _buildDayScrollSelector(),
                            const SizedBox(height: 16),
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

  // ─────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────

  Widget _buildExpertCard() {
    if (_expert == null) return const SizedBox();
    return Container(
      decoration:
          BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFD9D5C5),
                backgroundImage: _expert!.avatarUrl != null &&
                        _expert!.avatarUrl!.isNotEmpty
                    ? NetworkImage(supabase.storage
                        .from('pic')
                        .getPublicUrl(_expert!.avatarUrl!))
                    : const AssetImage('images/nekhlawi_icon.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_expert!.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_expert!.title,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip(
                  Icons.monetization_on_outlined, 'الاستشارة تبدأ من ٣٠٠ ريال'),
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
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildMonthScrollSelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected = month.month == _selectedMonth.month &&
              month.year == _selectedMonth.year;
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _arabicMonth(month),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 13,
                  ),
                ),
              ),
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
          final isSelected =
              day.day == _selectedDay.day && day.month == _selectedDay.month;

          return FutureBuilder<int>(
            future: _fetchAvailableCountForDay(day),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _selectedSlots.clear();
                  });
                  _loadData();
                },
                child: Container(
                  width: 78,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? kPrimary : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        _arabicWeekday(day),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isSelected ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'متاح: $count',
                        style: TextStyle(
                          fontSize: 9,
                          color: isSelected ? Colors.white60 : kPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
        mainAxisSpacing: 10,
      ),
      itemCount: _displaySlots.length,
      itemBuilder: (context, index) {
        final slot = _displaySlots[index];
        final isSelected = _isSelectedSlot(slot);
        return GestureDetector(
          onTap: slot.isAvailable ? () => _toggleSlotSelection(slot) : null,
          child: Container(
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? kSlotUnavailable
                  : (isSelected ? Colors.white : kSlotAvailable),
              borderRadius: BorderRadius.circular(10),
              border:
                  isSelected ? Border.all(color: kPrimary, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: Text(
              _formatSlotTime(slot.dateTime),
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? kPrimary : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _selectedStart != null
                        ? _formatSlotTime(_selectedStart!)
                        : '--:--',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.alarm, size: 18, color: Colors.black54),
                ],
              ),
              Row(
                children: [
                  Text(
                    _selectedEnd != null
                        ? _formatSlotTime(_selectedEnd!)
                        : '--:--',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.alarm_off,
                      size: 18, color: Colors.black54),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedSlotCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المدة: $_totalDurationLabel',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  'المجموع: $_totalPrice ريال',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF797F3D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlotCount > 0 ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'تأكيد الحجز',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text('© 2025-2026',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
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
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}