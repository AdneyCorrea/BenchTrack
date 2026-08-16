import 'package:flutter/material.dart';

import '../models/workstation.dart';

class WorkstationsScreen extends StatefulWidget {
  final List<Workstation> workstations;
  final VoidCallback onNewWorkstation;
  final ValueChanged<Workstation> onEditWorkstation;
  final ValueChanged<Workstation> onOpenDetails;
  final ValueChanged<Workstation> onDeleteWorkstation;
  final ValueChanged<Workstation> onStartTest;
  final Set<String> activeTestWorkstationIds;

  const WorkstationsScreen({
    super.key,
    required this.workstations,
    required this.onNewWorkstation,
    required this.onEditWorkstation,
    required this.onOpenDetails,
    required this.onDeleteWorkstation,
    required this.onStartTest,
    required this.activeTestWorkstationIds,
  });

  @override
  State<WorkstationsScreen> createState() => _WorkstationsScreenState();
}

class _WorkstationsScreenState extends State<WorkstationsScreen> {
  String search = '';

  List<Workstation> get filtered {
    if (search.trim().isEmpty) return widget.workstations;
    final s = search.toLowerCase();
    return widget.workstations.where((w) =>
        w.codigo.toLowerCase().contains(s) ||
        w.pedido.toLowerCase().contains(s) ||
        w.processador.toLowerCase().contains(s) ||
        w.placaVideo.toLowerCase().contains(s) ||
        w.status.toLowerCase().contains(s)).toList();
  }

  Color statusColor(String s) {
    switch (s) {
      case 'Aprovada': return const Color(0xFF36C275);
      case 'Reprovada': return const Color(0xFFE31B23);
      case 'Teste 48h': return const Color(0xFFFFB020);
      case 'Aguardando teste': return const Color(0xFF7AA7FF);
      default: return Colors.white70;
    }
  }

  IconData statusIcon(String s) {
    switch (s) {
      case 'Aprovada': return Icons.check_circle_rounded;
      case 'Reprovada': return Icons.cancel_rounded;
      case 'Teste 48h': return Icons.timer_rounded;
      case 'Aguardando teste': return Icons.hourglass_top_rounded;
      default: return Icons.build_rounded;
    }
  }

  Future<void> _confirmDelete(Workstation workstation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Workstation'),
        content: Text(
          'Você tem certeza que deseja excluir a Workstation "${workstation.codigo}"?\n\n'
          'Essa ação também removerá os testes, ocorrências e arquivos relacionados a ela.\n\n'
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

    if (confirmed == true) {
      widget.onDeleteWorkstation(workstation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return LayoutBuilder(builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 30, vertical: 24),
        child: Column(children: [
          if (mobile) ...[
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: const InputDecoration(
                hintText: 'Pesquisar workstation...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onNewWorkstation,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova Workstation'),
              ),
            ),
          ] else
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar por código, pedido, processador, GPU ou status...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: widget.onNewWorkstation,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Nova Workstation'),
              ),
            ]),
          const SizedBox(height: 20),
          Expanded(
            child: list.isEmpty
                ? _empty()
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _card(list[i], mobile),
                  ),
          ),
        ]),
      );
    });
  }

  Widget _empty() => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2022),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.computer_rounded,
                    size: 38,
                    color: Color(0xFFE31B23),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Nenhuma Workstation encontrada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  search.isEmpty
                      ? 'Cadastre sua primeira Workstation.'
                      : 'Nenhuma máquina corresponde à pesquisa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _card(Workstation w, bool mobile) {
    final color = statusColor(w.status);
    final testing = widget.activeTestWorkstationIds.contains(w.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onOpenDetails(w),
              child: Padding(
                padding: EdgeInsets.zero,
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(w, color),
                          const SizedBox(height: 16),
                          _details(w),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _header(w, color),
                                const SizedBox(height: 12),
                                _details(w),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Excluir Workstation',
                            onPressed: () => _confirmDelete(w),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white54,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
              ),
            ),
            if (mobile) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onOpenDetails(w),
                      icon: const Icon(Icons.visibility_rounded),
                      label: const Text('Ver detalhes'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Excluir Workstation',
                    onPressed: () => _confirmDelete(w),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    testing ? 'Teste 48h em andamento' : 'Teste de stress de 48 horas',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                testing
                    ? TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.timer_rounded, size: 18),
                        label: const Text('Em teste'),
                      )
                    : FilledButton.icon(
                        onPressed: () => widget.onStartTest(w),
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Iniciar 48h'),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Workstation w, Color color) => Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF2B2022),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.computer_rounded,
              color: Color(0xFFE31B23),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.codigo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  w.responsavel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon(w.status), size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  w.status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _details(Workstation w) => Wrap(
        spacing: 18,
        runSpacing: 8,
        children: [
          _info(Icons.memory_rounded, w.processador),
          _info(Icons.videogame_asset_rounded, w.placaVideo),
          _info(Icons.sd_card_rounded, w.memoriaRam),
          _info(Icons.storage_rounded, w.armazenamento),
        ],
      );

  Widget _info(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white38),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ),
        ],
      );
}
