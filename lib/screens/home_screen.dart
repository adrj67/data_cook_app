import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/python_service.dart';
import '../widgets/progress_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // No necesitamos variables de estado adicionales por ahora

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Seleccionar archivo SEPA',
      );

      // Verificar si el widget sigue montado
      if (!mounted) return;

      if (result != null) {
        final filePath = result.files.single.path!;
        final appState = Provider.of<AppState>(context, listen: false);
        appState.setFilePath(filePath);
        await _processFile(filePath);
      }
    } catch (e) {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addLogMessage('❌ Error al seleccionar archivo: $e');
    }
  }

  Future<void> _processFile(String filePath) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final pythonService = PythonService();

    try {
      appState.startProcessing();
      
      // Verificar mounted antes de cada operación que use el contexto
      if (!mounted) return;
      appState.addLogMessage('📁 Archivo seleccionado: ${filePath.split(Platform.pathSeparator).last}');
      
      if (!mounted) return;
      appState.addLogMessage('🐍 Iniciando proceso Python...');

      final process = await pythonService.runPythonScript(filePath);
      
      bool success = true;
      String errorMessage = '';
      
      // Los streams no necesitan mounted check directamente
      pythonService.getProcessOutput(process).listen((data) {
        // Verificar mounted dentro del stream
        if (!mounted) return;
        appState.addLogMessage('📤 $data');
        if (data.contains('Progreso:')) {
          try {
            final percent = double.parse(data.split(':')[1].trim().replaceAll('%', ''));
            appState.updateProgress(percent / 100, data);
          } catch (e) {
            // Ignorar si no se puede parsear
          }
        }
      });

      pythonService.getProcessError(process).listen((data) {
        if (!mounted) return;
        appState.addLogMessage('⚠️ Error: $data');
        success = false;
        errorMessage = data;
      });

      final exitCode = await pythonService.waitForProcess(process);
      
      // Verificar mounted antes de usar el contexto
      if (!mounted) return;
      
      if (exitCode == 0 && success) {
        appState.updateProgress(1.0, '✅ Proceso completado exitosamente');
        appState.addLogMessage('✅ Base de datos actualizada correctamente');
        appState.finishProcessing(true);
      } else {
        if (exitCode != 0) {
          appState.addLogMessage('❌ Error: El proceso terminó con código $exitCode');
        }
        if (!success && errorMessage.isNotEmpty) {
          appState.addLogMessage('❌ Error en proceso: $errorMessage');
        }
        appState.finishProcessing(false);
      }
    } catch (e) {
      if (!mounted) return;
      appState.addLogMessage('❌ Error: $e');
      appState.finishProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DataCook - Procesador SEPA'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: appState.isProcessing ? null : _selectFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Seleccionar archivo SEPA'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (appState.selectedFilePath.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_copy, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appState.selectedFilePath.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                ProgressWidget(
                  isProcessing: appState.isProcessing,
                  progress: appState.progress,
                  statusMessage: appState.statusMessage,
                ),
                
                const SizedBox(height: 16),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  appState.clearLogMessages();
                                },
                                tooltip: 'Limpiar log',
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            reverse: true,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: appState.logMessages.map((msg) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      msg,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}