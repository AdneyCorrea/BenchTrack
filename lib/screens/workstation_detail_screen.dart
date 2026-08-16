import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../models/occurrence.dart';
import '../models/test_session.dart';
import '../models/workstation.dart';
import '../services/attachment_service.dart';
import '../services/occurrence_service.dart';
import '../services/test_service.dart';

class WorkstationDetailScreen extends StatefulWidget {
  final Workstation workstation;
  final VoidCallback onEdit;
  final VoidCallback onStartTest;

  const WorkstationDetailScreen({
    super.key,
    required this.workstation,
    required this.onEdit,
    required this.onStartTest,
  });

  @override
  State<WorkstationDetailScreen> createState() => _WorkstationDetailScreenState();
}

class _WorkstationDetailScreenState extends State<WorkstationDetailScreen> {
  late final TestService _testService;
  late final OccurrenceService _occurrenceService;
  late final AttachmentService _attachmentService;

  List<TestSession> _tests = [];
  List<Occurrence> _occurrences = [];
  List<Attachment> _attachments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _testService = TestService(client);
    _occurrenceService = OccurrenceService(client);
    _attachmentService = AttachmentService(client);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final active = await _testService.getActiveTests();
      final finished = await _testService.getFinishedTests();
      final tests = [
        ...active.where((t) => t.workstationId == widget.workstation.id),
        ...finished.where((t) => t.workstationId == widget.workstation.id),
      ];

      final occurrences = <Occurrence>[];
      for (final test in tests) {
        occurrences.addAll(await _occurrenceService.getForTest(test.id));
      }

      final allAttachments = await _attachmentService.getAll();
      final attachments = allAttachments
          .where((a) => a.workstationId == widget.workstation.id)
          .toList();

      if (!mounted) return;
      setState(() {
        _tests = tests;
        _occurrences = occurrences;
        _attachments = attachments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar o histórico desta Workstation.';
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Aprovada': return const Color(0xFF36C275);
      case 'Reprovada': return const Color(0xFFE31B23);
      case 'Teste 48h': return const Color(0xFFFFB020);
      case 'Aguardando teste': return const Color(0xFF7AA7FF);
      default: return Colors.white70;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Aprovada': return Icons.check_circle_rounded;
      case 'Reprovada': return Icons.cancel_rounded;
      case 'Teste 48h': return Icons.timer_rounded;
      case 'Aguardando teste': return Icons.hourglass_top_rounded;
      default: return Icons.build_rounded;
    }
  }

