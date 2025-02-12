import 'package:flutter/material.dart';
import 'package:frontend/views/CommandePage.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  void navigateTo(BuildContext context, String pageName) {
    Widget page;
    switch (pageName) {
      case 'Commandes':
        page = const CommandePage(); // Redirection vers la page Commandes
        break;
      default:
        page = Scaffold(
          appBar: AppBar(title: Text(pageName)),
          body: Center(child: Text('Page de $pageName en cours de développement')),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home Page'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            buildMenuItem(context, 'assets/icons/dashboard.png', 'Tableau de bord'),
            buildMenuItem(context, 'assets/icons/planning.png', 'Planification'),
            buildMenuItem(context, 'assets/icons/users.png', 'Utilisateurs'),
            buildMenuItem(context, 'assets/icons/stock.png', 'Stock'),
            buildMenuItem(context, 'assets/icons/orders.png', 'Commandes'),
            buildMenuItem(context, 'assets/icons/rooms.png', 'Salles'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.logout),
        tooltip: 'Se déconnecter',
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, String iconPath, String title) {
    return GestureDetector(
      onTap: () => navigateTo(context, title),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, width: 50, height: 50),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
