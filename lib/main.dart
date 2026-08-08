import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_state.dart';
import 'screens/main_menu_screen.dart';
import 'database/database_helper.dart';

void main() {
  // Inicializar el database helper antes de ejecutar la app
  DatabaseHelper.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataCook - Recetas y Costos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}