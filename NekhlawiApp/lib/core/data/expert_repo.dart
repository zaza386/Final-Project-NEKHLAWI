import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expert_item.dart';

class ExpertRepo {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ExpertItem>> fetchExperts({String? query}) async {
    final q = (query ?? '').trim().toLowerCase();

    // نجيب البيانات من السيرفر (اسم من User + تخصص من ExpertProfile)
    final res = await _client
        .from('ExpertProfile')
        .select('''
          ExpertID,
          Specialization,
          User (
            Name,
            ProfilePicturePath
          )
        ''')
        .limit(200) // خله 100/200 حسب عددكم
        .timeout(const Duration(seconds: 10));
    print('RAW DATA FROM SUPABASE: $res');

    final all = (res as List)
        .map((e) => ExpertItem.fromMap(e as Map<String, dynamic>))
        // ✅ نشيل اللي اسمهم فاضي (بدون ما نعرض "خبير بدون اسم")
        .where((e) => e.name.trim().isNotEmpty)
        .toList();

    // بدون بحث
    if (q.isEmpty) return all;

    // ✅ بحث بالاسم أو التخصص
    return all.where((e) {
      final name = e.name.toLowerCase();
      final spec = e.specialization.toLowerCase();
      return name.contains(q) || spec.contains(q);
    }).toList();
  }
}