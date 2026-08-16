import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/occurrence.dart';
import '../models/test_session.dart';
import '../models/workstation.dart';
import '../services/delete_service.dart';
import '../services/occurrence_service.dart';
import '../services/test_service.dart';
import '../services/workstation_service.dart';
import 'test_detail_screen.dart';
import '../widgets/occurrence_attachments.dart';

class Testes48hScreen extends StatefulWidget {
  final List<Workstation> workstations;
  final ValueChanged<Workstation> onStartTest;
  final VoidCallback onRefresh;

  const Testes48hScreen({
    super.key,
    required this.workstations,
    required this.onStartTest,
    required this.onRefresh,
  });

  @override
  State<Testes48hScreen> createState() => _Testes48hScreenState();
}

class _Testes48hScreenState extends State<Testes48hScreen> {
  late final TestService _testService;
  late final WorkstationService _workstationService;
  late final OccurrenceService _occurrenceService;

  List<TestSession> _activeTests = [];
  List<TestSession> _finishedTests = [];
  final Map<String, List<Occurrence>> _occurrences = {};
  final Set<String> _loadingOccurrences = {};

  Timer? _timer;
  bool _loading = true;
  bool _loadingFinished = false;
  bool _dialogOpen = false;
  String? _error;
  int _category = 0;

  static const List<String> _occurrenceTypes = [
    'Travamento',
    'Tela azul',
    'Reinicialização',
    'Temperatura alta',
    'Erro de benchmark',
    'Ruído',
    'Falha de hardware',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _testService = TestService(Supabase.instance.client);
    _workstationService = WorkstationService(Supabase.instance.client);
    _occurrenceService = OccurrenceService(Supabase.instance.client);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAllTests();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _category == 0) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllTests() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final active = await _testService.getActiveTests();
      final finished = await _testService.getFinishedTests();

      if (!mounted) return;

      setState(() {
        _activeTests = active;
        _finishedTests = finished;
        _occurrences.clear();
        _loading = false;
      });

