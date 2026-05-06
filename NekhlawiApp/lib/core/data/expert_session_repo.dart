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
    // 1) جيب السشنز
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

    // 2) اجمع كل IDs (خبراء + مزارعين)
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

    // 3) جيب كل الأسماء مرة وحدة
    final usersRes = await _db
        .from('User')
        .select('UserID, Name')
        .inFilter('UserID', allIds);

    final users = (usersRes as List).cast<Map<String, dynamic>>();

    final Map<String, String> idToName = {
      for (final u in users)
        u['UserID'].toString(): (u['Name'] ?? 'مستخدم').toString(),
    };

    // 4) ركّب الموديل (🔥 التعديل هنا)
    return sessions.map((s) {
      final expertId = s['ExpertID'].toString();
      final userId = s['UserID'].toString();

      final expertName = idToName[expertId] ?? 'خبير';
      final userName = idToName[userId] ?? 'مزارع';

      return ExpertSessionItem.fromMap(
        s,
        expertName: expertName,
        userName: userName, // ✅ مهم
      );
    }).toList();
  }
}
