import 'package:flutter/material.dart';
import 'CommandePage.dart';
import 'SalleListPage.dart';
import 'matiereView.dart';
import 'StockView.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text('Statistique en développement')), // Placeholder
    Center(child: Text('Planification en développement')), // Placeholder
    Center(child: Text('Utilisateurs en développement')), // Placeholder
    StockView(),
    CommandePage(),
    SalleListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.stacked_line_chart),
            label: 'Statistique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Planification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room),
            label: 'Salles',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
