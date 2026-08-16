class Attachment {
  final String id;
  final String workstationId;
  final String? stressTestId;
  final String? occurrenceId;
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime createdAt;
  final String? uploadedBy;

  const Attachment({
    required this.id,
    required this.workstationId,
    this.stressTestId,
    this.occurrenceId,
    required this.fileName,
    required this.storagePath,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
    this.uploadedBy,
  });

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: (map['id'] ?? '').toString(),
      workstationId: (map['workstation_id'] ?? '').toString(),
      stressTestId: map['stress_test_id']?.toString(),
      occurrenceId: map['occurrence_id']?.toString(),
      fileName: (map['file_name'] ?? '').toString(),
      storagePath: (map['storage_path'] ?? '').toString(),
      mimeType: map['mime_type']?.toString(),
      sizeBytes: map['size_bytes'] == null
          ? null
          : int.tryParse(map['size_bytes'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
      uploadedBy: map['uploaded_by']?.toString(),
    );
  }
}
