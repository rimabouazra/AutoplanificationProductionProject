import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matiereProvider.dart';
import '../models/matiere.dart';
import 'package:intl/intl.dart';

class MatiereView extends StatefulWidget {
  @override
  _MatiereViewState createState() => _MatiereViewState();
}

class _MatiereViewState extends State<MatiereView> {
  final TextEditingController referenceController = TextEditingController();
  final TextEditingController couleurController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;

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
      await provider.addMatiere(Matiere(
        id: '',
        reference: reference,
        couleur: couleur,
        quantite: quantite,
        dateAjout: DateTime.now(),
        historique: [],
      ));

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

  void _modifierQuantite(
      BuildContext context, Matiere matiere, bool ajouter) async {
    TextEditingController quantiteController = TextEditingController();
    List<Map<String, dynamic>> commandes = [];

    String? selectedCommandeId;
    String? selectedModele;
    String? selectedTaille;
    if (!ajouter) {
      commandes = await Provider.of<MatiereProvider>(context, listen: false)
          .fetchCommandes();
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(ajouter ? "Ajouter Quantité" : "Consommer Quantité"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantiteController,
                  decoration: InputDecoration(labelText: "Quantité"),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 10),
                if (!ajouter)
                  DropdownButton<String>(
                    hint: Text("Sélectionner une commande"),
                    value: selectedCommandeId,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCommandeId = newValue;
                        final commande = commandes
                            .firstWhere((cmd) => cmd['id'] == newValue);
                        selectedModele = commande['modele'];
                        selectedTaille = commande['taille'];
                      });
                    },
                    items: commandes.map((commande) {
                      return DropdownMenuItem<String>(
                        value: commande['id'],
                        child: Text(
                            "Modèle: ${commande['modele']} | Taille: ${commande['taille']}"),
                      );
                    }).toList(),
                  ),
                if (!ajouter &&
                    selectedModele != null &&
                    selectedTaille != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "Modèle: $selectedModele | Taille: $selectedTaille",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!ajouter && selectedCommandeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Veuillez sélectionner une commande"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final provider =
                      Provider.of<MatiereProvider>(context, listen: false);
                  int valeur = int.tryParse(quantiteController.text) ?? 0;
                  if (valeur <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Veuillez entrer une quantité valide"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  double nouvelleQuantite = ajouter
                      ? matiere.quantite + valeur.toDouble()
                      : (matiere.quantite - valeur.toDouble())
                          .clamp(0, double.infinity);

                  await provider.updateMatiere(matiere.id, nouvelleQuantite);

                  Navigator.pop(context);
                },
                child: Text("Confirmer"),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Matiere> _filtrerMatieres(List<Matiere> matieres) {
    String searchText = searchController.text.toLowerCase();
    return matieres.where((matiere) {
      bool matchesSearch = matiere.reference.toLowerCase().contains(searchText);
      bool matchesDate = selectedDate == null ||
          DateFormat('yyyy-MM-dd').format(matiere.dateAjout) ==
              DateFormat('yyyy-MM-dd').format(selectedDate!);
      return matchesSearch && matchesDate;
    }).toList();
  }

  String _formatDate(dynamic date) {
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      throw ArgumentError("Format de date invalide : $date");
    }

    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void _afficherFormulaireRenommage(BuildContext context, Matiere matiere) {
    final TextEditingController referenceController =
        TextEditingController(text: matiere.reference);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Renommer la matière"),
        content: TextField(
          controller: referenceController,
          decoration: InputDecoration(labelText: "Nouvelle référence"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newReference = referenceController.text.trim();
              if (newReference.isNotEmpty) {
                await Provider.of<MatiereProvider>(context, listen: false)
                    .renameMatiere(matiere.id, newReference);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Veuillez entrer une référence valide"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("Renommer"),
          ),
        ],
      ),
    );
  }

  void _afficherHistorique(BuildContext context, Matiere matiere) async {
    final provider = Provider.of<MatiereProvider>(context, listen: false);
    List<Historique> historique = await provider.fetchHistorique(matiere.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Historique de ${matiere.reference}",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: historique.length,
            itemBuilder: (context, index) {
              final entry = historique[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    entry.action == 'Ajout' ? Icons.add : Icons.remove,
                    color: entry.action == 'Ajout' ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    _formatDate(entry.date),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${entry.action}: ${entry.quantite}",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer", style: TextStyle(color: Colors.blue)),
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
      body: Consumer<MatiereProvider>(
        builder: (context, provider, child) {
          if (provider.matieres.isEmpty) {
            return Center(
                child: Text("Aucune matière disponible",
                    style: TextStyle(fontSize: 18, color: Colors.grey)));
          }
          return Column(
            children: [
              // Champ de recherche
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Rechercher une matière...",
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
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
                          backgroundColor: const Color.fromARGB(255, 147, 179, 234),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _afficherFormulaireAjout(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF1ABC9C),
        elevation: 4,
      ),
    );
  }
}
