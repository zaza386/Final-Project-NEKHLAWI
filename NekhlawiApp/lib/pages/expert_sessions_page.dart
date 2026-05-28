import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/header_background.dart';

// Internal slot model — mirrors TimeSlot in booking_page.dart exactly
class _Slot {
  final String? id;
  final DateTime dateTime; // result of DateTime.parse(slot_time) — NOT converted to local
  final bool isAvailable;

  _Slot({this.id, required this.dateTime, required this.isAvailable});

  factory _Slot.fromMap(Map<String, dynamic> map) {
    return _Slot(
      id: map['id']?.toString(),
      dateTime: DateTime.parse(map['slot_time']), // same as TimeSlot.fromMap
      isAvailable: map['is_available'] ?? false,
    );
  }
}

class ExpertSessionsPage extends StatefulWidget {
  const ExpertSessionsPage({super.key});

  @override
  State<ExpertSessionsPage> createState() => _ExpertSessionsPageState();
}

class _ExpertSessionsPageState extends State<ExpertSessionsPage> {
  final supabase = Supabase.instance.client;

  // Exact same color constants as booking_page.dart
  static const Color kPrimary         = Color(0xFF797F3D);
  static const Color kBackground      = Color(0xFFF2F0E8);
  static const Color kCard            = Color(0xFFFFFFFF);
  static const Color kSlotAvailable   = Color(0xFFD4D0C4);
  static const Color kSlotUnavailable = Color(0xFF8E8E8E);

  bool _isLoading = false;
  bool _isSaving  = false;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay   = DateTime.now();

  late final List<DateTime> _months = _generateMonths();

  List<_Slot> _dbSlots      = [];
  List<_Slot> _displaySlots = [];

  // Which hour:minute keys the expert has toggled ON
  // Key format: "H:MM" — same numbers booking_page uses for matching (.hour / .minute)
  final Set<String> _enabledKeys = {};

