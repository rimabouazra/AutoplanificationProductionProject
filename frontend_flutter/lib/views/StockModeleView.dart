import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/modeleProvider.dart';
import '../models/modele.dart';

class StockModeleView extends StatefulWidget {
  @override
  _StockModeleViewState createState() => _StockModeleViewState();
}

class _StockModeleViewState extends State<StockModeleView> {
  TextEditingController _nomController = TextEditingController();
  TextEditingController _taillesController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  List<Modele> _filteredModeles = [];
  String? _selectedBase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModeleProvider>(context, listen: false).fetchModeles();
    });
    _searchController.addListener(_filterModeles);
  }

  void _filterModeles() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredModeles = Provider.of<ModeleProvider>(context, listen: false)
          .modeles
          .where((modele) => modele.nom.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addModeleDialog() {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    final basesDisponibles = modeleProvider.modeles.map((m) => m.nom).toList();
    TextEditingController _consommationController = TextEditingController();
    String? _selectedBase;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter un modèle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom du modèle'),
              ),
              TextField(
                controller: _taillesController,
                decoration: InputDecoration(
                    labelText: 'Tailles (séparées par des virgules)'),
              ),
              //TextField(
              //controller: _consommationController,
              //decoration: InputDecoration(labelText: 'Consommation (en m)'),
              //keyboardType: TextInputType.number,
              //),//a changer
              DropdownButtonFormField<String>(
                value: _selectedBase,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBase = newValue;
                  });
                },
                items: [
                  DropdownMenuItem(value: null, child: Text("Aucune base")),
                  ...basesDisponibles.map((base) {
                    return DropdownMenuItem(value: base, child: Text(base));
                  }).toList(),
                ],
                decoration: InputDecoration(labelText: 'Base (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                String nom = _nomController.text;
                List<String> tailles = _taillesController.text.split(',');
                if (_selectedBase != null) {
                  // Afficher le dialogue de validation des associations
                  _showAssociationDialog(context, modeleProvider, nom, tailles,
                      _selectedBase!, _consommationController.text);
                } else {
                  // Pas de base sélectionnée, procéder directement
                  List<Consommation> consommations = [];
                  if (_consommationController.text.isNotEmpty) {
                    double consommationValue =
                        double.tryParse(_consommationController.text) ?? 0.0;
                    consommations = tailles
                        .map((taille) => Consommation(
                            taille: taille, quantity: consommationValue))
                        .toList();
                  }

                  await modeleProvider
                      .addModele(nom, tailles, null, consommations, []);

                  _nomController.clear();
                  _taillesController.clear();
                  _consommationController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Suivant'),
            ),
          ],
        );
      },
    );
  }

  void _editTailleAssociation(Modele modele, String tailleModele) {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    final bases = modeleProvider.modeles;

    String? selectedBase;
    String? selectedTailleBase;

    // Trouver l'association existante
    final existingAssociation = modele.taillesBases.firstWhere(
      (tb) => tb.tailles.contains(tailleModele),
      orElse: () => TailleBase(baseId: "", tailles: []),
    );

    if (existingAssociation.baseId.isNotEmpty) {
      selectedBase = modeleProvider.modeles
          .firstWhere(
            (m) => m.id == existingAssociation.baseId,
            orElse: () =>
                Modele(id: '', nom: '', tailles: [], consommation: []),
          )
          .nom;
      selectedTailleBase = existingAssociation.tailles.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Modifier association pour $tailleModele'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBase,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBase = newValue;
                        selectedTailleBase = null;
                      });
                    },
                    items: [
                      DropdownMenuItem(value: null, child: Text("Aucune base")),
                      ...bases.map((base) {
                        return DropdownMenuItem(
                          value: base.nom,
                          child: Text(base.nom),
                        );
                      }).toList(),
                    ],
                    decoration: InputDecoration(labelText: 'Base'),
                  ),
                  if (selectedBase != null)
                    DropdownButtonFormField<String>(
                      value: selectedTailleBase,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedTailleBase = newValue;
                        });
                      },
                      items: [
                        DropdownMenuItem(
                            value: null, child: Text("Sélectionner")),
                        ...bases
                            .firstWhere((b) => b.nom == selectedBase)
                            .tailles
                            .map((taille) {
                          return DropdownMenuItem(
                            value: taille,
                            child: Text(taille),
                          );
                        }).toList(),
                      ],
                      decoration:
                          InputDecoration(labelText: 'Taille correspondante'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedBase != null && selectedTailleBase != null) {
                      final baseId =
                          bases.firstWhere((b) => b.nom == selectedBase).id;

                      // Mettre à jour les taillesBases
                      final updatedTaillesBases = [...modele.taillesBases];
                      updatedTaillesBases.removeWhere(
                          (tb) => tb.tailles.contains(tailleModele));
                      updatedTaillesBases.add(TailleBase(
                        baseId: baseId,
                        tailles: [selectedTailleBase!],
                      ));

                      await modeleProvider.updateModele(
                        modele.id,
                        modele.nom,
                        modele.tailles,
                        _selectedBase,
                        modele.consommation,
                        updatedTaillesBases,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAssociationDialog(
    BuildContext context,
    ModeleProvider modeleProvider,
    String nom,
    List<String> tailles,
    String baseNom,
    String consommationText,
  ) {
    final baseModel = modeleProvider.modeles.firstWhere(
      (m) => m.nom == baseNom,
      orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []),
    );

    // Créer les associations par défaut (index par index)
    List<Map<String, dynamic>> associations =
        tailles.asMap().entries.map((entry) {
      int index = entry.key;
      String tailleModele = entry.value;
      String tailleBase =
          index < baseModel.tailles.length ? baseModel.tailles[index] : "N/A";

      return {
        'tailleModele': tailleModele,
        'tailleBase': tailleBase,
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Valider les associations de tailles'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Vérifiez les associations entre les tailles du modèle et celles de la base "$baseNom"'),
                    SizedBox(height: 16),
                    ...associations.map((association) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${association['tailleModele']} →'),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: association['tailleBase'],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    association['tailleBase'] = newValue;
                                  });
                                },
                                items: [
                                  ...baseModel.tailles.map((baseTaille) {
                                    return DropdownMenuItem(
                                      value: baseTaille,
                                      child: Text(baseTaille),
                                    );
                                  }).toList(),
                                  DropdownMenuItem(
                                    value: "N/A",
                                    child: Text('Non associé',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    // Préparer les taillesBases pour l'API
                    List<TailleBase> taillesBases = [];
                    for (var assoc in associations) {
                      if (assoc['tailleBase'] != "N/A") {
                        taillesBases.add(TailleBase(
                          baseId: baseModel.id,
                          tailles: [assoc['tailleBase']!],
                        ));
                      }
                    }

                    // Préparer les consommations
                    List<Consommation> consommations = [];
                    if (consommationText.isNotEmpty) {
                      double consommationValue =
                          double.tryParse(consommationText) ?? 0.0;
                      consommations = tailles
                          .map((taille) => Consommation(
                              taille: taille, quantity: consommationValue))
                          .toList();
                    }

                    await modeleProvider.addModele(
                        nom, tailles, baseNom, consommations, taillesBases);

                    _nomController.clear();
                    _taillesController.clear();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editModeleDialog(Modele modele) {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    final basesDisponibles = modeleProvider.modeles.map((m) => m.nom).toList();
    TextEditingController _consommationController = TextEditingController(
        text: (modele.consommation.isNotEmpty &&
                modele.consommation[0].quantity > 0)
            ? modele.consommation[0].quantity.toStringAsFixed(2)
            : '');

    _nomController.text = modele.nom;
    _taillesController.text = modele.tailles.join(', ');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier le modèle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom du modèle'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedBase,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedBase = newValue;
                  });
                },
                items: [
                  DropdownMenuItem(value: null, child: Text("Aucune base")),
                  ...basesDisponibles.map((base) {
                    return DropdownMenuItem(value: base, child: Text(base));
                  }).toList(),
                ],
                decoration: InputDecoration(labelText: 'Base (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                String nom = _nomController.text;
                //List<String> tailles = _taillesController.text.split(',');
                //double consommationValue =
                //double.tryParse(_consommationController.text) ?? 0.0;
                //List<Consommation> consommations = tailles
                //.map((taille) => Consommation(
                //taille: taille, quantity: consommationValue))
                //.toList();
                await modeleProvider.updateModele(modele.id, nom,
                    modele.tailles, _selectedBase, modele.consommation);
                Navigator.pop(context);
              },
              child: Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _deleteModele(String id) async {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    await modeleProvider.deleteModele(id);
  }

  void _showEditConsommationDialog(Modele modele, String taille) {
    final consommation = modele.consommation.firstWhere(
      (c) => c.taille == taille,
      orElse: () => Consommation(taille: taille, quantity: 0.0),
    );

    final controller = TextEditingController(
      text: consommation.quantity.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Modifier consommation pour $taille'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Nouvelle quantité (m)',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? 0.0;
                Provider.of<ModeleProvider>(context, listen: false)
                    .updateConsommation(modele.id, taille, newValue);
                Navigator.pop(context);
              },
              child: Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeleProvider = Provider.of<ModeleProvider>(context);
    final modeles = _searchController.text.isEmpty
        ? modeleProvider.modeles
        : _filteredModeles;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Color(0xFF1ABC9C),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _addModeleDialog,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: modeles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: modeles.length,
                    itemBuilder: (context, index) {
                      final modele = modeles[index];
                      return Card(
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ExpansionTile(
                          title: Text(
                            modele.nom,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${modele.tailles.length} tailles disponibles',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editModeleDialog(modele),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteModele(modele.id),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bases associées:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  modele.derives != null &&
                                          modele.derives!.isNotEmpty
                                      ? Column(
                                          children: modele.derives!.map((base) {
                                            return ListTile(
                                              leading: Icon(Icons.link,
                                                  color: Colors.blue),
                                              title: Text(base.nom),
                                              subtitle:
                                                  Text(base.tailles.join(', ')),
                                            );
                                          }).toList(),
                                        )
                                      : Text(
                                          "Moule d'origine",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                  SizedBox(height: 16),
                                  Text(
                                    "Consommations par taille:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 20,
                                      columns: [
                                        DataColumn(label: Text('Taille')),
                                        DataColumn(label: Text('Tailles Base')),
                                        DataColumn(
                                            label: Text('Consommation (m)')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: modele.tailles.map((taille) {
                                        final consommation =
                                            modele.consommation.firstWhere(
                                          (c) => c.taille == taille,
                                          orElse: () => Consommation(
                                              taille: taille, quantity: 0.0),
                                        );
                                        // Trouver la taille correspondante dans la base associée
                                        String taillesBase =
                                            "N/A"; // Valeur par défaut
                                        if (modele.taillesBases.isNotEmpty) {
                                          final baseCorrespondante =
                                              modele.taillesBases.firstWhere(
                                            (tb) => tb.tailles.contains(taille),
                                            orElse: () => TailleBase(
                                                baseId: "", tailles: []),
                                          );

                                          if (baseCorrespondante != null) {
                                            int index =
                                                modele.tailles.indexOf(taille);
                                            if (index != -1 &&
                                                index <
                                                    baseCorrespondante
                                                        .tailles.length) {
                                              taillesBase = baseCorrespondante
                                                  .tailles[index];
                                            }
                                          }
                                        }

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(taille)),
                                            DataCell(
                                              Builder(
                                                builder: (context) {
                                                  final tailleBase = modele
                                                      .getTailleBaseForTaille(
                                                          taille);
                                                  return Row(
                                                    children: [
                                                      Text(tailleBase ?? "N/A"),
                                                      if (tailleBase != null)
                                                        IconButton(
                                                          icon: Icon(Icons.edit,
                                                              size: 16),
                                                          onPressed: () =>
                                                              _editTailleAssociation(
                                                                  modele,
                                                                  taille),
                                                        ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                            DataCell(Text(consommation.quantity
                                                .toStringAsFixed(2))),
                                            DataCell(
                                              IconButton(
                                                icon:
                                                    Icon(Icons.edit, size: 20),
                                                onPressed: () =>
                                                    _showEditConsommationDialog(
                                                        modele, taille),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
