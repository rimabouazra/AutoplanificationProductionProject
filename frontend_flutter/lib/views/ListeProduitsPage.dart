import 'package:flutter/material.dart';
import '../models/produits.dart';
import '../services/api_service.dart';

class ProduitsPage extends StatefulWidget {
  @override
  _ProduitsPageState createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  List<Produit> _produits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProduits();
  }

  Future<void> _fetchProduits() async {
    try {
      final produits = await ApiService.getProduits();
      setState(() {
        _produits = produits;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  // Méthode pour modifier un produit
  void _modifierProduit(Produit produit) {
    TextEditingController tailleController = TextEditingController(text: produit.taille);
    TextEditingController couleurController = TextEditingController(text: produit.couleur);
    TextEditingController quantiteController = TextEditingController(text: produit.quantite.toString());
    String etat = produit.etat;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier Produit"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: etat,
                  items: ['coupé', 'moulé'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      etat = newValue!;
                    });
                  },
                  decoration: InputDecoration(labelText: "État"),
                ),
                TextField(
                  controller: tailleController,
                  decoration: InputDecoration(labelText: "Taille"),
                ),
                TextField(
                  controller: couleurController,
                  decoration: InputDecoration(labelText: "Couleur"),
                ),
                TextField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: "Quantité"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Appeler la méthode updateProduit avec les valeurs modifiées
                await ApiService.updateProduit(
                  produit.id,
                  tailleController.text,
                  couleurController.text,
                  int.parse(quantiteController.text),
                  etat,
                );
                _fetchProduits(); // Rafraîchir la liste des produits
                Navigator.pop(context); // Fermer le dialogue
              },
              child: Text("Modifier"),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour supprimer un produit
  void _supprimerProduit(String id) async {
    await ApiService.deleteProduit(id);
    _fetchProduits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Liste des Produits")),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _produits.length,
        itemBuilder: (context, index) {
          final produit = _produits[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(produit.modele.nom),
              subtitle: Text("Taille: ${produit.taille}, Couleur: ${produit.couleur}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _modifierProduit(produit),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _supprimerProduit(produit.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
