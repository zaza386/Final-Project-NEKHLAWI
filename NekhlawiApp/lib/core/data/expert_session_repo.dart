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
    // 1) جيب سشنز اليوزر أو الخبير
    final sessionsRes = await _db
        .from('ExpertSession')
        .select('ExpertSessionID, UserID, ExpertID, Status, StartAt, EndAt, BookedAt')
        .eq(isExpert ? 'ExpertID' : 'UserID', userId)
        .inFilter('Status', statuses)
        .order('StartAt', ascending: true)
        .limit(limit);

    final sessions = (sessionsRes as List).cast<Map<String, dynamic>>();
    if (sessions.isEmpty) return [];

    // 2) اجمع ExpertIDs (هذي هي UserID حق الخبير)
    final expertIds = sessions
        .map((e) => e['ExpertID']?.toString())
        .where((id) => id != null && id!.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    // 3) جيب أسماء الخبراء من جدول User
    final usersRes = await _db
        .from('User')
        .select('UserID, Name')
        .inFilter('UserID', expertIds);

    final users = (usersRes as List).cast<Map<String, dynamic>>();

    final Map<String, String> idToName = {
      for (final u in users) u['UserID'].toString(): (u['Name'] ?? 'خبير').toString(),
    };

    // 4) ركّب الموديل مع اسم الخبير
    return sessions.map((s) {
      final expertId = s['ExpertID'].toString();
      final name = idToName[expertId] ?? 'خبير';
      return ExpertSessionItem.fromMap(s, expertName: name);
    }).toList();
  }
}