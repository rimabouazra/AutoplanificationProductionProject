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
    final quantite = double.tryParse(quantiteController.text) ?? 0;

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
      appBar: TopNavbar(), // Utilisation du TopNavbar ici
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
<<<<<<< HEAD
              ),

              // Filtre par date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.calendar_today, color: Colors.white),
                        label: Text(
                            selectedDate == null
                                ? "Filtrer par date"
                                : DateFormat('yyyy-MM-dd')
                                    .format(selectedDate!),
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 121, 166, 244),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),

              // Liste des matières
              Expanded(
                child: Consumer<MatiereProvider>(
                  builder: (context, provider, child) {
                    List<Matiere> filteredMatieres =
                        _filtrerMatieres(provider.matieres);

                    if (filteredMatieres.isEmpty) {
                      return Center(
                          child: Text("Aucune matière trouvée",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey)));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredMatieres.length,
                      itemBuilder: (context, index) {
                        final matiere = filteredMatieres[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 4,
                          margin: EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(matiere.reference[0].toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(matiere.reference,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Couleur: ${matiere.couleur}",
                                    style: TextStyle(fontSize: 14)),
                                Text("Quantité: ${matiere.quantite}",
                                    style: TextStyle(fontSize: 14)),
                                Text(
                                    "Date: ${DateFormat('yyyy-MM-dd').format(matiere.dateAjout)}",
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon:
                                      Icon(Icons.history, color: Colors.purple),
                                  onPressed: () =>
                                      _afficherHistorique(context, matiere),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _afficherFormulaireRenommage(
                                      context, matiere),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add, color: Colors.green),
                                  onPressed: () =>
                                      _modifierQuantite(context, matiere, true),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.remove, color: Colors.orange),
                                  onPressed: () => _modifierQuantite(
                                      context, matiere, false),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _supprimerMatiere(context, matiere.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
=======
              );
            },
>>>>>>> 9deaa6a130574ea4b6de70f030c565bc65214b78
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
