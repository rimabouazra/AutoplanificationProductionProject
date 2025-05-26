import 'package:flutter/material.dart';
import 'package:frontend/views/StatistiquesView.dart';
import 'CommandePage.dart';
import 'SalleListPage.dart';
import 'StockView.dart';
import 'PlanificationView.dart';
import 'UsersView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    Navigator.pushReplacementNamed(context, '/login'); 
  }
  List<Widget> _buildPages(String? role) {
    List<Widget> pages = [
      PlanificationView(), // Première page par défaut
      StatistiquesView(),
    ];

    if (role == 'admin') {
      pages.addAll([
        UsersView(),
        StockView(),
        CommandePage(),
        SalleListPage(),
      ]);
    } else if (role == 'manager') {
      pages.addAll([
        StockView(),
        CommandePage(),
        SalleListPage(),
      ]);
    } else if (role == 'responsable_modele') {
      pages.addAll([
        StockView(),
        SalleListPage(),
      ]);
    } else if (role == 'responsable_matiere') {
      pages.add(StockView());
    }

    return pages;
  }

  List<BottomNavigationBarItem> _buildNavItems(String? role) {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.schedule), 
        label: 'Planification'
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart), 
        label: 'Statistiques'
      ),
    ];

    if (role == 'admin') {
      items.addAll([
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Utilisateurs'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Salles'),
      ]);
    } else if (role == 'manager') {
      items.addAll([
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Commandes'),
        BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Salles'),
      ]);
    } else if (role == 'responsable_modele') {
      items.addAll([
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'),
        BottomNavigationBarItem(icon: Icon(Icons.meeting_room), label: 'Salles'),
      ]);
    } else if (role == 'responsable_matiere') {
      items.add(BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Stock'));
    }

    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final role = snapshot.data!;
        final pages = _buildPages(role);
        final navItems = _buildNavItems(role);

        // Ensure selected index is within bounds
        final safeIndex = _selectedIndex < pages.length ? _selectedIndex : 0;

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: safeIndex,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}