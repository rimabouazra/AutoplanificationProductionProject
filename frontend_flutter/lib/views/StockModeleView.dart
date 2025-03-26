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
              TextField(
                controller: _consommationController,
                decoration: InputDecoration(labelText: 'Consommation (en m)'),
                keyboardType: TextInputType.number,
              ),//a changer
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
                List<Consommation> consommations = [];
                if (_consommationController.text.isNotEmpty) {
                  double consommationValue =
                      double.tryParse(_consommationController.text) ?? 0.0;
                  consommations = tailles
                      .map((taille) => Consommation(
                          taille: taille, quantity: consommationValue))
                      .toList();
                }
                await modeleProvider.addModele(
                    nom, tailles, _selectedBase, consommations);

                _nomController.clear();
                _taillesController.clear();
                _consommationController.clear();
                Navigator.pop(context);
              },
              child: Text('Ajouter'),
            ),
          ],
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
                await modeleProvider.updateModele(
                    modele.id, nom, modele.tailles, _selectedBase, modele.consommation);
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
                                            DataCell(Text(taillesBase)),
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
