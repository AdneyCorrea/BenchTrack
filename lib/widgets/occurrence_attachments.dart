import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/attachment.dart';
import '../models/occurrence.dart';
import '../services/attachment_service.dart';
import '../services/delete_service.dart';

class OccurrenceAttachments extends StatefulWidget {
  final Occurrence occurrence;
  final String workstationId;
  final String testId;

  const OccurrenceAttachments({
    super.key,
    required this.occurrence,
    required this.workstationId,
    required this.testId,
  });

  @override
  State<OccurrenceAttachments> createState() =>
      _OccurrenceAttachmentsState();
}

class _OccurrenceAttachmentsState extends State<OccurrenceAttachments> {
  late final AttachmentService _service;
  List<Attachment> _attachments = const [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _service = AttachmentService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _service.getForOccurrence(widget.occurrence.id);
      if (!mounted) return;
      setState(() {
        _attachments = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);

    try {
      final attachment = await _service.pickAndUploadForOccurrence(
        workstationId: widget.workstationId,
        testId: widget.testId,
        occurrenceId: widget.occurrence.id,
      );

      if (!mounted) return;

      if (attachment != null) {
        setState(() {
          _attachments = [attachment, ..._attachments];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arquivo enviado com sucesso.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on StorageException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível enviar o arquivo: ${error.message}');
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível salvar o arquivo: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showError('Não foi possível enviar o arquivo.');
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }


Future<void> _delete(Attachment attachment) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir arquivo'),
      content: Text(
        'Você tem certeza que deseja excluir "${attachment.fileName}"?\n\n'
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
    await DeleteService(Supabase.instance.client).deleteAttachment(
      attachmentId: attachment.id,
      storagePath: attachment.storagePath,
    );

    if (!mounted) return;
    setState(() {
      _attachments = _attachments
          .where((item) => item.id != attachment.id)
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Arquivo excluído com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } on PostgrestException catch (error) {
    if (!mounted) return;
    _showError('Não foi possível excluir o arquivo: ${error.message}');
  } on StorageException catch (error) {
    if (!mounted) return;
    _showError('Não foi possível excluir o arquivo: ${error.message}');
  } catch (_) {
    if (!mounted) return;
    _showError('Não foi possível excluir o arquivo.');
  }
}

  Future<void> _open(Attachment attachment) async {
    try {
      final url = await _service.createSignedUrl(attachment.storagePath);
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showError('Não foi possível abrir o arquivo.');
      }
    } on StorageException catch (error) {
      if (!mounted) return;
      _showError('Não foi possível gerar o acesso ao arquivo: ${error.message}');
    } catch (_) {
      if (!mounted) return;
      _showError('Não foi possível abrir o arquivo.');
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool narrow = constraints.maxWidth < 430;

        final attachmentLabel = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.attach_file_rounded,
              size: 16,
              color: Colors.white54,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _attachments.isEmpty
                    ? 'Nenhum arquivo anexado'
                    : 'Arquivos (${_attachments.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        );

        final uploadButton = TextButton.icon(
          onPressed: _uploading ? null : _upload,
          icon: _uploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_rounded, size: 16),
          label: Text(_uploading ? 'Enviando...' : 'Anexar arquivo'),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (narrow) ...[
              Row(
                children: [
                  Expanded(child: attachmentLabel),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: uploadButton,
                ),
              ),
            ] else
              Row(
                children: [
                  Expanded(child: attachmentLabel),
                  uploadButton,
                ],
              ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 6),
          ..._attachments.map(_buildAttachment),
        ],
      ],
    );
      },
    );
  }

  Widget _buildAttachment(Attachment attachment) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: const Color(0xFF1C1F25),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => _open(attachment),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  size: 18,
                  color: Color(0xFFE31B23),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attachment.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  AttachmentService.formatSize(attachment.sizeBytes),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Excluir arquivo',
                  onPressed: () => _delete(attachment),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
