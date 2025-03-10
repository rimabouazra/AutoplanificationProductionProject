import 'package:flutter/material.dart';
import '../views/ListeProduitsPage.dart'; // Assure-toi d'importer ta page de produits.

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;

  TopNavbar({Key? key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Gestion des Ressources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      centerTitle: true,
      backgroundColor: Colors.transparent,  // Pour faire apparaître le fond de dégradé.
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.blue.shade300],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.list_alt, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProduitsPage()),  // Redirige vers ListProduitsPage.
            );
          },
        ),
      ],
    );
  }
}