  List<DateTime> _generateMonths() {
    final now = DateTime.now();
    return List.generate(6, (i) => DateTime(now.year, now.month + i, 1));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── KEY INSIGHT ────────────────────────────────────────────────────────────
  // booking_page.dart stores slots by querying:
  //   gte('slot_time', DateTime.utc(day.year, day.month, day.day))
  // and matches them with:
  //   s.dateTime.hour == hour   ← dateTime = DateTime.parse(slot_time), NO .toLocal()
  //
  // So booking_page treats the raw UTC hour in the stored string as the display hour.
  // To match, we must store:  "YYYY-MM-DDThh:mm:00.000Z"
  // where hh:mm is the LOCAL hour the expert picked — NOT converted to real UTC.
  // i.e., expert picks 13:00 local → we store "...T13:00:00.000Z"
  // booking_page then sees .hour == 13 and displays "1:00 م" ✓
  // ────────────────────────────────────────────────────────────────────────────

  // Build a slot_time string that booking_page will read correctly.
  // We write the local h/m directly into a UTC-formatted string.
  String _slotTimeString(int hour, int minute) {
    final y  = _selectedDay.year.toString().padLeft(4, '0');
    final mo = _selectedDay.month.toString().padLeft(2, '0');
    final d  = _selectedDay.day.toString().padLeft(2, '0');
    final h  = hour.toString().padLeft(2, '0');
    final mi = minute.toString().padLeft(2, '0');
    return '${y}-${mo}-${d}T${h}:${mi}:00.000Z';
  }

  // The query range booking_page uses — we must use the same range to fetch
  // the same rows, since Supabase compares the stored "fake UTC" string.
  String _dayStartString() {
    final y  = _selectedDay.year.toString().padLeft(4, '0');
    final mo = _selectedDay.month.toString().padLeft(2, '0');
    final d  = _selectedDay.day.toString().padLeft(2, '0');
    return '${y}-${mo}-${d}T00:00:00.000Z';
  }

  String _dayEndString() {
    final next = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day + 1);
    final y  = next.year.toString().padLeft(4, '0');
    final mo = next.month.toString().padLeft(2, '0');
    final d  = next.day.toString().padLeft(2, '0');
    return '${y}-${mo}-${d}T00:00:00.000Z';
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final expertId = supabase.auth.currentUser?.id;
      if (expertId == null) return;

      final response = await supabase
          .from('time_slots')
          .select('id, slot_time, is_available')
          .eq('ExpertID', expertId)
          .gte('slot_time', _dayStartString())
          .lt('slot_time', _dayEndString())
          .order('slot_time');

      _dbSlots = (response as List).map((r) => _Slot.fromMap(r)).toList();
      _buildDisplaySlots();
      _syncEnabledKeys();
    } catch (e) {
      debugPrint('ExpertSessionsPage._loadData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mirrors booking_page._generateHalfHourSlots — matches on raw .hour / .minute
  void _buildDisplaySlots() {
    final slots = <_Slot>[];
    for (int hour = 8; hour <= 19; hour++) {
      for (int minute in [0, 30]) {

        final slotTime = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day,
          hour, minute,
        );

        // Same match as booking_page line 168 — raw .hour, raw .minute (no toLocal)
        final dbMatch = _dbSlots.firstWhere(
          (s) => s.dateTime.hour == hour && s.dateTime.minute == minute,
          orElse: () => _Slot(dateTime: slotTime, isAvailable: false),
        );
        final existsInDb = _dbSlots.any(
          (s) => s.dateTime.hour == hour && s.dateTime.minute == minute,
        );

        slots.add(_Slot(
          id: existsInDb ? dbMatch.id : null,
          dateTime: slotTime,
          isAvailable: existsInDb ? dbMatch.isAvailable : false,
        ));
      }
    }
    _displaySlots = slots;
  }

  // Pre-check any slot that already exists in DB
  void _syncEnabledKeys() {
    _enabledKeys.clear();
    for (final s in _dbSlots) {
      _enabledKeys.add('${s.dateTime.hour}:${s.dateTime.minute}');
    }
  }

  String _slotKey(_Slot slot) => '${slot.dateTime.hour}:${slot.dateTime.minute}';

  bool _isBooked(_Slot slot) {
    final k = _slotKey(slot);
    final db = _dbSlots.firstWhere(
      (s) => '${s.dateTime.hour}:${s.dateTime.minute}' == k,
      orElse: () => _Slot(dateTime: slot.dateTime, isAvailable: true),
    );
    final existsInDb = _dbSlots.any(
      (s) => '${s.dateTime.hour}:${s.dateTime.minute}' == k,
    );
    return existsInDb && !db.isAvailable;
  }

  void _toggleSlot(_Slot slot) {
    if (_isBooked(slot)) return;
    final k = _slotKey(slot);
    setState(() {
      if (_enabledKeys.contains(k)) {
        _enabledKeys.remove(k);
      } else {
        _enabledKeys.add(k);
      }
    });
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    try {
      final expertId = supabase.auth.currentUser?.id;
      if (expertId == null) return;

      final dbKeys = <String>{};
      for (final s in _dbSlots) {
        dbKeys.add('${s.dateTime.hour}:${s.dateTime.minute}');
      }

      final toInsert = _enabledKeys.difference(dbKeys);
      final toDelete = dbKeys.difference(_enabledKeys);

      if (toInsert.isNotEmpty) {
        final inserts = toInsert.map((k) {
          final parts  = k.split(':');
          final hour   = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          return {
            'ExpertID'    : expertId,
            // Store local hour directly as UTC string — matches how booking_page reads it
            'slot_time'   : _slotTimeString(hour, minute),
            'is_available': true,
          };
        }).toList();
        await supabase.from('time_slots').insert(inserts);
      }

      for (final k in toDelete) {
        final dbSlot = _dbSlots.firstWhere(
          (s) => '${s.dateTime.hour}:${s.dateTime.minute}' == k,
          orElse: () => _Slot(dateTime: DateTime.now(), isAvailable: false),
        );
        if (dbSlot.id != null && dbSlot.isAvailable) {
          await supabase.from('time_slots').delete().eq('id', dbSlot.id!);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ أوقات التوفر بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<int> _fetchEnabledCountForDay(DateTime day) async {
    final expertId = supabase.auth.currentUser?.id ?? '';
    final next  = DateTime(day.year, day.month, day.day + 1);
    final start = '${day.year.toString().padLeft(4,'0')}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}T00:00:00.000Z';
    final end   = '${next.year.toString().padLeft(4,'0')}-${next.month.toString().padLeft(2,'0')}-${next.day.toString().padLeft(2,'0')}T00:00:00.000Z';
    final response = await supabase
        .from('time_slots')
        .select('id')
        .eq('ExpertID', expertId)
        .eq('is_available', true)
        .gte('slot_time', start)
        .lt('slot_time', end);
    return (response as List).length;
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(lastDay, (i) => DateTime(month.year, month.month, i + 1));
  }

  String _arabicWeekday(DateTime date) {
    const days = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
    return days[date.weekday - 1];
  }

  String _arabicMonth(DateTime date) {
    const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                    'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Exact same logic as booking_page._formatSlotTime
  String _formatSlotTime(DateTime dt) {
    final hour   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
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
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 90,
                child: HeaderBackground(title: 'إدارة أوقات التوفر'),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.only(
                    topLeft:  Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMonthScrollSelector(),
                            const SizedBox(height: 12),
                            _buildDayScrollSelector(),
                            const SizedBox(height: 16),
                            _buildTimeSlotsGrid(),
                            const SizedBox(height: 16),
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

  Widget _buildMonthScrollSelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final month = _months[index];
          final isSelected =
              month.month == _selectedMonth.month &&
              month.year  == _selectedMonth.year;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMonth = month;
                _selectedDay   = DateTime(month.year, month.month, 1);
              });
              _loadData();
            },
            child: Container(
              margin:  const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color:        isSelected ? kPrimary : kCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  _arabicMonth(month),
                  style: TextStyle(
                    color:    isSelected ? Colors.white : Colors.black87,
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
              day.day   == _selectedDay.day &&
              day.month == _selectedDay.month;

          return FutureBuilder<int>(
            future: _fetchEnabledCountForDay(day),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _enabledKeys.clear();
                  });
                  _loadData();
                },
                child: Container(
                  width:  78,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color:        isSelected ? kPrimary : kCard,
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
                          fontSize:   20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        _arabicWeekday(day),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'متاح: $count',
                        style: TextStyle(
                          fontSize:   9,
                          color:      isSelected ? Colors.white60 : kPrimary,
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
      padding:     const EdgeInsets.only(bottom: 10),
      shrinkWrap:  true,
      physics:     const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
      ),
      itemCount: _displaySlots.length,
      itemBuilder: (context, index) {
        final slot    = _displaySlots[index];
        final booked  = _isBooked(slot);
        final enabled = _enabledKeys.contains(_slotKey(slot));

        final Color bgColor;
        final Color textColor = Colors.white;

        if (booked) {
          bgColor = kSlotUnavailable;
        } else if (enabled) {
          bgColor = kPrimary;
        } else {
          bgColor = kSlotAvailable;
        }

        return GestureDetector(
          onTap: booked ? null : () => _toggleSlot(slot),
          child: Container(
            decoration: BoxDecoration(
              color:        bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              _formatSlotTime(slot.dateTime),
              style: TextStyle(fontSize: 11, color: textColor),
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
              _legendItem('محجوز',      kSlotUnavailable),
              const SizedBox(width: 16),
              _legendItem('غير مفعّل', kSlotAvailable),
              const SizedBox(width: 16),
              _legendItem('مفعّل',     kPrimary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (final s in _displaySlots) {
                        if (!_isBooked(s)) _enabledKeys.add(_slotKey(s));
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimary,
                    side:  const BorderSide(color: kPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('تحديد الكل', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      for (final s in _displaySlots) {
                        if (!_isBooked(s)) _enabledKeys.remove(_slotKey(s));
                      }
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side:  const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('إلغاء الكل', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor:         kPrimary,
                disabledBackgroundColor: kPrimary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'حفظ أوقات التوفر',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}