  String _date(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  Future<void> _openAttachment(Attachment attachment) async {
    try {
      final url = await _attachmentService.createSignedUrl(attachment.storagePath);
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o arquivo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.workstation.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Workstation'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;
          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(mobile ? 16 : 30, 20, mobile ? 16 : 30, 32),
              children: [
                _buildHero(color, mobile),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildQuickStats(mobile),
                  const SizedBox(height: 16),
                  _buildComponents(mobile),
                  const SizedBox(height: 16),
                  _buildTests(),
                  const SizedBox(height: 16),
                  _buildOccurrences(),
                  const SizedBox(height: 16),
                  _buildFiles(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(Color color, bool mobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 18 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: mobile ? 52 : 64,
                  height: mobile ? 52 : 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2022),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.computer_rounded, color: Color(0xFFE31B23), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.workstation.codigo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(
                        widget.workstation.pedido.isEmpty ? 'Sem número de pedido' : 'Pedido ${widget.workstation.pedido}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _badge(color)),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.workstation.status != 'Teste 48h')
                  FilledButton.icon(
                    onPressed: widget.onStartTest,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar teste 48h'),
                  ),
                OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Editar Workstation'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(widget.workstation.status), size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(widget.workstation.status, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool mobile) {
    final active = _tests.where((t) => t.status == 'Em andamento').length;
    final finished = _tests.where((t) => t.status == 'Finalizado').length;
    return GridView.count(
      crossAxisCount: mobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: mobile ? 1.65 : 2.4,
      children: [
        _stat(Icons.timer_rounded, 'Testes ativos', '$active', const Color(0xFFFFB020)),
        _stat(Icons.history_rounded, 'Testes finalizados', '$finished', const Color(0xFF7AA7FF)),
        _stat(Icons.warning_amber_rounded, 'Ocorrências', '${_occurrences.length}', const Color(0xFFE31B23)),
        _stat(Icons.attach_file_rounded, 'Arquivos', '${_attachments.length}', const Color(0xFF36C275)),
      ],
    );
  }

  Widget _stat(IconData icon, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55)))])),
          ],
        ),
      ),
    );
  }

  Widget _buildComponents(bool mobile) {
    return _section(
      title: 'Configuração da máquina',
      icon: Icons.memory_rounded,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _component('Processador', widget.workstation.processador, Icons.memory_rounded),
          _component('Placa-mãe', widget.workstation.placaMae, Icons.developer_board_rounded),
          _component('Memória RAM', widget.workstation.memoriaRam, Icons.sd_card_rounded),
          _component('Placa de vídeo', widget.workstation.placaVideo, Icons.videogame_asset_rounded),
          _component('Armazenamento', widget.workstation.armazenamento, Icons.storage_rounded),
          _component('Fonte', widget.workstation.fonte, Icons.bolt_rounded),
          _component('Cooler', widget.workstation.cooler, Icons.ac_unit_rounded),
          _component('Sistema operacional', widget.workstation.sistemaOperacional, Icons.desktop_windows_rounded),
        ],
      ),
    );
  }

  Widget _component(String label, String value, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF14161B), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFF292C33))),
      child: Row(children: [Icon(icon, size: 18, color: Colors.white54), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))), const SizedBox(height: 3), Text(value.isEmpty ? 'Não informado' : value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]))]),
    );
  }

  Widget _section({required String title, required IconData icon, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 19, color: const Color(0xFFE31B23)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))]),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }

  Widget _buildTests() {
    return _section(
      title: 'Histórico de testes 48h',
      icon: Icons.timer_rounded,
      child: _tests.isEmpty
          ? _muted('Nenhum teste registrado para esta Workstation.')
          : Column(children: _tests.map(_testRow).toList()),
    );
  }

  Widget _testRow(TestSession test) {
    final approved = test.result == 'Aprovada';
    final active = test.status == 'Em andamento';
    final color = active ? const Color(0xFFFFB020) : (approved ? const Color(0xFF36C275) : const Color(0xFFE31B23));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFF14161B), borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        Icon(active ? Icons.timer_rounded : (approved ? Icons.check_circle_rounded : Icons.cancel_rounded), color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(active ? 'Teste em andamento' : 'Teste finalizado', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 3), Text('Início: ${_date(test.startedAt)}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45))), if (!active && test.finishedAt != null) Text('Fim: ${_date(test.finishedAt!)}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.45)))])),
        if (!active) Text(test.result ?? 'Sem resultado', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
      ]),
    );
  }

  Widget _buildOccurrences() {
    return _section(
      title: 'Ocorrências',
      icon: Icons.warning_amber_rounded,
      child: _occurrences.isEmpty
          ? _muted('Nenhuma ocorrência registrada.')
          : Column(children: _occurrences.map((o) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFF14161B), borderRadius: BorderRadius.circular(11)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.warning_amber_rounded, color: Color(0xFFE31B23), size: 21), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.tipo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), const SizedBox(height: 4), Text(o.descricao, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.62))), const SizedBox(height: 4), Text(_date(o.createdAt), style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.35)))]))]))).toList()),
    );
  }

  Widget _buildFiles() {
    return _section(
      title: 'Arquivos da Workstation',
      icon: Icons.folder_rounded,
      child: _attachments.isEmpty
          ? _muted('Nenhum arquivo vinculado a esta Workstation.')
          : Column(
              children: _attachments.map<Widget>((a) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: Color(0xFF7AA7FF),
                  ),
                  title: Text(
                    a.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    AttachmentService.formatSize(a.sizeBytes),
                  ),
                  trailing: IconButton(
                    tooltip: 'Abrir',
                    onPressed: () => _openAttachment(a),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _muted(String text) => Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.50), fontSize: 12));

  Widget _buildError() => Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, color: Color(0xFFE31B23), size: 42), const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente'))])));
}
