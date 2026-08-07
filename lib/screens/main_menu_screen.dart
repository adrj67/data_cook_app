import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import 'sepa_processor/home_screen.dart';
import 'recipes/recipe_list_screen.dart';
import 'products/product_search_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas
  final List<Widget> _screens = const [
    HomeScreen(),          // Procesador SEPA
    RecipeListScreen(),    // Mis Recetas
    ProductSearchScreen(), // Buscar Productos
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: 'Procesar SEPA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Mis Recetas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Productos',
          ),
        ],
      ),
    );
  }
}