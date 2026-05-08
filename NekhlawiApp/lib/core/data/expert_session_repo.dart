import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expert_session_item.dart';

class ExpertSessionRepo {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<ExpertSessionItem>> fetchUserSessions({
    required String userId,
    required List<String> statuses,
    int limit = 20,
    bool isExpert = false,
  }) async {

    final sessionsRes = await _db
        .from('ExpertSession')
        .select(
      'ExpertSessionID, UserID, ExpertID, Status, StartAt, EndAt, BookedAt',
    )
        .eq(isExpert ? 'ExpertID' : 'UserID', userId)
        .inFilter('Status', statuses)
        .order('StartAt', ascending: true)
        .limit(limit);

    final sessions = (sessionsRes as List).cast<Map<String, dynamic>>();

    if (sessions.isEmpty) return [];

    final expertIds = sessions
        .map((e) => e['ExpertID']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final userIds = sessions
        .map((e) => e['UserID']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final allIds = {...expertIds, ...userIds}.toList();

    final usersRes = await _db
        .from('User')
        .select('UserID, Name')
        .inFilter('UserID', allIds);

    final users = (usersRes as List).cast<Map<String, dynamic>>();

    final Map<String, String> idToName = {
      for (final u in users)
        u['UserID'].toString(): (u['Name'] ?? 'مستخدم').toString(),
    };

    return sessions.map((s) {

      final expertId = s['ExpertID']?.toString() ?? '';
      final userId = s['UserID']?.toString() ?? '';

      return ExpertSessionItem.fromMap(
        s,
        expertName: idToName[expertId] ?? 'خبير',
        userName: idToName[userId] ?? 'مزارع',
      );

    }).toList();
  }

  Future<void> createBooking({
    required String userId,
    required String expertId,
    required DateTime selectedDate,
  }) async {

    try {

      final existing = await _db
          .from('ExpertSession')
          .select('ExpertSessionID')
          .eq('ExpertID', expertId)
          .eq('StartAt', selectedDate.toIso8601String())
          .maybeSingle();

      if (existing != null) {
        throw Exception('هذا الموعد محجوز مسبقاً');
      }

      await _db.from('ExpertSession').insert({
        'UserID': userId,
        'ExpertID': expertId,
        'Status': 'pending',
        'StartAt': selectedDate.toIso8601String(),
        'BookedAt': DateTime.now().toIso8601String(),
      });

    } catch (e) {
      throw Exception('خطأ في الحجز: $e');
    }
  }
}


