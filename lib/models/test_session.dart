class TestSession {
  final String id;
  final String workstationId;
  final String status;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? result;
  final String? observacoes;

  const TestSession({
    required this.id,
    required this.workstationId,
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.result,
    this.observacoes,
  });

  factory TestSession.fromMap(Map<String, dynamic> map) {
    return TestSession(
      id: (map['id'] ?? '').toString(),
      workstationId: (map['workstation_id'] ?? '').toString(),
      status: (map['status'] ?? 'Em andamento').toString(),
      startedAt: DateTime.parse(map['started_at'].toString()).toLocal(),
      finishedAt: map['finished_at'] == null
          ? null
          : DateTime.parse(map['finished_at'].toString()).toLocal(),
      result: map['result']?.toString(),
      observacoes: map['observacoes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'workstation_id': workstationId,
      'status': status,
      'started_at': startedAt.toUtc().toIso8601String(),
      'finished_at': finishedAt?.toUtc().toIso8601String(),
      'result': result,
      'observacoes': observacoes,
    };
  }
}
