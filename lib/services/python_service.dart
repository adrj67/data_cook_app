import 'dart:io';
import 'package:path/path.dart' as path;

class PythonService {
  // Ruta al script Python
  final String pythonScriptPath;
  
  PythonService() : pythonScriptPath = _getPythonScriptPath();

  static String _getPythonScriptPath() {
    // Asume que el script está en ../DataCook/python/main.py
    final currentDir = Directory.current.path;
    return path.join(currentDir, '..', 'DataCook', 'python', 'main.py');
  }

  Future<Process> runPythonScript(String zipFilePath) async {
    // Verificar que el script existe
    final scriptFile = File(pythonScriptPath);
    if (!await scriptFile.exists()) {
      throw Exception('No se encontró el script Python en: $pythonScriptPath');
    }

    // Verificar que el archivo zip existe
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) {
      throw Exception('No se encontró el archivo ZIP: $zipFilePath');
    }

    // Ejecutar Python con el script y el path del zip
    return await Process.start(
      'python',  // o 'python3' en Linux/Mac
      [pythonScriptPath, zipFilePath],
      workingDirectory: path.dirname(pythonScriptPath),
    );
  }

  Stream<String> getProcessOutput(Process process) async* {
    // Leer stdout en tiempo real
    await for (var data in process.stdout) {
      yield String.fromCharCodes(data);
    }
  }

  Stream<String> getProcessError(Process process) async* {
    // Leer stderr en tiempo real
    await for (var data in process.stderr) {
      yield String.fromCharCodes(data);
    }
  }

  Future<int> waitForProcess(Process process) async {
    return await process.exitCode;
  }
}