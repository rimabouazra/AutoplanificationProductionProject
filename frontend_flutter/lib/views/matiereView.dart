import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matiereProvider.dart';
import '../models/matiere.dart';

class MatiereView extends StatefulWidget {
  @override
  _MatiereViewState createState() => _MatiereViewState();
}

class _MatiereViewState extends State<MatiereView> {
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController couleurController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<MatiereProvider>(context, listen: false).fetchMatieres();
  }

  void _ajouterMatiere(BuildContext context) async {
    final provider = Provider.of<MatiereProvider>(context, listen: false);
    final reference = referenceController.text.trim();
    final couleur = couleurController.text.trim();
    final quantite = int.tryParse(quantiteController.text) ?? 0;

    if (reference.isEmpty || couleur.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Veuillez remplir tous les champs !"),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await provider.addMatiere(
        Matiere(
            id: '', reference: reference, couleur: couleur, quantite: quantite),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Matière ajoutée avec succès !"),
            backgroundColor: Colors.green),
      );
      referenceController.clear();
      couleurController.clear();
      quantiteController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _supprimerMatiere(BuildContext context, String id) async {
    final provider = Provider.of<MatiereProvider>(context, listen: false);
    await provider.deleteMatiere(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Matière supprimée"), backgroundColor: Colors.blue),
    );
  }

  void _afficherFormulaireAjout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Ajouter une Matière"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: referenceController,
              decoration: InputDecoration(labelText: "Référence"),
            ),
            TextField(
              controller: couleurController,
              decoration: InputDecoration(labelText: "Couleur"),
            ),
            TextField(
              controller: quantiteController,
              decoration: InputDecoration(labelText: "Quantité"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
              onPressed: () {
                _ajouterMatiere(context);
                Navigator.pop(context);
              },
              child: Text("Ajouter")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestion des Matières")),
      body: Consumer<MatiereProvider>(
        builder: (context, provider, child) {
          if (provider.matieres.isEmpty) {
            return Center(child: Text("Aucune matière disponible"));
          }
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: provider.matieres.length,
            itemBuilder: (context, index) {
              final matiere = provider.matieres[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(matiere.reference[0].toUpperCase(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(matiere.reference,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Couleur: ${matiere.couleur} - Quantité: ${matiere.quantite}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              int newQuantite =
                                  matiere.quantite; // Quantité actuelle

                              return AlertDialog(
                                title: Text("Modifier la quantité"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                          labelText: "Nouvelle quantité"),
                                      onChanged: (value) {
                                        newQuantite = int.tryParse(value) ??
                                            matiere.quantite;
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: Text("Annuler"),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  ElevatedButton(
                                    child: Text("Modifier"),
                                    onPressed: () {
                                      Provider.of<MatiereProvider>(context,
                                              listen: false)
                                          .updateMatiere(
                                              matiere.id, newQuantite);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _supprimerMatiere(context, matiere.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherFormulaireAjout(context),
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
