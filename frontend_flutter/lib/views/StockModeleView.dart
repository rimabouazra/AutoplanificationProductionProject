import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/modeleProvider.dart';
import '../models/modele.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
class StockModeleView extends StatefulWidget {
  const StockModeleView({super.key});

  @override
  _StockModeleViewState createState() => _StockModeleViewState();
}

class _StockModeleViewState extends State<StockModeleView> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _taillesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Modele> _filteredModeles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModeleProvider>(context, listen: false).fetchModeles();
    });
    _searchController.addListener(_filterModeles);
  }

  void _filterModeles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredModeles = Provider.of<ModeleProvider>(context, listen: false)
          .modeles
          .where((modele) => modele.nom.toLowerCase().contains(query))
          .toList();
    });
  }

  Widget _buildAssociationsList(Modele modele, ModeleProvider modeleProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Associations de tailles:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        modele.taillesBases.isNotEmpty
            ? Column(
                children: modele.taillesBases.map((tb) {
                  final base = modeleProvider.modeles.firstWhere(
                    (m) => m.id == tb.baseId,
                    orElse: () => Modele(
                        id: '', nom: 'Inconnu', tailles: [], consommation: []),
                  );
                  return ListTile(
                    title: Text('${base.nom} (${tb.tailles.join(", ")})'),
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
              DataColumn(label: Text('Consommation (m)')),
              DataColumn(label: Text('Actions')),
            ],
            rows: modele.tailles.map((taille) {
              final consommation = modele.consommation.firstWhere(
                (c) => c.taille == taille,
                orElse: () => Consommation(taille: taille, quantity: 0.0),
              );
              // Récupérer toutes les tailles de base associées à cette taille
              final taillesBase = modele.taillesBases
                  .asMap()
                  .entries
                  .where((entry) => entry.value.tailles.contains(taille))
                  .map((entry) {
                final base = modeleProvider.modeles.firstWhere(
                  (m) => m.id == entry.value.baseId,
                  orElse: () => Modele(
                      id: '', nom: 'Inconnu', tailles: [], consommation: []),
                );
                final index = modele.tailles.indexOf(taille);
                return '${base.nom}: ${entry.value.tailles[index] ?? "N/A"}';
              }).join(', ');
              return DataRow(
                cells: [
                  DataCell(Text(taille)),
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                                taillesBase.isEmpty ? "N/A" : taillesBase)),
                        IconButton(
                          icon: Icon(Icons.edit, size: 16),
                          onPressed: () =>
                              _editTailleAssociation(modele, taille),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(consommation.quantity.toStringAsFixed(2))),
                  DataCell(
                    IconButton(
                      icon: Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showEditConsommationDialog(modele, taille),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
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


void _addModeleDialog() {
  final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
  final basesDisponibles = modeleProvider.modeles;
  final TextEditingController _consommationController = TextEditingController();
  List<String> selectedBases = [];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Ajouter un modèle',
          style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom du modèle',
                    prefixIcon: const Icon(Icons.view_in_ar, color: Colors.blueGrey),
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
                  controller: _taillesController,
                  decoration: InputDecoration(
                    labelText: 'Tailles (séparées par des virgules)',
                    prefixIcon: const Icon(Icons.format_size, color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                MultiSelectDialogField(
                  items: basesDisponibles
                      .map((base) => MultiSelectItem<String>(base.nom, base.nom))
                      .toList(),
                  title: Text("Sélectionner les bases"),
                  selectedColor: Colors.blueGrey,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: Colors.blueGrey, width: 1),
                  ),
                  buttonText: Text("Bases (optionnel)"),
                  buttonIcon: Icon(Icons.category, color: Colors.blueGrey),
                  onConfirm: (List<String> values) {
                    setState(() {
                      selectedBases = values;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _consommationController,
                  decoration: InputDecoration(
                    labelText: 'Consommation (optionnel)',
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
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nom = _nomController.text.trim();
              final tailles = _taillesController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              if (nom.isEmpty || tailles.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Veuillez remplir tous les champs obligatoires"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              if (selectedBases.isNotEmpty) {
                _showAssociationDialog(context, modeleProvider, nom, tailles, selectedBases, _consommationController.text);
              } else {
                List<Consommation> consommations = [];
                if (_consommationController.text.isNotEmpty) {
                  final consommationValue = double.tryParse(_consommationController.text) ?? 0.0;
                  consommations = tailles
                      .map((taille) => Consommation(taille: taille, quantity: consommationValue))
                      .toList();
                }
                await modeleProvider.addModele(nom, tailles, null, consommations, []);
                _nomController.clear();
                _taillesController.clear();
                _consommationController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Suivant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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

    final existingAssociation = modele.taillesBases.firstWhere(
      (tb) => tb.tailles.contains(tailleModele),
      orElse: () => TailleBase(baseId: "", tailles: []),
    );

    if (existingAssociation.baseId.isNotEmpty) {
      selectedBase = modeleProvider.modeles
          .firstWhere(
            (m) => m.id == existingAssociation.baseId,
            orElse: () =>
                Modele(id: '', nom: 'Inconnu', tailles: [], consommation: []),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Modifier association pour $tailleModele',
                style: const TextStyle(
                    fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
              ),
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
                      const DropdownMenuItem(
                          value: null, child: Text("Aucune base")),
                      ...bases.map((base) {
                        return DropdownMenuItem(
                            value: base.nom, child: Text(base.nom));
                      }).toList(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Base',
                      prefixIcon:
                          const Icon(Icons.category, color: Colors.blueGrey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
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
                        const DropdownMenuItem(
                            value: null, child: Text("Sélectionner")),
                        ...bases
                            .firstWhere((b) => b.nom == selectedBase)
                            .tailles
                            .map((taille) {
                          return DropdownMenuItem(
                              value: taille, child: Text(taille));
                        }).toList(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Taille correspondante',
                        prefixIcon: const Icon(Icons.format_size,
                            color: Colors.blueGrey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedBase != null && selectedTailleBase != null) {
                      final baseId =
                          bases.firstWhere((b) => b.nom == selectedBase).id;
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
                        null,
                        modele.consommation,
                        updatedTaillesBases,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
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
        );
      },
    );
  }

void _showAssociationDialog(
    BuildContext context,
    ModeleProvider modeleProvider,
    String nom,
    List<String> tailles,
    List<String> baseNoms,
    String consommationText) {
  final Map<String, List<Map<String, dynamic>>> associationsByBase = {};

  for (final baseNom in baseNoms) {
    final baseModel = modeleProvider.modeles.firstWhere(
      (m) => m.nom == baseNom,
      orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []),
    );
    associationsByBase[baseNom] = tailles.asMap().entries.map((entry) {
      final int index = entry.key;
      final String tailleModele = entry.value;
      final String tailleBase =
          index < baseModel.tailles.length ? baseModel.tailles[index] : "N/A";
      return {'tailleModele': tailleModele, 'tailleBase': tailleBase};
    }).toList();
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Valider les associations de tailles',
              style: TextStyle(fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...baseNoms.map((baseNom) {
                    final baseModel = modeleProvider.modeles.firstWhere(
                      (m) => m.nom == baseNom,
                      orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Base: $baseNom',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...associationsByBase[baseNom]!.map((association) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: Text('${association['tailleModele']} →')),
                                const SizedBox(width: 10),
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
                                            value: baseTaille, child: Text(baseTaille));
                                      }).toList(),
                                      const DropdownMenuItem(
                                          value: "N/A",
                                          child: Text('Non associé', style: TextStyle(color: Colors.grey))),
                                    ],
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final List<TailleBase> taillesBases = [];
                  final Map<String, List<String>> baseTaillesMap = {};

                  for (final baseNom in baseNoms) {
                    final baseModel = modeleProvider.modeles.firstWhere(
                      (m) => m.nom == baseNom,
                      orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []),
                    );
                    for (final assoc in associationsByBase[baseNom]!) {
                      if (assoc['tailleBase'] != "N/A") {
                        if (!baseTaillesMap.containsKey(baseModel.id)) {
                          baseTaillesMap[baseModel.id] = [];
                        }
                        baseTaillesMap[baseModel.id]!.add(assoc['tailleBase']!);
                      }
                    }
                    if (baseTaillesMap.containsKey(baseModel.id)) {
                      taillesBases.add(TailleBase(baseId: baseModel.id, tailles: baseTaillesMap[baseModel.id]!));
                    }
                  }

                  List<Consommation> consommations = [];
                  if (consommationText.isNotEmpty) {
                    final consommationValue = double.tryParse(consommationText) ?? 0.0;
                    consommations = tailles
                        .map((taille) => Consommation(taille: taille, quantity: consommationValue))
                        .toList();
                  }

                  await modeleProvider.addModele(nom, tailles, baseNoms, consommations, taillesBases);
                  _nomController.clear();
                  _taillesController.clear();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Confirmer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
    _nomController.text = modele.nom;
    _taillesController.text = modele.tailles.join(', ');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Modifier le modèle',
            style: TextStyle(
                fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du modèle',
                  prefixIcon:
                      const Icon(Icons.view_in_ar, color: Colors.blueGrey),
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
                controller: _taillesController,
                decoration: InputDecoration(
                  labelText: 'Tailles (séparées par des virgules)',
                  prefixIcon:
                      const Icon(Icons.format_size, color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nom = _nomController.text.trim();
                final tailles = _taillesController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (nom.isEmpty || tailles.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Veuillez remplir tous les champs obligatoires"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                await modeleProvider.updateModele(
                  modele.id,
                  nom,
                  tailles,
                  modele.taillesBases.isNotEmpty
                      ? modele.taillesBases.first.baseId
                      : null,
                  modele.consommation,
                  modele.taillesBases,
                );
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
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
    );
  }

  void _deleteModele(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(
              fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        content: const Text('Voulez-vous vraiment supprimer ce modèle ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<ModeleProvider>(context, listen: false)
          .deleteModele(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Modèle supprimé avec succès"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _taillesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeleProvider = Provider.of<ModeleProvider>(context);
    final modeles = _searchController.text.isEmpty
        ? modeleProvider.modeles
        : _filteredModeles;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                ? Center(
                    child: _searchController.text.isEmpty
                        ? CircularProgressIndicator()
                        : Text(
                            'Aucun modèle trouvé',
                            style: TextStyle(fontSize: 18),
                          ),
                  )
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
                            '${modele.tailles.length} tailles ',
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
                                    "Associations de tailles:",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  modele.taillesBases.isNotEmpty
                                      ? Column(
                                          children:
                                              modele.taillesBases.map((tb) {
                                            final base = modeleProvider.modeles
                                                .firstWhere(
                                              (m) => m.id == tb.baseId,
                                              orElse: () => Modele(
                                                  id: '',
                                                  nom: 'Inconnu',
                                                  tailles: [],
                                                  consommation: []),
                                            );
                                            return ListTile(
                                              title: Text(base.nom),
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
                                        final taillesBase = modele
                                            .getTailleBaseForTaille(taille)
                                            .join(', ');
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(taille)),
                                            DataCell(
                                              Row(
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                          taillesBase.isEmpty
                                                              ? "N/A"
                                                              : taillesBase)),
                                                  IconButton(
                                                    icon: Icon(Icons.edit,
                                                        size: 16),
                                                    onPressed: () =>
                                                        _editTailleAssociation(
                                                            modele, taille),
                                                  ),
                                                ],
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
