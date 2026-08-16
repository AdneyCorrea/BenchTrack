import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';

class AttachmentService {
  static const String bucket = 'benchtrack-files';

  final SupabaseClient client;

  AttachmentService(this.client);

  PostgrestQueryBuilder _table() {
    return client.schema('public').from('attachments');
  }

  Future<List<Attachment>> getAll() async {
    final response = await _table()
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Attachment.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<Attachment?> pickAndUploadForWorkstation({
    required String workstationId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.isEmpty) {
      throw StateError('O sistema não forneceu o caminho do arquivo.');
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Usuário não autenticado.');

    final safeName = _sanitizeFileName(picked.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        '$userId/workstations/$workstationId/general/${timestamp}_$safeName';

    await client.storage.from(bucket).upload(
      storagePath,
      File(path),
      fileOptions: const FileOptions(upsert: false, cacheControl: '3600'),
    );

    try {
      final response = await _table().insert({
        'workstation_id': workstationId,
        'file_name': picked.name,
        'storage_path': storagePath,
        'mime_type': null,
        'size_bytes': picked.size,
        'uploaded_by': userId,
      }).select().single();

      return Attachment.fromMap(Map<String, dynamic>.from(response));
    } catch (error) {
      try {
        await client.storage.from(bucket).remove([storagePath]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<Attachment>> getForTest(String testId) async {
    final response = await _table()
        .select()
        .eq('stress_test_id', testId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => Attachment.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<Attachment>> getForOccurrence(String occurrenceId) async {
    final response = await _table()
        .select()
        .eq('occurrence_id', occurrenceId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) => Attachment.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Attachment?> pickAndUploadForOccurrence({
    required String workstationId,
    required String testId,
    required String occurrenceId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;
    final path = picked.path;

    if (path == null || path.isEmpty) {
      throw StateError('O sistema não forneceu o caminho do arquivo.');
    }

    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Usuário não autenticado.');
    }

    final safeName = _sanitizeFileName(picked.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        '$userId/workstations/$workstationId/tests/$testId/occurrences/$occurrenceId/${timestamp}_$safeName';

    final file = File(path);

    await client.storage.from(bucket).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(
        upsert: false,
        cacheControl: '3600',
      ),
    );

    try {
      final response = await _table().insert({
        'workstation_id': workstationId,
        'stress_test_id': testId,
        'occurrence_id': occurrenceId,
        'file_name': picked.name,
        'storage_path': storagePath,
        'mime_type': null,
        'size_bytes': picked.size,
        'uploaded_by': userId,
      }).select().single();

      return Attachment.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (error) {
      // If the metadata insert fails, do not leave an orphaned object.
      try {
        await client.storage.from(bucket).remove([storagePath]);
      } catch (_) {
        // Keep the original error as the useful one for the user.
      }
      rethrow;
    }
  }

  Future<String> createSignedUrl(String storagePath) {
    return client.storage.from(bucket).createSignedUrl(
      storagePath,
      3600,
    );
  }

  String _sanitizeFileName(String name) {
    final normalized = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return normalized.isEmpty ? 'arquivo' : normalized;
  }

  static String formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Tamanho desconhecido';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
