import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/occurrence.dart';

class OccurrenceService {
  final SupabaseClient client;

  OccurrenceService(this.client);

  PostgrestQueryBuilder _table() {
    return client.schema('public').from('test_occurrences');
  }

  Future<List<Occurrence>> getForTest(String testId) async {
    final response = await _table()
        .select()
        .eq('stress_test_id', testId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => Occurrence.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }


Future<void> delete(String occurrenceId) async {
  await client
      .schema('public')
      .from('test_occurrences')
      .delete()
      .eq('id', occurrenceId);
}

Future<Occurrence> create({
    required String testId,
    required String workstationId,
    required String tipo,
    required String descricao,
  }) async {
    final userId = client.auth.currentUser?.id;

    final response = await _table()
        .insert({
          'stress_test_id': testId,
          'workstation_id': workstationId,
          'tipo': tipo,
          'descricao': descricao,
          'user_id': userId,
        })
        .select()
        .single();

    return Occurrence.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}
