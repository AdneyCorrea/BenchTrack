import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteService {
  final SupabaseClient client;

  DeleteService(this.client);

  Future<void> deleteOccurrence(String occurrenceId) async {
    final files = await client
        .schema('public')
        .from('attachments')
        .select('id, storage_path')
        .eq('occurrence_id', occurrenceId);

    final paths = <String>[];
    for (final item in (files as List)) {
      final path = (item['storage_path'] ?? '').toString();
      if (path.isNotEmpty) paths.add(path);
    }

    if (paths.isNotEmpty) {
      await client.storage.from('benchtrack-files').remove(paths);
    }

    await client
        .schema('public')
        .from('test_occurrences')
        .delete()
        .eq('id', occurrenceId);
  }

  Future<void> deleteAttachment({
    required String attachmentId,
    required String storagePath,
  }) async {
    if (storagePath.isNotEmpty) {
      await client.storage.from('benchtrack-files').remove([
        storagePath,
      ]);
    }

    await client
        .schema('public')
        .from('attachments')
        .delete()
        .eq('id', attachmentId);
  }

  Future<void> deleteTest(String testId) async {
    final files = await client
        .schema('public')
        .from('attachments')
        .select('storage_path')
        .eq('stress_test_id', testId);

    final paths = <String>[];
    for (final item in (files as List)) {
      final path = (item['storage_path'] ?? '').toString();
      if (path.isNotEmpty) paths.add(path);
    }

    if (paths.isNotEmpty) {
      await client.storage.from('benchtrack-files').remove(paths);
    }

    await client
        .schema('public')
        .from('stress_tests')
        .delete()
        .eq('id', testId);
  }

  Future<void> deleteWorkstation(String workstationId) async {
    final files = await client
        .schema('public')
        .from('attachments')
        .select('storage_path')
        .eq('workstation_id', workstationId);

    final paths = <String>[];
    for (final item in (files as List)) {
      final path = (item['storage_path'] ?? '').toString();
      if (path.isNotEmpty) paths.add(path);
    }

    if (paths.isNotEmpty) {
      await client.storage.from('benchtrack-files').remove(paths);
    }

    await client
        .schema('public')
        .from('workstations')
        .delete()
        .eq('id', workstationId);
  }
}
