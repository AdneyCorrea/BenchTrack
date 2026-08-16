import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../models/workstation.dart';
import '../services/attachment_service.dart';
import '../services/delete_service.dart';

class ArquivosScreen extends StatefulWidget {
  final List<Workstation> workstations;

  const ArquivosScreen({super.key, required this.workstations});

  @override
  State<ArquivosScreen> createState() => _ArquivosScreenState();
}

class _ArquivosScreenState extends State<ArquivosScreen> {
  late final AttachmentService _service;
  List<Attachment> _items = const [];
  bool _loading = true;
  bool _uploading = false;
  String _search = '';
  String _workstationFilter = 'Todas';

  @override
  void initState() {
    super.initState();
    _service = AttachmentService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.getAll();
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _error('Não foi possível carregar os arquivos.');
    }
  }

  List<Attachment> get _filtered {
    final q = _search.trim().toLowerCase();
    return _items.where((a) {
      final ws = widget.workstations.cast<Workstation?>().firstWhere(
        (w) => w?.id == a.workstationId,
        orElse: () => null,
      );
      final wsName = ws?.codigo ?? 'Workstation removida';
      final matchesSearch = q.isEmpty ||
          a.fileName.toLowerCase().contains(q) ||
          wsName.toLowerCase().contains(q);
      final matchesWs = _workstationFilter == 'Todas' ||
          a.workstationId == _workstationFilter;
      return matchesSearch && matchesWs;
    }).toList();
  }

  Workstation? _workstation(String id) {
    for (final w in widget.workstations) {
      if (w.id == id) return w;
    }
    return null;
  }

  Future<void> _upload() async {
    if (widget.workstations.isEmpty) {
      _error('Cadastre uma Workstation antes de enviar arquivos.');
      return;
    }

    String selected = widget.workstations.first.id;

    final chosen = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            final screenWidth = MediaQuery.sizeOf(dialogContext).width;
            final availableWidth = screenWidth - 32;
            final dialogWidth = availableWidth.clamp(0.0, 430.0).toDouble();

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height - 48,
                ),
                child: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Enviar arquivo',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fechar',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selected,
                          decoration: const InputDecoration(
                            labelText: 'Workstation',
                            prefixIcon: Icon(Icons.computer_rounded),
                          ),
                          items: widget.workstations.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Text(
                                w.codigo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setLocal(() => selected = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(
                            dialogContext,
                            selected,
                          ),
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Escolher arquivo'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (chosen == null) return;

    setState(() => _uploading = true);
    try {
      final item = await _service.pickAndUploadForWorkstation(
        workstationId: chosen,
      );
      if (!mounted) return;
      if (item != null) {
        setState(() => _items = [item, ..._items]);
        _message('Arquivo enviado com sucesso.');
      }
    } catch (_) {
      if (mounted) _error('Não foi possível enviar o arquivo.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _open(Attachment item) async {
    try {
      final url = await _service.createSignedUrl(item.storagePath);
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) _error('Não foi possível abrir o arquivo.');
    } catch (_) {
      if (mounted) _error('Não foi possível abrir o arquivo.');
    }
  }

  Future<void> _delete(Attachment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir arquivo'),
        content: Text(
          'Você tem certeza que deseja excluir "${item.fileName}"?\n\n'
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE31B23)),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DeleteService(Supabase.instance.client).deleteAttachment(
        attachmentId: item.id,
        storagePath: item.storagePath,
      );
      if (!mounted) return;
      setState(() => _items = _items.where((x) => x.id != item.id).toList());
      _message('Arquivo excluído com sucesso.');
    } catch (_) {
      if (mounted) _error('Não foi possível excluir o arquivo.');
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  void _error(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final list = _filtered;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 18 : 30, vertical: 24),
      child: Column(
        children: [
          if (mobile) ...[
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Pesquisar arquivos...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _filterDropdown()),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _uploading ? null : _upload,
                child: _uploading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_rounded),
              ),
            ]),
          ] else
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Pesquisar por nome ou Workstation...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: _filterDropdown()),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file_rounded),
                label: const Text('Enviar arquivo'),
              ),
            ]),
          const SizedBox(height: 20),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? _empty()
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _card(list[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown() => DropdownButtonFormField<String>(
    value: _workstationFilter,
    decoration: const InputDecoration(labelText: 'Workstation'),
    items: [
      const DropdownMenuItem(value: 'Todas', child: Text('Todas')),
      ...widget.workstations.map((w) => DropdownMenuItem(value: w.id, child: Text(w.codigo))),
    ],
    onChanged: (v) => setState(() => _workstationFilter = v ?? 'Todas'),
  );

  Widget _card(Attachment item) {
    final ws = _workstation(item.workstationId);
    final name = ws?.codigo ?? 'Workstation removida';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2022),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFFE31B23)),
        ),
        title: Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$name  •  ${AttachmentService.formatSize(item.sizeBytes)}'),
        trailing: Wrap(spacing: 2, children: [
          IconButton(tooltip: 'Abrir', onPressed: () => _open(item), icon: const Icon(Icons.open_in_new_rounded)),
          IconButton(tooltip: 'Excluir', onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline_rounded)),
        ]),
        onTap: () => _open(item),
      ),
    );
  }

  Widget _empty() => Center(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.folder_open_rounded, size: 56, color: Color(0xFFE31B23)),
          const SizedBox(height: 16),
          const Text('Nenhum arquivo encontrado', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Envie documentos, fotos, logs e relatórios para uma Workstation.', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55))),
        ]),
      ),
    ),
  );
}
