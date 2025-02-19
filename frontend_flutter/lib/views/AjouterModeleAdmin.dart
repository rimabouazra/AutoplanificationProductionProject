import 'package:flutter/material.dart';
import '../models/modele.dart';
import '../services/api_service.dart';

class AjouterModeleAdmin extends StatefulWidget {
  final String machineId;

  const AjouterModeleAdmin({required this.machineId, Key? key}) : super(key: key);

  @override
  _AjouterModeleAdminState createState() => _AjouterModeleAdminState();
}

class _AjouterModeleAdminState extends State<AjouterModeleAdmin> {
  List<Modele> modeles = [];
  Modele? selectedModele;
  String? selectedTaille;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchModeles();
  }

  Future<void> _fetchModeles() async {
    try {
      List<Modele> fetchedModeles = await ApiService.getModeles();
      setState(() {
        modeles = fetchedModeles;
      });
    } catch (e) {
      _showSnackBar("Erreur lors du chargement des modèles : $e", isError: true);
    }
  }

  Future<void> _ajouterModeleDialog() async {
    final TextEditingController nomController = TextEditingController();
    final TextEditingController taillesController = TextEditingController();
    bool isSaving = false;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              title: Text("Ajouter un Modèle", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
                    decoration: InputDecoration(
                      labelText: "Nom du Modèle",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: taillesController,
                    decoration: InputDecoration(
                      labelText: "Tailles (séparées par des virgules)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annuler", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          String nom = nomController.text.trim();
                          List<String> tailles = taillesController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          if (nom.isEmpty || tailles.isEmpty) {
                            _showSnackBar("Veuillez remplir tous les champs", isError: true);
                            return;
                          }

                          await ApiService.addModele(nom, tailles);
                          await _fetchModeles();
                          Navigator.pop(context);
                          _showSnackBar("Modèle ajouté avec succès !");
                        },
                  child: isSaving
                      ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text("Ajouter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter un modèle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<Modele>(
                            decoration: InputDecoration(
                              labelText: "Sélectionner un modèle",
                              border: OutlineInputBorder(),
                            ),
                            value: selectedModele,
                            onChanged: (Modele? newValue) {
                              setState(() {
                                selectedModele = newValue;
                                selectedTaille = null;
                              });
                            },
                            items: modeles.map((Modele modele) {
                              return DropdownMenuItem<Modele>(
                                value: modele,
                                child: Text(modele.nom),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Colors.blue, size: 32),
                          onPressed: _ajouterModeleDialog,
                        ),
                      ],
                    ),
                    if (selectedModele != null) ...[
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Sélectionner une taille",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedTaille,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTaille = newValue;
                          });
                        },
                        items: selectedModele!.tailles.map((String taille) {
                          return DropdownMenuItem<String>(
                            value: taille,
                            child: Text(taille),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: (selectedModele != null && selectedTaille != null && !isLoading)
                    ? () async {
                        setState(() => isLoading = true);
                        await ApiService.updateMachineModele(
                          widget.machineId,
                          selectedModele!.id,
                          selectedTaille!,
                        );
                        setState(() => isLoading = false);
                        _showSnackBar("Modèle associé avec succès !");
                        Navigator.pop(context);
                      }
                    : null,
                child: isLoading
                    ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text("Associer", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
