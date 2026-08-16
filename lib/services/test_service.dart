import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/test_session.dart';

class TestService {
  final SupabaseClient client;

  TestService(this.client);

  PostgrestQueryBuilder _table() {
    return client.schema('public').from('stress_tests');
  }

  Future<List<TestSession>> getActiveTests() async {
    final response = await _table()
        .select()
        .eq('status', 'Em andamento')
        .order('started_at', ascending: true);

    return (response as List)
        .map(
          (item) => TestSession.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<TestSession>> getFinishedTests() async {
    final response = await _table()
        .select()
        .eq('status', 'Finalizado')
        .order('finished_at', ascending: false);

    return (response as List)
        .map(
          (item) => TestSession.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<TestSession?> getActiveTestForWorkstation(
    String workstationId,
  ) async {
    final response = await _table()
        .select()
        .eq('workstation_id', workstationId)
        .eq('status', 'Em andamento')
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return TestSession.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<TestSession> startTest(String workstationId) async {
    final existing = await getActiveTestForWorkstation(workstationId);

    if (existing != null) {
      return existing;
    }

    final response = await _table()
        .insert({
          'workstation_id': workstationId,
          'status': 'Em andamento',
          'started_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single();

    return TestSession.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  Future<TestSession> finishTest({
    required String testId,
    required String result,
    String? observacoes,
  }) async {
    final response = await _table()
        .update({
          'status': 'Finalizado',
          'finished_at': DateTime.now().toUtc().toIso8601String(),
          'result': result,
          'observacoes': observacoes,
        })
        .eq('id', testId)
        .select()
        .single();

    return TestSession.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}