      for (final test in [...active, ...finished]) {
        await _loadOccurrences(test.id);
      }
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar os testes.';
      });
    }
  }

  Future<void> _loadOccurrences(String testId) async {
    if (!mounted) return;

    setState(() => _loadingOccurrences.add(testId));

    try {
      final items = await _occurrenceService.getForTest(testId);
      if (!mounted) return;

      setState(() {
        _occurrences[testId] = items;
        _loadingOccurrences.remove(testId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOccurrences.remove(testId));
    }
  }

  Workstation? _workstationFor(String id) {
    for (final workstation in widget.workstations) {
      if (workstation.id == id) return workstation;
    }
    return null;
  }

  String _duration(TestSession test) {
    final end = test.finishedAt ?? DateTime.now();
    final elapsed = end.difference(test.startedAt);
    final seconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    const maxSeconds = 48 * 60 * 60;
    final clamped = seconds > maxSeconds ? maxSeconds : seconds;
    final h = clamped ~/ 3600;
    final m = (clamped % 3600) ~/ 60;
    final s = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _progress(TestSession test) {
    final end = test.finishedAt ?? DateTime.now();
    final elapsed = end.difference(test.startedAt).inSeconds;
    return (elapsed / (48 * 3600)).clamp(0.0, 1.0);
  }

  String _remaining(TestSession test) {
    final target = test.startedAt.add(const Duration(hours: 48));
    final diff = target.difference(DateTime.now());
    if (diff.isNegative || test.status == 'Finalizado') {
      return 'Teste concluído';
    }
    return '${diff.inHours}h ${(diff.inMinutes % 60).toString().padLeft(2, '0')}min restantes';
  }

  Future<void> _addOccurrence(TestSession test, Workstation workstation) async {
    setState(() => _dialogOpen = true);

    final result = await showDialog<_OccurrenceDialogResult>(
      context: context,
      builder: (_) => const _OccurrenceDialog(),
    );

    if (mounted) {
      setState(() => _dialogOpen = false);
    }

    if (!mounted || result == null) return;

    try {
      final occurrence = await _occurrenceService.create(
        testId: test.id,
        workstationId: workstation.id,
        tipo: result.tipo,
        descricao: result.descricao,
      );

      if (!mounted) return;

      setState(() {
        final list = _occurrences.putIfAbsent(test.id, () => []);
        list.insert(0, occurrence);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência registrada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível registrar: ${error.message}');
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível registrar a ocorrência.');
    }
  }

  Future<void> _deleteOccurrence(
    TestSession test,
    Occurrence occurrence,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ocorrência'),
        content: const Text(
          'Você tem certeza que deseja excluir esta ocorrência?\n\n'
          'Os arquivos anexados a ela também serão excluídos.\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE31B23),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DeleteService(Supabase.instance.client)
          .deleteOccurrence(occurrence.id);

      if (!mounted) return;

      setState(() {
        _occurrences[test.id] = (_occurrences[test.id] ?? [])
            .where((item) => item.id != occurrence.id)
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência excluída com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível excluir: ${error.message}');
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível excluir a ocorrência.');
    }
  }

  Future<void> _finish(TestSession test, Workstation workstation) async {
    String result = 'Aprovada';
    setState(() => _dialogOpen = true);
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Finalizar teste 48h'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Escolha o resultado do teste e, se quiser, registre uma observação.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: result,
                    items: const [
                      DropdownMenuItem(
                        value: 'Aprovada',
                        child: Text('Aprovada'),
                      ),
                      DropdownMenuItem(
                        value: 'Reprovada',
                        child: Text('Reprovada'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => result = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Resultado',
                      prefixIcon: Icon(Icons.flag_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações finais',
                      hintText: 'Ex.: teste concluído sem erros.',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finalizar'),
              ),
            ],
          );
        },
      ),
    );

    if (mounted) {
      setState(() => _dialogOpen = false);
    }

    if (!mounted || confirmed != true) {
      notesController.dispose();
      return;
    }

    try {
      await _testService.finishTest(
        testId: test.id,
        result: result,
        observacoes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      final updated = Workstation(
        id: workstation.id,
        codigo: workstation.codigo,
        pedido: workstation.pedido,
        responsavel: workstation.responsavel,
        processador: workstation.processador,
        placaMae: workstation.placaMae,
        memoriaRam: workstation.memoriaRam,
        placaVideo: workstation.placaVideo,
        armazenamento: workstation.armazenamento,
        fonte: workstation.fonte,
        cooler: workstation.cooler,
        sistemaOperacional: workstation.sistemaOperacional,
        observacoes: workstation.observacoes,
        status: result,
      );

      await _workstationService.updateWorkstation(updated);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teste finalizado: $result.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadAllTests();
      widget.onRefresh();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível finalizar: ${error.message}');
    } finally {
      notesController.dispose();
    }
  }

  Future<void> _deleteFinishedTest(TestSession test, Workstation workstation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir teste finalizado'),
        content: Text(
          'Você tem certeza que deseja excluir o teste finalizado da Workstation '
          '"${workstation.codigo}"?\n\n'
          'As ocorrências e arquivos vinculados a este teste também serão excluídos.\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE31B23),
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DeleteService(Supabase.instance.client).deleteTest(test.id);

      // Ao apagar o único registro finalizado que definia o resultado,
      // a Workstation volta para o estado de aguardando novo teste.
      final reset = Workstation(
        id: workstation.id,
        codigo: workstation.codigo,
        pedido: workstation.pedido,
        responsavel: workstation.responsavel,
        processador: workstation.processador,
        placaMae: workstation.placaMae,
        memoriaRam: workstation.memoriaRam,
        placaVideo: workstation.placaVideo,
        armazenamento: workstation.armazenamento,
        fonte: workstation.fonte,
        cooler: workstation.cooler,
        sistemaOperacional: workstation.sistemaOperacional,
        observacoes: workstation.observacoes,
        status: 'Aguardando teste',
      );
      await _workstationService.updateWorkstation(reset);

      if (!mounted) return;

      setState(() {
        _finishedTests.removeWhere((item) => item.id == test.id);
        _occurrences.remove(test.id);
      });

      widget.onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teste finalizado excluído com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível excluir o teste: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showError('Não foi possível excluir o teste finalizado.');
    }
  }

  String _formatDateTime(DateTime value) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8E2026),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            FilledButton.icon(
              onPressed: _loadAllTests,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final bool activeCategory = _category == 0;
    final tests = activeCategory ? _activeTests : _finishedTests;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
          child: Row(
            children: [
              Expanded(
                child: _CategoryButton(
                  selected: activeCategory,
                  icon: Icons.timer_rounded,
                  label: 'Em andamento',
                  count: _activeTests.length,
                  onTap: () {
                    setState(() => _category = 0);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CategoryButton(
                  selected: !activeCategory,
                  icon: Icons.history_rounded,
                  label: 'Finalizados',
                  count: _finishedTests.length,
                  onTap: () async {
                    setState(() => _category = 1);
                    if (_finishedTests.isEmpty && !_loadingFinished) {
                      setState(() => _loadingFinished = true);
                      try {
                        final finished = await _testService.getFinishedTests();
                        if (!mounted) return;
                        setState(() => _finishedTests = finished);
                      } catch (_) {
                        if (!mounted) return;
                        _showError('Não foi possível carregar os testes finalizados.');
                      } finally {
                        if (mounted) setState(() => _loadingFinished = false);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingFinished && !activeCategory
              ? const Center(child: CircularProgressIndicator())
              : tests.isEmpty
                  ? _buildEmpty(activeCategory)
                  : RefreshIndicator(
                      onRefresh: _loadAllTests,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                        itemCount: tests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildTestCard(tests[index], activeCategory);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmpty(bool active) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2022),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    active ? Icons.timer_rounded : Icons.history_rounded,
                    size: 40,
                    color: const Color(0xFFE31B23),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  active
                      ? 'Nenhum teste em andamento'
                      : 'Nenhum teste finalizado',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  active
                      ? 'Comece um teste de 48 horas pela tela de Workstations.'
                      : 'Os testes concluídos aparecerão aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(TestSession test, bool active) {
    final workstation = _workstationFor(test.workstationId);
    if (workstation == null) return const SizedBox.shrink();

    final progress = _progress(test);
    final occurrences = _occurrences[test.id] ?? const <Occurrence>[];
    final loadingOccurrences = _loadingOccurrences.contains(test.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TestDetailScreen(
                test: test,
                workstation: workstation,
              ),
            ),
          );
        },
        child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2022),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    active ? Icons.timer_rounded : Icons.history_rounded,
                    color: const Color(0xFFE31B23),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workstation.codigo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${workstation.processador} • ${workstation.placaVideo}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!active) _resultBadge(test.result),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFF292C33),
                color: active
                    ? const Color(0xFFE31B23)
                    : (test.result == 'Aprovada'
                        ? const Color(0xFF36C275)
                        : const Color(0xFFE31B23)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${(progress * 100).round()}% concluído',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  active ? _remaining(test) : 'Finalizado em ${_formatDateTime(test.finishedAt ?? test.startedAt)}',
                  style: TextStyle(
                    color: active
                        ? const Color(0xFFFFB020)
                        : Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Início: ${_formatDateTime(test.startedAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40),
                fontSize: 11,
              ),
            ),
            if (!active && test.observacoes != null && test.observacoes!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF14161B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Observações: ${test.observacoes}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: active
                      ? () => _addOccurrence(test, workstation)
                      : null,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: Text(
                    occurrences.isEmpty
                        ? 'Registrar ocorrência'
                        : 'Ocorrências (${occurrences.length})',
                  ),
                ),
                if (active)
                  OutlinedButton.icon(
                    onPressed: () => _finish(test, workstation),
                    icon: const Icon(Icons.flag_rounded),
                    label: const Text('Finalizar teste'),
                  ),
                FilledButton.icon(
                  onPressed: () => _loadOccurrences(test.id),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar'),
                ),
                if (!active)
                  OutlinedButton.icon(
                    onPressed: () => _deleteFinishedTest(test, workstation),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir teste'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (loadingOccurrences)
              const LinearProgressIndicator(minHeight: 2)
            else if (occurrences.isNotEmpty)
              _buildOccurrences(test, occurrences),
          ],
        ),
      ),
      ),
    );
  }

  Widget _resultBadge(String? result) {
    final bool approved = result == 'Aprovada';
    final color = approved
        ? const Color(0xFF36C275)
        : const Color(0xFFE31B23);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            result ?? 'Sem resultado',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrences(TestSession test, List<Occurrence> occurrences) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF292C33)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de ocorrências',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          ...occurrences.map(
            (occurrence) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1A1D),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFE31B23),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                occurrence.tipo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _formatDateTime(occurrence.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.38),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Excluir ocorrência',
                              onPressed: () => _deleteOccurrence(test, occurrence),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          occurrence.descricao,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OccurrenceAttachments(
                          occurrence: occurrence,
                          workstationId: occurrence.workstationId,
                          testId: occurrence.testId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF3A1A1D) : const Color(0xFF181B21),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFFE31B23)
                    : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE31B23)
                      : const Color(0xFF292C33),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccurrenceDialogResult {
  final String tipo;
  final String descricao;

  const _OccurrenceDialogResult({
    required this.tipo,
    required this.descricao,
  });
}

class _OccurrenceDialog extends StatefulWidget {
  const _OccurrenceDialog();

  @override
  State<_OccurrenceDialog> createState() => _OccurrenceDialogState();
}

class _OccurrenceDialogState extends State<_OccurrenceDialog> {
  String _tipo = _Testes48hScreenState._occurrenceTypes.first;
  final TextEditingController _descriptionController =
      TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final descricao = _descriptionController.text.trim();

    if (descricao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva a ocorrência antes de registrar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _OccurrenceDialogResult(
        tipo: _tipo,
        descricao: descricao,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar ocorrência'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                items: _Testes48hScreenState._occurrenceTypes
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _tipo = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo da ocorrência',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva o que aconteceu durante o teste...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 78),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Registrar'),
        ),
      ],
    );
  }
}
