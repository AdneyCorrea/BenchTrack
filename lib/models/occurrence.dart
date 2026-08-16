class Occurrence {
  final String id;
  final String testId;
  final String workstationId;
  final String tipo;
  final String descricao;
  final DateTime createdAt;
  final String? userId;

  const Occurrence({
    required this.id,
    required this.testId,
    required this.workstationId,
    required this.tipo,
    required this.descricao,
    required this.createdAt,
    this.userId,
  });

  factory Occurrence.fromMap(Map<String, dynamic> map) {
    return Occurrence(
      id: (map['id'] ?? '').toString(),
      testId: (map['stress_test_id'] ?? '').toString(),
      workstationId: (map['workstation_id'] ?? '').toString(),
      tipo: (map['tipo'] ?? 'Outro').toString(),
      descricao: (map['descricao'] ?? '').toString(),
      createdAt: DateTime.parse(map['created_at'].toString()).toLocal(),
      userId: map['user_id']?.toString(),
    );
  }
}
