import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/test_session.dart';
import 'models/workstation.dart';
import 'screens/dashboard_screen.dart';
import 'screens/arquivos_screen.dart';
import 'screens/login_screen.dart';
import 'screens/testes_48h_screen.dart';
import 'screens/workstation_form_screen.dart';
import 'screens/workstation_detail_screen.dart';
import 'screens/workstations_screen.dart';
import 'services/supabase_config.dart';
import 'services/test_service.dart';
import 'services/workstation_service.dart';
import 'services/delete_service.dart';

class BenchTrackApp extends StatelessWidget {
  const BenchTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BenchTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE31B23),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF181B21),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF181B21),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  Session? _session;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _session = Supabase.instance.client.auth.currentSession;

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) {
        return;
      }

      setState(() {
        _session = data.session;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return LoginScreen(
        onLoggedIn: () {
          setState(() {
            _session = Supabase.instance.client.auth.currentSession;
          });
        },
      );
    }

    return BenchTrackShell(session: _session!);
  }
}

class BenchTrackShell extends StatefulWidget {
  final Session session;

  const BenchTrackShell({
    super.key,
    required this.session,
  });

  @override
  State<BenchTrackShell> createState() => _BenchTrackShellState();
}

class _BenchTrackShellState extends State<BenchTrackShell> {
  int _selectedIndex = 0;

  final List<Workstation> _workstations = [];

  late final WorkstationService _workstationService;
  late final TestService _testService;

  final List<TestSession> _activeTests = [];
  bool _loadingTests = true;
  String? _testLoadError;

  bool _loadingWorkstations = true;
  String? _loadError;

  final List<String> _titles = const [
    'Dashboard',
    'Workstations',
    'Testes 48h',
    'Arquivos',
  ];

  @override
  void initState() {
    super.initState();
    _workstationService = WorkstationService(
      Supabase.instance.client,
    );
    _testService = TestService(Supabase.instance.client);
    _loadWorkstations();
    _loadTests();
  }

  Future<void> _loadWorkstations() async {
    setState(() {
      _loadingWorkstations = true;
      _loadError = null;
    });

    try {
      final items = await _workstationService.getWorkstations();

      if (!mounted) {
        return;
      }

      setState(() {
        _workstations
          ..clear()
          ..addAll(items);
        _loadingWorkstations = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingWorkstations = false;
        _loadError = 'Erro do Supabase: ${error.message}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingWorkstations = false;
        _loadError = 'Não foi possível carregar as Workstations.';
      });
    }
  }

  Future<void> _refreshBenchTrackData() async {
    await Future.wait([
      _loadWorkstations(),
      _loadTests(),
    ]);
  }

