import 'package:flutter/material.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/views/AjouterModeleAdmin.dart';
import '../models/machine.dart';
import '../services/api_service.dart';

class MachinesParSalleView extends StatefulWidget {
  final String salleId;
  const MachinesParSalleView({Key? key, required this.salleId})
      : super(key: key);

  @override
  _MachinesParSalleViewState createState() => _MachinesParSalleViewState();
}

class _MachinesParSalleViewState extends State<MachinesParSalleView> {
  List<dynamic> machines = [];

  @override
  void initState() {
    super.initState();
    fetchMachinesParSalle();
  }

  Future<void> fetchMachinesParSalle() async {
    try {
      var data = await ApiService.fetchMachinesParSalle(widget.salleId);
      print("Données reçues de l'API : $data"); // Debug
      setState(() {
        machines = data;
      });
    } catch (e) {
      print("Erreur lors du chargement des machines : $e");
    }
  }

  Future<void> _showAddMachineDialog() async {
    TextEditingController nomController = TextEditingController();
    String? selectedModele;
    String? selectedTaille;
    List<Modele> modeles = [];

    // Récupérer les modèles depuis l'API
    try {
      modeles = await ApiService.getModeles();
      print("Modèles récupérés : $modeles"); // DEBUG
    } catch (e) {
      print("Erreur lors du chargement des modèles : $e");
    }
    // Vérifiez si la liste est vide
    if (modeles.isEmpty) {
      print("Aucun modèle disponible !");
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Ajouter une Machine"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: InputDecoration(
                        labelText: "Nom de la machine",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedModele,
                      hint: Text("Sélectionner un modèle"),
                      items: modeles.map<DropdownMenuItem<String>>((modele) {
                        return DropdownMenuItem<String>(
                          value: modele.id,
                          child: Text(modele.nom),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedModele = value;
                          selectedTaille =
                              null; // Réinitialiser la taille si modèle change
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (selectedModele != null)
                      DropdownButtonFormField<String>(
                        value: selectedTaille,
                        hint: Text("Sélectionner une taille"),
                        items: modeles
                            .firstWhere(
                              (m) => m.id == selectedModele,
                              orElse: () => Modele(
                                  id: '',
                                  nom: '',
                                  tailles: []), // Retourne un objet Modele vide si non trouvé
                            )
                            .tailles
                            .map<DropdownMenuItem<String>>((taille) {
                          return DropdownMenuItem<String>(
                            value: taille,
                            child: Text(taille),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTaille = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Annuler"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Ajouter"),
                  onPressed: () async {
                    String nom = nomController.text.trim();
                    if (nom.isEmpty) {
                      print("Veuillez remplir le champ du nom.");
                      return;
                    }

                    try {
                      await ApiService.addMachine(
                        nom: nom,
                        salleId: widget.salleId,
                        modele: selectedModele,
                        taille: selectedTaille,
                      );
                      Navigator.pop(context);
                      fetchMachinesParSalle();
                    } catch (e) {
                      print("Erreur lors de l'ajout de la machine : $e");
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMachineDialog(dynamic machine) async {
    TextEditingController nomController =
        TextEditingController(text: machine["nom"]);
    String etat = machine["etat"] ?? "disponible";
    String modele = machine["modele"]?["nom"] ?? "Aucun modèle";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Modifier la Machine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: "Nom de la machine"),
              ),
              DropdownButton<String>(
                value: etat,
                onChanged: (String? newValue) {
                  setState(() {
                    etat = newValue!;
                  });
                },
                items: ["disponible", "occupee", "arretee"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Enregistrer"),
              onPressed: () async {
                await ApiService.updateMachine(
                    machine["_id"], nomController.text, etat);
                Navigator.pop(context);
                fetchMachinesParSalle();
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AjouterModeleAdmin(
                      machineId: machine["_id"],
                    ),
                  ),
                );
              },
              child: Text("Ajouter un modèle"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Machines par Salle")),
      body: machines.isEmpty
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: machines.length,
              itemBuilder: (context, index) {
                var machine = machines[index];
                return GestureDetector(
                  onTap: () => _showEditMachineDialog(machine),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(
                          int.parse(Machine.getEtatColor(machine["etat"]))),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          machine["nom"],
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        ElevatedButton(
                          onPressed: () => _showEditMachineDialog(machine),
                          child: Text("Modifier"),
                        ),
                        SizedBox(height: 5), // Ajoutez un petit espace
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            bool confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Confirmer la suppression"),
                                content: Text(
                                    "Voulez-vous vraiment supprimer cette machine ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      "Supprimer",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm) {
                              try {
                                await ApiService.deleteMachine(machine["_id"]);
                                setState(() {
                                  machines.removeAt(
                                      index); // Met à jour la liste sans recharger
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Machine supprimée")),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Erreur lors de la suppression")),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMachineDialog,
        child: Icon(Icons.add),
        tooltip: "Ajouter une machine",
      ),
    );
  }
}
