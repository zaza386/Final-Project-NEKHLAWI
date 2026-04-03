import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

// ─────────────────────────────────────────────
// SUPABASE: import the Supabase Flutter package
// Add to pubspec.yaml:
//   supabase_flutter: ^2.0.0
//   intl: ^0.19.0
// ─────────────────────────────────────────────
// import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SUPABASE: Initialize Supabase with your project URL and anon key
  // await Supabase.initialize(
  //   url: 'https://YOUR_PROJECT_ID.supabase.co',
  //   anonKey: 'YOUR_ANON_KEY',
  // );

  runApp(const MyApp());
}

// SUPABASE: Helper to access the Supabase client anywhere
// final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // RTL for Arabic UI
      builder: (context, child) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: child!,
      ),
      home: const BookingPage(),
    );
  }
}

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
    required this.location,
    required this.priceLabel,
    this.avatarUrl,
  });

  // SUPABASE: Map a Supabase row from the "experts" table to this model
  // Change field names to match your actual Supabase column names
  factory ExpertModel.fromMap(Map<String, dynamic> map) {
    return ExpertModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      priceLabel: map['price_label'] ?? '',
      avatarUrl: map['avatar_url'],
    );
  }
}

class TimeSlot {
  final String id;
  final DateTime dateTime;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.dateTime,
    required this.isAvailable,
  });

  // SUPABASE: Map a Supabase row from the "time_slots" table to this model
  // Change field names to match your actual Supabase column names
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'].toString(),
      // SUPABASE: "slot_time" should be a timestamptz column in Supabase
      dateTime: DateTime.parse(map['slot_time']),
      // SUPABASE: "is_available" is a boolean column in Supabase
      isAvailable: map['is_available'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────
// BOOKING PAGE
// ─────────────────────────────────────────────

class BookingPage extends StatefulWidget {
  // SUPABASE: Pass the expert's ID so we can query their data
  final String expertId;

  const BookingPage({
    super.key,
    this.expertId = '1', // default for demo
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // ── State ──────────────────────────────────
  bool _isLoading = true;
  ExpertModel? _expert;
  List<TimeSlot> _timeSlots = [];

  DateTime _selectedMonth = DateTime(2026, 2);
  DateTime _selectedDay = DateTime(2026, 2, 5);
  String? _selectedSlotId;

  // Months to display (you can generate these dynamically)
  final List<DateTime> _months = [
    DateTime(2026, 2),
    DateTime(2026, 3),
    DateTime(2026, 4),
  ];

  // ── Colors ─────────────────────────────────
  static const Color kPrimary = Color(0xFF5C6E2E);
  static const Color kBackground = Color(0xFFF2F0E8);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kSlotAvailable = Color(0xFF8E8E8E);
  static const Color kSlotUnavailable = Color(0xFFD4D0C4);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ── Data loading ───────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchExpert(),
      _fetchTimeSlots(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchExpert() async {
    // SUPABASE: Fetch expert details from the "experts" table by ID
    // final response = await supabase
    //     .from('experts')                          // SUPABASE: table name
    //     .select('id, name, title, location, price_label, avatar_url')
    //     .eq('id', widget.expertId)               // SUPABASE: filter by expert id
    //     .single();
    // setState(() => _expert = ExpertModel.fromMap(response));

    // ── Demo data (remove when using Supabase) ──
    await Future.delayed(const Duration(milliseconds: 400));
    _expert = ExpertModel(
      id: '1',
      name: 'م.خالد العتيبي',
      title: 'خبير زراعي',
      location: 'الأحساء، السعودية',
      priceLabel: 'الاستشارة تبدأ من ٣٠٠ ريال',
    );
  }

  Future<void> _fetchTimeSlots() async {
    // SUPABASE: Fetch available time slots for the selected day and expert
    // final start = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    // final end   = start.add(const Duration(days: 1));
    //
    // final response = await supabase
    //     .from('time_slots')                      // SUPABASE: table name
    //     .select('id, slot_time, is_available')
    //     .eq('expert_id', widget.expertId)        // SUPABASE: filter by expert
    //     .gte('slot_time', start.toIso8601String()) // SUPABASE: from start of day
    //     .lt('slot_time', end.toIso8601String())    // SUPABASE: to end of day
    //     .order('slot_time');
    //
    // setState(() {
    //   _timeSlots = (response as List).map((r) => TimeSlot.fromMap(r)).toList();
    // });

    // ── Demo data (remove when using Supabase) ──
    await Future.delayed(const Duration(milliseconds: 300));
    final slots = <TimeSlot>[];
    for (int i = 0; i < 20; i++) {
      slots.add(TimeSlot(
        id: 'slot_$i',
        dateTime: DateTime(2026, 2, 5, 8, 0),
        isAvailable: i != 15, // slot 15 is unavailable for demo
      ));
    }
    _timeSlots = slots;
  }

  // ── Booking confirmation ───────────────────

  Future<void> _confirmBooking() async {
    if (_selectedSlotId == null) return;

    // SUPABASE: Insert a new booking into the "bookings" table
    // await supabase.from('bookings').insert({  // SUPABASE: table name
    //   'expert_id': widget.expertId,           // SUPABASE: expert foreign key
    //   'slot_id': _selectedSlotId,             // SUPABASE: time slot foreign key
    //   'user_id': supabase.auth.currentUser?.id, // SUPABASE: logged-in user id
    //   'created_at': DateTime.now().toIso8601String(),
    // });

    // SUPABASE: Mark the slot as unavailable after booking
    // await supabase
    //     .from('time_slots')                    // SUPABASE: table name
    //     .update({'is_available': false})        // SUPABASE: set unavailable
    //     .eq('id', _selectedSlotId!);            // SUPABASE: target slot id

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الحجز بنجاح!'),
        backgroundColor: kPrimary,
      ),
    );
  }

  // ── Helpers ────────────────────────────────

  List<DateTime> get _daysInSelectedMonth {
    final first = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final last = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    return List.generate(
      last.day,
      (i) => DateTime(first.year, first.month, i + 1),
    );
  }

  int _availableSlotsForDay(DateTime day) {
    // SUPABASE: In production this count comes from the fetched slots per day
    if (day.day == 5) return 1;
    if (day.day == 4) return 3;
    if (day.day == 6) return 1;
    return 0;
  }

  String _arabicWeekday(DateTime date) {
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  String _arabicMonth(DateTime date) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate() {
    return '${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}-${_selectedDay.day.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildExpertCard(),
                          const SizedBox(height: 16),
                          _buildMonthSelector(),
                          const SizedBox(height: 12),
                          _buildDaySelector(),
                          const SizedBox(height: 16),
                          _buildTimeSlotsGrid(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  // ── Header ─────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.arrow_forward, size: 26),
          ),
          const Expanded(
            child: Text(
              'اختر التاريخ و الوقت',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 26),
        ],
      ),
    );
  }

  // ── Expert Card ────────────────────────────

  Widget _buildExpertCard() {
    final expert = _expert!;
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // SUPABASE: If avatar_url is set, load it with Image.network
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFD9D5C5),
                child: expert.avatarUrl != null
                    // SUPABASE: Load avatar from Supabase Storage URL
                    ? ClipOval(child: Image.network(expert.avatarUrl!, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: kPrimary, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(expert.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right),
                    Text(expert.title,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.right),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip(Icons.monetization_on_outlined, expert.priceLabel),
              _infoChip(Icons.location_on_outlined, expert.location),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        const SizedBox(width: 4),
        Icon(icon, size: 16, color: kPrimary),
      ],
    );
  }

  // ── Month Selector ─────────────────────────

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL order
        itemCount: _months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected = month.month == _selectedMonth.month &&
              month.year == _selectedMonth.year;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
                _selectedDay =
                    DateTime(month.year, month.month, 1);
                _selectedSlotId = null;
              });
              // SUPABASE: Re-fetch slots for the new selected day
              _fetchTimeSlots();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _arabicMonth(month),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Day Selector ───────────────────────────

  Widget _buildDaySelector() {
    // Show a window of days around the selected day
    final days = _daysInSelectedMonth;
    final selectedIndex = days.indexWhere((d) => d.day == _selectedDay.day);
    final start = (selectedIndex - 1).clamp(0, days.length - 3);
    final visible = days.sublist(start, (start + 3).clamp(0, days.length));

    return Row(
      children: visible.map((day) {
        final isSelected = day.day == _selectedDay.day;
        final slots = _availableSlotsForDay(day);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
                _selectedSlotId = null;
              });
              // SUPABASE: Re-fetch slots for the newly selected day
              _fetchTimeSlots();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? kPrimary : Colors.grey.shade300,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الأوقات المتاحة $slots',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Time Slots Grid ────────────────────────

  Widget _buildTimeSlotsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final slot = _timeSlots[index];
        final isSelected = slot.id == _selectedSlotId;

        Color bgColor;
        Color textColor;
        Border? border;

        if (!slot.isAvailable) {
          bgColor = kSlotUnavailable;
          textColor = Colors.white54;
          border = null;
        } else if (isSelected) {
          bgColor = Colors.white;
          textColor = kPrimary;
          border = Border.all(color: kPrimary, width: 1.5);
        } else {
          bgColor = kSlotAvailable;
          textColor = Colors.white;
          border = null;
        }

        return GestureDetector(
          onTap: slot.isAvailable
              ? () => setState(() => _selectedSlotId = slot.id)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              // SUPABASE: Format slot time from the real dateTime
              '${slot.dateTime.hour}:${slot.dateTime.minute.toString().padLeft(2, '0')} ص',
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Bottom Bar ─────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      color: kBackground,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legendItem('غير متاح', kSlotUnavailable),
              const SizedBox(width: 16),
              _legendItem('متاح', kSlotAvailable),
            ],
          ),
          const SizedBox(height: 8),
          // Selected date & time
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _selectedSlotId != null
                    ? '٨:٠٠ ص'
                    : '--:--',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.alarm, size: 16, color: Colors.black54),
              const SizedBox(width: 16),
              Text(
                _formatSelectedDate(),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 12),
          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSlotId != null ? _confirmBooking : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          const SizedBox(height: 8),
          const Text(
            '© 2025-2026',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
