import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../models/occurrence.dart';
import '../models/test_session.dart';
import '../models/workstation.dart';
import '../services/attachment_service.dart';
import '../services/occurrence_service.dart';

class TestDetailScreen extends StatefulWidget {
  final TestSession test;
  final Workstation workstation;

  const TestDetailScreen({
    super.key,
    required this.test,
    required this.workstation,
  });

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  late final OccurrenceService _occurrenceService;
  late final AttachmentService _attachmentService;

  List<Occurrence> _occurrences = [];
  List<Attachment> _attachments = [];
  bool _loading = true;
  String? _error;

  bool get _active => widget.test.status == 'Em andamento';

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _occurrenceService = OccurrenceService(client);
    _attachmentService = AttachmentService(client);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final occurrences = await _occurrenceService.getForTest(widget.test.id);
      final attachments = await _attachmentService.getForTest(widget.test.id);

      if (!mounted) return;
      setState(() {
        _occurrences = occurrences;
        _attachments = attachments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os detalhes deste teste.';
      });
    }
  }

  Color get _resultColor {
    if (_active) return const Color(0xFFFFB020);
    return widget.test.result == 'Aprovada'
        ? const Color(0xFF36C275)
        : const Color(0xFFE31B23);
  }

  IconData get _resultIcon {
    if (_active) return Icons.timer_rounded;
    return widget.test.result == 'Aprovada'
        ? Icons.check_circle_rounded
        : Icons.cancel_rounded;
  }

  String _date(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }

  String _duration() {
    final end = widget.test.finishedAt ?? DateTime.now();
    final difference = end.difference(widget.test.startedAt);
    final seconds = difference.inSeconds.clamp(0, 48 * 60 * 60);
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _openAttachment(Attachment attachment) async {
    try {
      final url = await _attachmentService.createSignedUrl(attachment.storagePath);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        _showMessage('Não foi possível abrir o arquivo.');
      }
    } catch (_) {
      if (mounted) _showMessage('Não foi possível abrir o arquivo.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do teste'),
        actions: [
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
              padding: EdgeInsets.fromLTRB(
                mobile ? 16 : 30,
                20,
                mobile ? 16 : 30,
                32,
              ),
              children: [
                _buildHeader(mobile),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  _buildError()
                else ...[
                  _buildSummary(mobile),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 16),
                  _buildFiles(),
                  if (widget.test.observacoes != null &&
                      widget.test.observacoes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildObservations(),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool mobile) {
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
                  width: mobile ? 52 : 62,
                  height: mobile ? 52 : 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2022),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _resultIcon,
                    color: _resultColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.workstation.codigo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teste de stress de 48 horas',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: _badge()),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.workstation.processador.isEmpty ? 'Processador não informado' : widget.workstation.processador} • '
              '${widget.workstation.placaVideo.isEmpty ? 'GPU não informada' : widget.workstation.placaVideo}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge() {
    final label = _active ? 'Em andamento' : (widget.test.result ?? 'Sem resultado');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: _resultColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_resultIcon, size: 16, color: _resultColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _resultColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool mobile) {
    return GridView.count(
      crossAxisCount: mobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: mobile ? 1.65 : 2.4,
      children: [
        _stat(Icons.play_circle_outline_rounded, 'Início', _date(widget.test.startedAt), const Color(0xFF7AA7FF)),
        _stat(Icons.stop_circle_outlined, 'Fim', widget.test.finishedAt == null ? 'Em andamento' : _date(widget.test.finishedAt!), const Color(0xFF7AA7FF)),
        _stat(Icons.timer_rounded, 'Duração', _duration(), _resultColor),
        _stat(Icons.warning_amber_rounded, 'Ocorrências', '${_occurrences.length}', const Color(0xFFE31B23)),
      ],
    );
  }

  double _progress() {
    final end = widget.test.finishedAt ?? DateTime.now();
    final seconds = end.difference(widget.test.startedAt).inSeconds;
    return (seconds / (48 * 3600)).clamp(0.0, 1.0);
  }

  Widget _stat(IconData icon, String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final events = <_TimelineEvent>[];

    events.add(
      _TimelineEvent(
        date: widget.test.startedAt,
        title: 'Teste iniciado',
        description: 'O teste de stress de 48 horas foi iniciado.',
        icon: Icons.play_arrow_rounded,
        color: const Color(0xFF7AA7FF),
      ),
    );

    for (final occurrence in _occurrences) {
      events.add(
        _TimelineEvent(
          date: occurrence.createdAt,
          title: occurrence.tipo,
          description: occurrence.descricao,
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFE31B23),
          occurrence: occurrence,
        ),
      );
    }

    if (widget.test.finishedAt != null) {
      final approved = widget.test.result == 'Aprovada';
      events.add(
        _TimelineEvent(
          date: widget.test.finishedAt!,
          title: approved ? 'Teste aprovado' : 'Teste reprovado',
          description: approved
              ? 'A Workstation foi aprovada no teste de 48 horas.'
              : 'A Workstation foi reprovada no teste de 48 horas.',
          icon: approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: approved
              ? const Color(0xFF36C275)
              : const Color(0xFFE31B23),
        ),
      );
    }

    events.sort((a, b) => a.date.compareTo(b.date));

    return _section(
      title: 'Linha do tempo',
      icon: Icons.timeline_rounded,
      child: Column(
        children: events
            .asMap()
            .entries
            .map((entry) => _timelineTile(entry.value, entry.key < events.length - 1))
            .toList(),
      ),
    );
  }

  Widget _timelineTile(_TimelineEvent event, bool hasNext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(event.icon, size: 16, color: event.color),
              ),
              if (hasNext)
                Container(
                  width: 2,
                  height: 48,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: const Color(0xFF292C33),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 330;
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _date(event.date),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _date(event.date),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),
                if (event.occurrence != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ocorrência registrada durante o teste',
                    style: TextStyle(
                      fontSize: 9,
                      color: event.color.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiles() {
    return _section(
      title: 'Arquivos deste teste',
      icon: Icons.folder_rounded,
      child: _attachments.isEmpty
          ? _muted('Nenhum arquivo vinculado a este teste.')
          : Column(
              children: _attachments.map<Widget>((attachment) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: Color(0xFF7AA7FF),
                  ),
                  title: Text(
                    attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${AttachmentService.formatSize(attachment.sizeBytes)} • ${_date(attachment.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Abrir arquivo',
                    onPressed: () => _openAttachment(attachment),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildObservations() {
    return _section(
      title: 'Observações do teste',
      icon: Icons.notes_rounded,
      child: Text(
        widget.test.observacoes!,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _section({required String title, required IconData icon, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: const Color(0xFFE31B23)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _muted(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.50),
        fontSize: 12,
      ),
    );
  }

  Widget _buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: Color(0xFFE31B23)),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEvent {
  final DateTime date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Occurrence? occurrence;

  const _TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.occurrence,
  });
}
