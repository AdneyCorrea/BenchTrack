import 'package:flutter/material.dart';

import '../models/test_session.dart';
import '../models/workstation.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onNewWorkstation;
  final List<Workstation> workstations;
  final List<TestSession> activeTests;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    required this.onNewWorkstation,
    required this.workstations,
    required this.activeTests,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 30, vertical: isMobile ? 18 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcome(isMobile),
              const SizedBox(height: 24),
              _buildStats(isMobile),
              const SizedBox(height: 28),
              _buildMainSection(context, isMobile),
              const SizedBox(height: 28),
              _buildBottomSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcome(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF231417), Color(0xFF17191E)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF322328)),
      ),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildWelcomeText(), const SizedBox(height: 20), _buildNewWorkstationButton()])
          : Row(children: [Expanded(child: _buildWelcomeText()), _buildNewWorkstationButton()]),
    );
  }

  Widget _buildWelcomeText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Olá, Técnico 👋', style: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text('Central de Workstations', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8)),
        SizedBox(height: 8),
        Text('Acompanhe suas máquinas, testes e ocorrências em um só lugar.', style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.5)),
      ],
    );
  }

  Widget _buildNewWorkstationButton() {
    return FilledButton.icon(
      onPressed: onNewWorkstation,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Nova Workstation'),
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31B23), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildStats(bool isMobile) {
    final assembly = workstations.where((w) {
      final status = w.status.trim().toLowerCase();
      return status == 'montagem' || status == 'em montagem';
    }).length;

    final testing = activeTests.length;

    final approved = workstations.where((w) {
      final status = w.status.trim().toLowerCase();
      return status == 'aprovada' || status == 'aprovado';
    }).length;

    final failed = workstations.where((w) {
      final status = w.status.trim().toLowerCase();
      return status == 'reprovada' || status == 'reprovado';
    }).length;

    final cards = [
      _StatData(title: 'Em montagem', value: '$assembly', subtitle: 'Workstations', icon: Icons.build_rounded),
      _StatData(title: 'Em teste', value: '$testing', subtitle: 'Testes ativos', icon: Icons.timer_rounded),
      _StatData(title: 'Aprovadas', value: '$approved', subtitle: 'Workstations', icon: Icons.check_circle_rounded),
      _StatData(title: 'Reprovadas', value: '$failed', subtitle: 'Workstations', icon: Icons.error_rounded),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map((data) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _StatCard(data: data),
                ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) => _StatCard(data: cards[index]),
    );
  }

  Widget _buildMainSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildActiveTests(),
          const SizedBox(height: 18),
          _buildQuickActions(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildActiveTests()),
        const SizedBox(width: 18),
        Expanded(child: _buildQuickActions()),
      ],
    );
  }

  Widget _buildActiveTests() {
    if (activeTests.isEmpty) {
      return _SectionCard(
        title: 'Testes em andamento',
        actionText: 'Ver todos',
        onAction: () => onNavigate(2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF36C275), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhum teste de 48h em andamento.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visible = activeTests.take(3).toList();

    return _SectionCard(
      title: 'Testes em andamento',
      actionText: 'Ver todos',
      onAction: () => onNavigate(2),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            _buildActiveTestRow(visible[i]),
            if (i < visible.length - 1) const Divider(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTestRow(TestSession test) {
    Workstation? workstation;
    for (final item in workstations) {
      if (item.id == test.workstationId) {
        workstation = item;
        break;
      }
    }

    final elapsed = DateTime.now().difference(test.startedAt);
    final progress = (elapsed.inSeconds / (48 * 60 * 60)).clamp(0.0, 1.0).toDouble();
    final remaining = Duration(seconds: ((48 * 60 * 60) - elapsed.inSeconds).clamp(0, 48 * 60 * 60));
    final remainingText = '${remaining.inHours.toString().padLeft(2, '0')}h ${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}min';

    final code = workstation?.codigo ?? 'Workstation removida';
    final processor = workstation?.processador.trim().isNotEmpty == true
        ? workstation!.processador
        : 'Configuração não informada';
    final gpu = workstation?.placaVideo.trim().isNotEmpty == true
        ? workstation!.placaVideo
        : '';

    return _TestRow(
      workstation: code,
      component: gpu.isEmpty ? processor : '$processor + $gpu',
      progress: progress,
      remaining: progress >= 1 ? 'Concluído' : remainingText,
    );
  }

  Widget _buildQuickActions() {
    return _SectionCard(
      title: 'Ações rápidas',
      child: Column(
        children: [
          _ActionTile(icon: Icons.add_circle_outline_rounded, title: 'Cadastrar Workstation', subtitle: 'Adicionar uma nova máquina', onTap: onNewWorkstation),
          const SizedBox(height: 10),
          _ActionTile(icon: Icons.search_rounded, title: 'Pesquisar Workstation', subtitle: 'Encontrar uma máquina', onTap: () => onNavigate(1)),
          const SizedBox(height: 10),
          _ActionTile(icon: Icons.upload_file_rounded, title: 'Enviar arquivo', subtitle: 'Adicionar fotos ou documentos', onTap: () => onNavigate(3)),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final recent = workstations.take(5).toList();

    return _SectionCard(
      title: 'Workstations recentes',
      actionText: 'Ver todas',
      onAction: () => onNavigate(1),
      child: recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhuma Workstation cadastrada.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  _RecentWorkstationRow(
                    code: recent[i].codigo,
                    processor: recent[i].processador,
                    gpu: recent[i].placaVideo,
                    status: recent[i].status,
                    statusType: _statusType(recent[i].status),
                  ),
                  if (i < recent.length - 1) const Divider(height: 24),
                ],
              ],
            ),
    );
  }

  _StatusType _statusType(String status) {
    switch (status.trim().toLowerCase()) {
      case 'teste 48h':
      case 'em teste':
        return _StatusType.testing;
      case 'aprovada':
      case 'aprovado':
        return _StatusType.approved;
      case 'reprovada':
      case 'reprovado':
        return _StatusType.failed;
      default:
        return _StatusType.assembly;
    }
  }
}

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  const _StatData({required this.title, required this.value, required this.subtitle, required this.icon});
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF2B2022), borderRadius: BorderRadius.circular(13)), child: Icon(data.icon, color: const Color(0xFFE31B23), size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.title, style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 12)),
              const SizedBox(height: 4),
              Text(data.value, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 1),
              Text(data.subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 11)),
            ])),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget child;
  const _SectionCard({required this.title, required this.child, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)), const Spacer(), if (actionText != null) TextButton(onPressed: onAction, child: Text(actionText!, style: const TextStyle(color: Color(0xFFE31B23))))]),
          const SizedBox(height: 18),
          child,
        ]),
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final String workstation;
  final String component;
  final double progress;
  final String remaining;
  const _TestRow({required this.workstation, required this.component, required this.progress, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFF2B2022), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.computer_rounded, size: 20, color: Color(0xFFE31B23))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(workstation, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(component, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54)))])),
        Text(remaining, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.54))),
      ]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: const Color(0xFF292C33), color: const Color(0xFFE31B23))),
      const SizedBox(height: 6),
      Text('${(progress * 100).round()}% concluído', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
    ]);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1F25),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF2B2022), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: const Color(0xFFE31B23), size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)), const SizedBox(height: 3), Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11))])),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ]),
        ),
      ),
    );
  }
}

enum _StatusType { testing, approved, failed, assembly }

class _RecentWorkstationRow extends StatelessWidget {
  final String code;
  final String processor;
  final String gpu;
  final String status;
  final _StatusType statusType;
  const _RecentWorkstationRow({required this.code, required this.processor, required this.gpu, required this.status, required this.statusType});

  Color get statusColor {
    switch (statusType) {
      case _StatusType.testing: return const Color(0xFFFFB020);
      case _StatusType.approved: return const Color(0xFF36C275);
      case _StatusType.failed: return const Color(0xFFE31B23);
      case _StatusType.assembly: return const Color(0xFF7AA7FF);
    }
  }

  IconData get statusIcon {
    switch (statusType) {
      case _StatusType.testing: return Icons.timer_rounded;
      case _StatusType.approved: return Icons.check_circle_rounded;
      case _StatusType.failed: return Icons.cancel_rounded;
      case _StatusType.assembly: return Icons.build_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF20232A), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.computer_rounded, color: Colors.white70)),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 3), Text(processor, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)))])),
      Expanded(child: Text(gpu, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.54)))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(statusIcon, size: 14, color: statusColor), const SizedBox(width: 5), Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11))])),
    ]);
  }
}
