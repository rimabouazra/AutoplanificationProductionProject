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
  String? selectedModeleId;
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
