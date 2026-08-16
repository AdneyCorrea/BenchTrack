import 'package:flutter/material.dart';
import '../models/workstation.dart';

class WorkstationFormScreen extends StatefulWidget {
  final Workstation? workstation;
  const WorkstationFormScreen({super.key, this.workstation});
  @override
  State<WorkstationFormScreen> createState() => _WorkstationFormScreenState();
}

class _WorkstationFormScreenState extends State<WorkstationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController codigo, pedido, responsavel, processador, placaMae, memoriaRam, placaVideo, armazenamento, fonte, cooler, sistema, observacoes;
  String status = 'Montagem';
  final statuses = const ['Montagem', 'Aguardando teste', 'Teste 48h', 'Aprovada', 'Reprovada'];

  bool get editing => widget.workstation != null;

  @override
  void initState() {
    super.initState();
    final w = widget.workstation;
    codigo = TextEditingController(text: w?.codigo ?? '');
    pedido = TextEditingController(text: w?.pedido ?? '');
    responsavel = TextEditingController(text: w?.responsavel ?? '');
    processador = TextEditingController(text: w?.processador ?? '');
    placaMae = TextEditingController(text: w?.placaMae ?? '');
    memoriaRam = TextEditingController(text: w?.memoriaRam ?? '');
    placaVideo = TextEditingController(text: w?.placaVideo ?? '');
    armazenamento = TextEditingController(text: w?.armazenamento ?? '');
    fonte = TextEditingController(text: w?.fonte ?? '');
    cooler = TextEditingController(text: w?.cooler ?? '');
    sistema = TextEditingController(text: w?.sistemaOperacional ?? '');
    observacoes = TextEditingController(text: w?.observacoes ?? '');
    status = w?.status ?? 'Montagem';
  }

  @override
  void dispose() {
    for (final c in [codigo,pedido,responsavel,processador,placaMae,memoriaRam,placaVideo,armazenamento,fonte,cooler,sistema,observacoes]) { c.dispose(); }
    super.dispose();
  }

  void save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Workstation(
      id: widget.workstation?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      codigo: codigo.text.trim(), pedido: pedido.text.trim(), responsavel: responsavel.text.trim(),
      processador: processador.text.trim(), placaMae: placaMae.text.trim(), memoriaRam: memoriaRam.text.trim(),
      placaVideo: placaVideo.text.trim(), armazenamento: armazenamento.text.trim(), fonte: fonte.text.trim(),
      cooler: cooler.text.trim(), sistemaOperacional: sistema.text.trim(), observacoes: observacoes.text.trim(), status: status,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar Workstation' : 'Nova Workstation')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 800;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: desktop ? 40 : 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Title('Identificação'),
                    const SizedBox(height: 16),
                    _fields(desktop, [
                      _field(codigo, 'Código da Workstation', 'Ex.: WS-000127', Icons.qr_code_rounded, true),
                      _field(pedido, 'Número do pedido', 'Ex.: 123456', Icons.receipt_long_rounded),
                      _field(responsavel, 'Técnico responsável', 'Nome do técnico', Icons.person_rounded, true),
                    ]),
                    const SizedBox(height: 32),
                    const _Title('Hardware'),
                    const SizedBox(height: 16),
                    _fields(desktop, [
                      _field(processador, 'Processador', 'Ex.: Ryzen 9 7950X', Icons.memory_rounded, true),
                      _field(placaMae, 'Placa-mãe', 'Ex.: ASUS X670E', Icons.developer_board_rounded, true),
                      _field(memoriaRam, 'Memória RAM', 'Ex.: 64 GB DDR5 6000', Icons.sd_card_rounded, true),
                      _field(placaVideo, 'Placa de vídeo', 'Ex.: RTX 4080 SUPER', Icons.videogame_asset_rounded, true),
                      _field(armazenamento, 'Armazenamento', 'Ex.: 2 TB NVMe', Icons.storage_rounded, true),
                      _field(fonte, 'Fonte', 'Ex.: 1000W 80 Plus Gold', Icons.bolt_rounded, true),
                      _field(cooler, 'Cooler', 'Ex.: Water Cooler 360mm', Icons.ac_unit_rounded),
                    ]),
                    const SizedBox(height: 32),
                    const _Title('Sistema'),
                    const SizedBox(height: 16),
                    _fields(desktop, [_field(sistema, 'Sistema operacional', 'Ex.: Windows 11 Pro', Icons.desktop_windows_rounded), _statusField()]),
                    const SizedBox(height: 16),
                    TextFormField(controller: observacoes, maxLines: 5, decoration: const InputDecoration(labelText: 'Observações', hintText: 'Adicione informações importantes sobre a máquina...', alignLabelWithHint: true, prefixIcon: Padding(padding: EdgeInsets.only(bottom: 70), child: Icon(Icons.notes_rounded)))),
                    const SizedBox(height: 36),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), const SizedBox(width: 12), FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: Text(editing ? 'Salvar alterações' : 'Cadastrar Workstation'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31B23), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)))])
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _fields(bool desktop, List<Widget> list) {
    if (!desktop) return Column(children: list.map((w) => Padding(padding: const EdgeInsets.only(bottom: 14), child: w)).toList());
    return Wrap(spacing: 16, runSpacing: 16, children: list.map((w) => SizedBox(width: 480, child: w)).toList());
  }

  Widget _field(TextEditingController c, String label, String hint, IconData icon, [bool required = false]) {
    return TextFormField(controller: c, decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)), validator: required ? (v) => v == null || v.trim().isEmpty ? 'Preencha este campo' : null : null);
  }

  Widget _statusField() {
    return DropdownButtonFormField<String>(
      initialValue: status,
      decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag_rounded)),
      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (v) { if (v != null) setState(() => status = v); },
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
}
