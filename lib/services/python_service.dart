import 'dart:io';
import 'package:path/path.dart' as path;

class PythonService {
  // Ruta al script Python
  final String pythonScriptPath;
  
  PythonService() : pythonScriptPath = _getPythonScriptPath();

  static String _getPythonScriptPath() {
    // Obtener el directorio actual (debería ser data_cook_app/)
    final currentDir = Directory.current.path;
    
    // Subir un nivel a App_DataCook/ y luego ir a DataCook/python/main.py
    final scriptPath = path.join(currentDir, '..', 'DataCook', 'python', 'main.py');
    return path.normalize(scriptPath);
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

    // Obtener el directorio de trabajo (DataCook/python/)
    final workingDir = path.dirname(pythonScriptPath);

    // Ejecutar Python con el script y el path del zip
    return await Process.start(
      'python',  // o 'python3' en Linux/Mac
      [pythonScriptPath, zipFilePath],
      workingDirectory: workingDir,
      environment: {
        'PYTHONIOENCODING': 'utf-8',  // Forzar codificación UTF-8
        'PYTHONUTF8': '1',            // Habilitar UTF-8 en Python 3.7+
      },
    );
  }

  Stream<String> getProcessOutput(Process process) async* {
    // Leer stdout en tiempo real
    await for (var data in process.stdout) {
      try {
        yield String.fromCharCodes(data);
      } catch (e) {
        // Si hay error de codificación, intentar con UTF-8
        try {
          yield String.fromCharCodes(data, 0, data.length);
        } catch (e2) {
          yield '[Error de codificación]';
        }
      }
    }
  }

  Stream<String> getProcessError(Process process) async* {
    // Leer stderr en tiempo real
    await for (var data in process.stderr) {
      try {
        yield String.fromCharCodes(data);
      } catch (e) {
        try {
          yield String.fromCharCodes(data, 0, data.length);
        } catch (e2) {
          yield '[Error de codificación]';
        }
      }
    }
  }

  Future<int> waitForProcess(Process process) async {
    return await process.exitCode;
  }
}