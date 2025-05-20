import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/matiereProvider.dart';
import '../models/matiere.dart';

class MatiereView extends StatefulWidget {
  const MatiereView({super.key});

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
          content: const Text("Veuillez remplir tous les champs !"),
          backgroundColor: Colors.redAccent,
        ),
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
          content: const Text("Matière ajoutée avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

      referenceController.clear();
      couleurController.clear();
      quantiteController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur : $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _supprimerMatiere(BuildContext context, String id) async {
    final provider = Provider.of<MatiereProvider>(context, listen: false);
    await provider.deleteMatiere(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Matière supprimée"),
        backgroundColor: Colors.blue,
      ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              ajouter ? "Ajouter Quantité" : "Consommer Quantité",
              style: const TextStyle(
                  fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantiteController,
                  decoration: InputDecoration(
                    labelText: "Quantité",
                    prefixIcon: const Icon(Icons.production_quantity_limits,
                        color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                if (!ajouter)
                  DropdownButtonFormField<String>(
                    hint: const Text("Sélectionner une commande"),
                    value: selectedCommandeId,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCommandeId = newValue;
                        if (newValue != null) {
                          final commande = commandes
                              .firstWhere((cmd) => cmd['id'] == newValue);
                          selectedModele = commande['modele'];
                          selectedTaille = commande['taille'];
                        } else {
                          selectedModele = null;
                          selectedTaille = null;
                        }
                      });
                    },
                    items: commandes.map((commande) {
                      return DropdownMenuItem<String>(
                        value: commande['id'],
                        child: Text(
                            "Modèle: ${commande['modele']} | Taille: ${commande['taille']}"),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                if (!ajouter &&
                    selectedModele != null &&
                    selectedTaille != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      "Modèle: $selectedModele | Taille: $selectedTaille",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  //if (!ajouter && selectedCommandeId == null) {
                  //ScaffoldMessenger.of(context).showSnackBar(
                  //SnackBar(
                  //content:
                  //  const Text("Veuillez sélectionner une commande"),
                  //backgroundColor: Colors.redAccent,
                  //),
                  //);
                  //return;
                  //}

                  final provider =
                      Provider.of<MatiereProvider>(context, listen: false);
                  final valeur = int.tryParse(quantiteController.text) ?? 0;
                  if (valeur <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text("Veuillez entrer une quantité valide"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  double nouvelleQuantite = ajouter
                      ? valeur.toDouble()
                      : (valeur.toDouble()).clamp(0, matiere.quantite);

                  // Passer l'action appropriée ("ajout" ou "consommation")
                  await provider.updateMatiere(
                    matiere.id,
                    nouvelleQuantite,
                    action: ajouter ? "ajout" : "consommation",
                  );

                  Navigator.pop(context);
                },
                child: const Text("Confirmer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Matiere> _filtrerMatieres(List<Matiere> matieres) {
    final searchText = searchController.text.toLowerCase();
    return matieres.where((matiere) {
      final matchesSearch =
          matiere.reference.toLowerCase().contains(searchText);
      final matchesDate = selectedDate == null ||
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Renommer la matière",
          style: TextStyle(
              fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: referenceController,
          decoration: InputDecoration(
            labelText: "Nouvelle référence",
            prefixIcon: const Icon(Icons.label, color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
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
                    content: const Text("Veuillez entrer une référence valide"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("Renommer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _afficherHistorique(BuildContext context, Matiere matiere) async {
    final provider = Provider.of<MatiereProvider>(context, listen: false);
    final historique = await provider.fetchHistorique(matiere.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Historique de ${matiere.reference}",
          style: const TextStyle(
              fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
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
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    entry.action.toLowerCase() == 'ajout'
                        ? Icons.add
                        : Icons.remove,
                    color: entry.action.toLowerCase() == 'ajout'
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(
                    _formatDate(entry.date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${entry.action}: ${entry.quantite}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _afficherFormulaireAjout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Ajouter une Matière",
          style: TextStyle(
              fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: referenceController,
              decoration: InputDecoration(
                labelText: "Référence",
                prefixIcon: const Icon(Icons.label, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: couleurController,
              decoration: InputDecoration(
                labelText: "Couleur",
                prefixIcon:
                    const Icon(Icons.color_lens, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantiteController,
              decoration: InputDecoration(
                labelText: "Quantité",
                prefixIcon: const Icon(Icons.production_quantity_limits,
                    color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => _ajouterMatiere(context),
            child: const Text("Ajouter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<MatiereProvider>(
          builder: (context, provider, child) {
            if (provider.matieres.isEmpty) {
              return const Center(
                child: Text(
                  "Aucune matière disponible",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeInDown(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Rechercher une matière...",
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blueGrey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: FadeInDown(
                          delay: const Duration(milliseconds: 200),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today,
                                color: Colors.white),
                            label: Text(
                              selectedDate == null
                                  ? "Filtrer par date"
                                  : DateFormat('yyyy-MM-dd')
                                      .format(selectedDate!),
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
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
                      ),
                      if (selectedDate != null)
                        FadeInRight(
                          child: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                selectedDate = null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<MatiereProvider>(
                    builder: (context, provider, child) {
                      final filteredMatieres =
                          _filtrerMatieres(provider.matieres);

                      if (filteredMatieres.isEmpty) {
                        return const Center(
                          child: Text(
                            "Aucune matière trouvée",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredMatieres.length,
                        itemBuilder: (context, index) {
                          final matiere = filteredMatieres[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: index * 100),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey[800],
                                  child: Text(
                                    matiere.reference[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  matiere.reference,
                                  style: const TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Couleur: ${matiere.couleur}",
                                        style: const TextStyle(fontSize: 14)),
                                    Text("Quantité: ${matiere.quantite}",
                                        style: const TextStyle(fontSize: 14)),
                                    Text(
                                      "Date: ${DateFormat('yyyy-MM-dd').format(matiere.dateAjout)}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.history,
                                          color: Colors.purple),
                                      onPressed: () =>
                                          _afficherHistorique(context, matiere),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _afficherFormulaireRenommage(
                                              context, matiere),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add,
                                          color: Colors.green),
                                      onPressed: () => _modifierQuantite(
                                          context, matiere, true),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove,
                                          color: Colors.orange),
                                      onPressed: () => _modifierQuantite(
                                          context, matiere, false),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _supprimerMatiere(
                                          context, matiere.id),
                                    ),
                                  ],
                                ),
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
      ),
      floatingActionButton: ZoomIn(
        child: FloatingActionButton(
          onPressed: () => _afficherFormulaireAjout(context),
          child: const Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blueGrey[800],
          elevation: 4,
        ),
      ),
    );
  }
}
