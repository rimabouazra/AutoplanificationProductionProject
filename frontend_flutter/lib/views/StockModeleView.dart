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
      _filteredModeles = Provider.of<ModeleProvider>(context, listen: false).modeles
          .where((modele) => modele.nom.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addModeleDialog() {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    final basesDisponibles = modeleProvider.modeles.map((m) => m.nom).toList();

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
                decoration: InputDecoration(labelText: 'Tailles (séparées par des virgules)'),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                String nom = _nomController.text;
                List<String> tailles = _taillesController.text.split(',');

                await modeleProvider.addModele(nom, tailles, _selectedBase);
                Navigator.of(context).pop();
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

    _nomController.text = modele.nom;
    _taillesController.text = modele.tailles.join(', ');
    //_selectedBase = modele.bases?.firstWhere((base) => true, orElse: () => null)?.nom;

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
              TextField(
                controller: _taillesController,
                decoration: InputDecoration(labelText: 'Tailles (séparées par des virgules)'),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                String nom = _nomController.text;
                List<String> tailles = _taillesController.text.split(',');

                await modeleProvider.updateModele(modele.id, nom, tailles, _selectedBase);
                Navigator.of(context).pop();
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
  @override
  Widget build(BuildContext context) {
    final modeleProvider = Provider.of<ModeleProvider>(context);
    final modeles = _searchController.text.isEmpty ? modeleProvider.modeles : _filteredModeles;

    return Scaffold(
      appBar: AppBar(
          actions: [
          Container(
            margin: EdgeInsets.only(right: 16), 
            child: CircleAvatar(
              backgroundColor: Color(0xFF1ABC9C),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _addModeleDialog, 
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
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            modele.nom,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text("Tailles disponibles: ${modele.tailles.join(', ')}"),
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
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bases associées:",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  modele.derives != null && modele.derives!.isNotEmpty
                                      ? Column(
                                          children: modele.derives!.map((base) {
                                            return ListTile(
                                              leading: Icon(Icons.link, color: Colors.blueAccent),
                                              title: Text(base.nom),
                                              subtitle: Text("Tailles: ${base.tailles.join(', ')}"),
                                            );
                                          }).toList(),
                                        )
                                      : Text("Moule d'origine", style: TextStyle(color: Colors.grey)),
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
