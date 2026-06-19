import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/internship_application_model.dart';

class InternshipRepository {
  final SupabaseClient supabase =
      Supabase.instance.client;

  Future<Map<String, int>>
      getDashboardStatistics() async {
    final response = await supabase
        .from('internship_applications')
        .select('status');

    final data = response as List;

    int total = data.length;

    int pending = data
        .where(
          (e) => e['status'] == 'pending',
        )
        .length;

    int diterima = data
        .where(
          (e) => e['status'] == 'diterima',
        )
        .length;

    int ditolak = data
        .where(
          (e) => e['status'] == 'ditolak',
        )
        .length;

    return {
      'total': total,
      'pending': pending,
      'diterima': diterima,
      'ditolak': ditolak,
    };
  }

  Future<List<InternshipApplication>>
      getApplications() async {
    final response = await supabase
        .from('internship_applications')
        .select()
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (e) =>
              InternshipApplication
                  .fromJson(e),
        )
        .toList();
  }

  Future<void> approveApplication({
    required String applicationId,
    required String reviewerId,
    String? urlSuratBalasan,
  }) async {
    await supabase
        .from('internship_applications')
        .update({
      'status': 'diterima',
      'reviewed_by': reviewerId,
      'reviewed_at':
          DateTime.now()
              .toIso8601String(),
      if (urlSuratBalasan != null)
        'url_surat_balasan': urlSuratBalasan,
    }).eq('id', applicationId);
  }

  Future<void> rejectApplication({
    required String applicationId,
    required String reviewerId,
    required String alasan,
  }) async {
    await supabase
        .from('internship_applications')
        .update({
      'status': 'ditolak',
      'alasan_penolakan': alasan,
      'reviewed_by': reviewerId,
      'reviewed_at':
          DateTime.now()
              .toIso8601String(),
    }).eq('id', applicationId);
  }

  Future<InternshipApplication?>
      getApplicationById(
    String id,
  ) async {
    final response = await supabase
        .from('internship_applications')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return InternshipApplication
        .fromJson(response);
  }
  Future<int> getMaxQuota() async {
  final response = await supabase
      .from('internship_settings')
      .select('max_quota')
      .eq('id', 1)
      .single();

  return response['max_quota'] ?? 20;
}

Future<void> updateMaxQuota(
  int quota,
) async {
  await supabase
      .from('internship_settings')
      .update({
        'max_quota': quota,
      })
      .eq('id', 1);
}
}