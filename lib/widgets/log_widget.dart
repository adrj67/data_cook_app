import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogWidget extends StatefulWidget {
  final List<String> messages;
  final VoidCallback onClear;
  final bool isProcessing;

  const LogWidget({
    super.key,
    required this.messages,
    required this.onClear,
    required this.isProcessing,
  });

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void didUpdateWidget(LogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length && _autoScroll) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de herramientas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Log de proceso',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.messages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.messages.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _autoScroll = !_autoScroll;
                    });
                    if (_autoScroll) {
                      _scrollToBottom();
                    }
                  },
                  tooltip: _autoScroll ? 'Auto-scroll activado' : 'Auto-scroll desactivado',
                  color: _autoScroll ? Colors.blue : Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: widget.messages.isEmpty ? null : () => _copyLog(context),
                  tooltip: 'Copiar todo el log',
                  color: widget.messages.isEmpty ? Colors.grey : null,
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt, size: 20),
                  onPressed: widget.messages.isEmpty ? null : () => _saveLogToFile(context),
                  tooltip: 'Guardar log como archivo',
                  color: widget.messages.isEmpty ? Colors.grey : null,
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: widget.isProcessing ? null : widget.onClear,
                  tooltip: 'Limpiar log',
                  color: widget.isProcessing ? Colors.grey : null,
                ),
              ],
            ),
          ),
          // Área del log
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade400,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay mensajes en el log. El proceso puede tardar hasta 3 minutos.',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      if (_autoScroll) {
                        setState(() {
                          _autoScroll = false;
                        });
                      }
                    },
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: widget.messages.length,
                        itemBuilder: (context, index) {
                          final message = widget.messages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: SelectableText(
                              message,
                              style: _getTextStyleForMessage(message),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  TextStyle _getTextStyleForMessage(String message) {
    if (message.contains('❌') || message.contains('Error') || message.contains('⚠️')) {
      return const TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontFamily: 'monospace',
      );
    } else if (message.contains('✅') || message.contains('completado') || message.contains('exitosa')) {
      return const TextStyle(
        color: Colors.green,
        fontSize: 12,
        fontFamily: 'monospace',
      );
    } else if (message.contains('Progreso:')) {
      return const TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
      );
    } else {
      return const TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
      );
    }
  }

  void _copyLog(BuildContext context) {
    if (widget.messages.isEmpty) return;

    final logText = widget.messages.join('\n');
    Clipboard.setData(ClipboardData(text: logText)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('✅ Log copiado al portapapeles'),
              ],
            ),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al copiar: $error'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _saveLogToFile(BuildContext context) async {
    if (widget.messages.isEmpty) return;

    try {
      final logText = widget.messages.join('\n');
      final timestamp = DateTime.now().toString().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'log_data_cook_$timestamp.txt';
      
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }
      
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(logText);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.save, color: Colors.green),
                const SizedBox(width: 8),
                Text('✅ Log guardado en: Downloads/$fileName'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}