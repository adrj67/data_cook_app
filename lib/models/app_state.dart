import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  bool isProcessing = false;
  String selectedFilePath = '';
  List<String> logMessages = [];
  double progress = 0.0;
  String statusMessage = 'Esperando archivo...';

  void startProcessing() {
    isProcessing = true;
    logMessages.clear();
    progress = 0.0;
    statusMessage = 'Procesando... ( Este proceso puede tardar varios minutos. )';
    notifyListeners();
  }

  void updateProgress(double value, String message) {
    progress = value;
    statusMessage = message;
    notifyListeners();
  }

  void addLogMessage(String message) {
    logMessages.add(message);
    notifyListeners();
  }

  void finishProcessing(bool success) {
    isProcessing = false;
    statusMessage = success ? '¡Proceso completado!' : 'Error en el proceso';
    notifyListeners();
  }

  void setFilePath(String path) {
    selectedFilePath = path;
    notifyListeners();
  }

  // Limpiar los mensajes del log
  void clearLogMessages() {
    logMessages.clear();
    notifyListeners();
  }
}