  Future<void> _loadTests() async {
    setState(() {
      _loadingTests = true;
      _testLoadError = null;
    });

    try {
      final items = await _testService.getActiveTests();

      if (!mounted) {
        return;
      }

      setState(() {
        _activeTests
          ..clear()
          ..addAll(items);
        _loadingTests = false;
      });
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTests = false;
        _testLoadError = 'Erro do Supabase: ${error.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTests = false;
        _testLoadError = 'Não foi possível carregar os testes.';
      });
    }
  }

  Future<void> _startTest(Workstation workstation) async {
    if (_activeTests.any((test) => test.workstationId == workstation.id)) {
      setState(() => _selectedIndex = 2);
      return;
    }

    try {
      final test = await _testService.startTest(workstation.id);

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
        status: 'Teste 48h',
      );

      final savedWorkstation = await _workstationService.updateWorkstation(updated);
      final index = _workstations.indexWhere((item) => item.id == savedWorkstation.id);

      if (!mounted) return;
      setState(() {
        if (index != -1) {
          _workstations[index] = savedWorkstation;
        }
        _activeTests.add(test);
        _selectedIndex = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teste de 48 horas iniciado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível iniciar o teste: ${error.message}');
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível iniciar o teste de 48 horas.');
    }
  }

  Future<void> _createWorkstation() async {
    final result = await Navigator.push<Workstation>(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkstationFormScreen(),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final saved = await _workstationService.createWorkstation(result);

      if (!mounted) {
        return;
      }

      setState(() {
        _workstations.insert(0, saved);
        _selectedIndex = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workstation salva com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível salvar: ${error.message}');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível salvar a Workstation.');
    }
  }

  Future<void> _editWorkstation(Workstation workstation) async {
    final result = await Navigator.push<Workstation>(
      context,
      MaterialPageRoute(
        builder: (_) => WorkstationFormScreen(
          workstation: workstation,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final saved = await _workstationService.updateWorkstation(result);

      if (!mounted) {
        return;
      }

      final index = _workstations.indexWhere(
        (item) => item.id == saved.id,
      );

      setState(() {
        if (index == -1) {
          _workstations.insert(0, saved);
        } else {
          _workstations[index] = saved;
        }
        _selectedIndex = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workstation atualizada com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível atualizar: ${error.message}');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Não foi possível atualizar a Workstation.');
    }
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


Future<void> _openWorkstationDetails(Workstation workstation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkstationDetailScreen(
          workstation: workstation,
          onEdit: () {
            Navigator.pop(context);
            _editWorkstation(workstation);
          },
          onStartTest: () {
            Navigator.pop(context);
            _startTest(workstation);
          },
        ),
      ),
    );
    if (mounted) {
      await _refreshBenchTrackData();
    }
  }

  Future<void> _deleteWorkstation(Workstation workstation) async {
  try {
    final service = DeleteService(Supabase.instance.client);
    await service.deleteWorkstation(workstation.id);

    if (!mounted) return;

    setState(() {
      _workstations.removeWhere((item) => item.id == workstation.id);
      _activeTests.removeWhere((test) => test.workstationId == workstation.id);
      _selectedIndex = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workstation excluída com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on PostgrestException catch (error) {
    if (!mounted) return;
    _showError('Não foi possível excluir: ${error.message}');
  } catch (error) {
    if (!mounted) return;
    _showError('Não foi possível excluir a Workstation.');
  }
}

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _showComingSoon(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$section será implementado nas próximas etapas.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCurrentPage() {
    if (_selectedIndex == 1 && _loadingWorkstations) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_selectedIndex == 1 && _loadError != null) {
      return _buildLoadError();
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          onNavigate: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          onNewWorkstation: _createWorkstation,
          workstations: _workstations,
          activeTests: _activeTests,
        );

      case 1:
        return WorkstationsScreen(
          workstations: _workstations,
          onNewWorkstation: _createWorkstation,
          onEditWorkstation: _editWorkstation,
          onOpenDetails: _openWorkstationDetails,
          onDeleteWorkstation: _deleteWorkstation,
          onStartTest: _startTest,
          activeTestWorkstationIds: _activeTests.map((test) => test.workstationId).toSet(),
        );

      case 2:
        if (_loadingTests) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_testLoadError != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_testLoadError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loadTests,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        return Testes48hScreen(
          workstations: _workstations,
          onStartTest: _startTest,
          onRefresh: _refreshBenchTrackData,
        );

      case 3:
        return ArquivosScreen(
          workstations: _workstations,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: Color(0xFFE31B23),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Não foi possível carregar as Workstations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _loadError ?? 'Erro desconhecido.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _loadWorkstations,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                _buildDesktopSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(),
                      Expanded(child: _buildCurrentPage()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F1115),
            elevation: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                _buildLogo(compact: true),
                const SizedBox(width: 12),
                Text(
                  _titles[_selectedIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Sair',
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: _buildCurrentPage(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: const Color(0xFF15171C),
            indicatorColor: const Color(0xFF3A1A1D),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.computer_outlined),
                selectedIcon: Icon(Icons.computer_rounded),
                label: 'PCs',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: 'Testes',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'Arquivos',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Color(0xFF14161B),
        border: Border(
          right: BorderSide(color: Color(0xFF24272E)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  _buildLogo(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'BenchTrack',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _sidebarItem(
                    index: 0,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  _sidebarItem(
                    index: 1,
                    icon: Icons.computer_rounded,
                    label: 'Workstations',
                  ),
                  _sidebarItem(
                    index: 2,
                    icon: Icons.timer_rounded,
                    label: 'Testes 48h',
                  ),
                  _sidebarItem(
                    index: 3,
                    icon: Icons.folder_rounded,
                    label: 'Arquivos',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF3A1A1D),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFFE31B23),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.session.user.email ?? 'Usuário',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? const Color(0xFF3A1A1D) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? const Color(0xFFE31B23)
                      : Colors.white60,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1115),
        border: Border(
          bottom: BorderSide(color: Color(0xFF24272E)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Atualizar Workstations',
            onPressed: _loadWorkstations,
            icon: const Icon(Icons.sync_rounded),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nenhuma nova notificação.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFF3A1A1D),
            child: Icon(
              Icons.person_rounded,
              size: 20,
              color: Color(0xFFE31B23),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({bool compact = false}) {
    return Container(
      width: compact ? 34 : 40,
      height: compact ? 34 : 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE31B23),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.memory_rounded,
        color: Colors.white,
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onAction;

  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.description,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1A1D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 38,
                      color: const Color(0xFFE31B23),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.construction_rounded),
                    label: const Text('Em desenvolvimento'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
