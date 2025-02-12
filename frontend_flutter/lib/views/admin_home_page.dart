import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  void navigateTo(BuildContext context, String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(pageName)),
          body: Center(child: Text('Page de $pageName en cours de développement')),
        ),
      ),
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
        padding: const EdgeInsets.all(8.0), // Réduction de l'espacement global
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 10, // Réduction de l'espacement vertical
          crossAxisSpacing: 10, // Réduction de l'espacement horizontal
          children: [
            buildMenuItem(context, Icons.show_chart, 'Tableau de bord'),
            buildMenuItem(context, Icons.person, 'Utilisateurs'),
            buildMenuItem(context, Icons.inventory, 'Stock'),
            buildMenuItem(context, Icons.mail, 'Commandes'),
            buildMenuItem(context, Icons.store, 'Salles'),
            buildMenuItem(context, Icons.event, 'Planification'),
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

  Widget buildMenuItem(BuildContext context, IconData icon, String title) {
    return GestureDetector(
      onTap: () => navigateTo(context, title),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40), // Réduction de la taille des icônes
          const SizedBox(height: 4), // Réduction de l'espacement entre l'icône et le texte
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13), // Ajustement de la taille du texte
          ),
        ],
      ),
    );
  }
}
