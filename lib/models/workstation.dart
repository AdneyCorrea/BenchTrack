class Workstation {
  String id;
  String codigo;
  String pedido;
  String responsavel;
  String processador;
  String placaMae;
  String memoriaRam;
  String placaVideo;
  String armazenamento;
  String fonte;
  String cooler;
  String sistemaOperacional;
  String observacoes;
  String status;

  Workstation({
    required this.id,
    required this.codigo,
    required this.pedido,
    required this.responsavel,
    required this.processador,
    required this.placaMae,
    required this.memoriaRam,
    required this.placaVideo,
    required this.armazenamento,
    required this.fonte,
    required this.cooler,
    required this.sistemaOperacional,
    required this.observacoes,
    required this.status,
  });

  factory Workstation.fromMap(Map<String, dynamic> map) {
    return Workstation(
      id: (map['id'] ?? '').toString(),
      codigo: (map['codigo'] ?? '').toString(),
      pedido: (map['pedido'] ?? '').toString(),
      responsavel: (map['responsavel'] ?? '').toString(),
      processador: (map['processador'] ?? '').toString(),
      placaMae: (map['placa_mae'] ?? '').toString(),
      memoriaRam: (map['memoria_ram'] ?? '').toString(),
      placaVideo: (map['placa_video'] ?? '').toString(),
      armazenamento: (map['armazenamento'] ?? '').toString(),
      fonte: (map['fonte'] ?? '').toString(),
      cooler: (map['cooler'] ?? '').toString(),
      sistemaOperacional: (map['sistema_operacional'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      status: (map['status'] ?? 'Montagem').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id.isNotEmpty) 'id': id,
    'codigo': codigo,
    'pedido': pedido,
    'responsavel': responsavel,
    'processador': processador,
    'placa_mae': placaMae,
    'memoria_ram': memoriaRam,
    'placa_video': placaVideo,
    'armazenamento': armazenamento,
    'fonte': fonte,
    'cooler': cooler,
    'sistema_operacional': sistemaOperacional,
    'observacoes': observacoes,
    'status': status,
  };
}
