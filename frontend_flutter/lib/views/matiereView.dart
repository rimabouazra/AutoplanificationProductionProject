import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matiereProvider.dart';
import '../models/matiere.dart';
import '../widgets/topNavbar.dart';


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
  id: '',
  reference: reference,
  couleur: couleur,
  quantite: quantite,
  dateAjout: DateTime.now(),
  historique: [],
)

      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Matière ajoutée avec succès !"),
            backgroundColor: Colors.green),
      );

      referenceController.clear();
      couleurController.clear();
      quantiteController.clear();
      Navigator.pop(context);
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

  void _modifierQuantite(BuildContext context, Matiere matiere, bool ajouter) {
    TextEditingController quantiteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ajouter ? "Ajouter Quantité" : "Consommer Quantité"),
        content: TextField(
          controller: quantiteController,
          decoration: InputDecoration(labelText: "Quantité"),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final provider =
                  Provider.of<MatiereProvider>(context, listen: false);
              int valeur = int.tryParse(quantiteController.text) ?? 0;

              if (valeur <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Veuillez entrer une quantité valide"),
                      backgroundColor: Colors.red),
                );
                return;
              }

              int nouvelleQuantite = ajouter
                  ? matiere.quantite + valeur
                  : (matiere.quantite - valeur)
                      .clamp(0, double.infinity)
                      .toInt();

              await provider.updateMatiere(matiere.id, nouvelleQuantite);
              Navigator.pop(context);
            },
            child: Text("Confirmer"),
          ),
        ],
      ),
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
              onPressed: () => _ajouterMatiere(context),
              child: Text("Ajouter")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(),
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
                        icon: Icon(Icons.add, color: Colors.green),
                        onPressed: () =>
                            _modifierQuantite(context, matiere, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove, color: Colors.orange),
                        onPressed: () =>
                            _modifierQuantite(context, matiere, false),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _supprimerMatiere(context, matiere.id),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final provider = Provider.of<MatiereProvider>(context,
                              listen: false);
                          List<Historique> historique =
                              await provider.fetchHistorique(matiere.id);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Historique de ${matiere.reference}"),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: historique
                                    .map((h) => Text(
                                        "${h.date} - ${h.action}: ${h.quantite}"))
                                    .toList(),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Fermer"))
                              ],
                            ),
                          );
                        },
                        child: Text("Voir Historique"),
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
