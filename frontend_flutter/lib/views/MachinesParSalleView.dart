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

    try {
      modeles = await ApiService.getModeles();
    } catch (e) {
      print("Erreur lors du chargement des modèles : $e");
    }
    if (modeles.isEmpty) {
      print("Aucun modèle disponible !");
    }
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: Center(
                child: Text(
                  "Ajouter une Machine",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: InputDecoration(
                        labelText: "Nom de la machine",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Annuler", style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text("Ajouter", style: TextStyle(color: Colors.white)),
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

  Future<void> _confirmDeleteMachine(dynamic machine) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Confirmer la suppression"),
        content: Text("Voulez-vous vraiment supprimer cette machine ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Annuler", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        await ApiService.deleteMachine(machine["_id"]);
        setState(() {
          machines.removeWhere((m) => m["_id"] == machine["_id"]);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la suppression")));
      }
    }
  }

  Future<void> _showEditMachineDialog(dynamic machine) async {
    TextEditingController nomController =
        TextEditingController(text: machine["nom"]);
    String etat = machine["etat"] ?? "disponible";
    String modele = machine["modele"]?["nom"] ?? "Aucun modèle";
    String taille = machine["taille"] ?? "Aucune taille";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Center(
            child: Text(
              "Modifier la Machine",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(
                  labelText: "Nom de la machine",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: etat,
                onChanged: (String? newValue) async {
                  setState(() {
                    etat = newValue!;
                  });
                  try {
                    await ApiService.updateMachine(
                        machine["_id"], nomController.text, etat);
                    // Mettre à jour l'état localement
                    setState(() {
                      machine["etat"] = etat;
                    });
                  } catch (e) {
                    print("Erreur lors de la mise à jour de l'état : $e");
                  }
                },
                items: ["disponible", "occupee", "arretee"].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              if (etat == "occupee")
                Column(
                  children: [
                    SizedBox(height: 10),
                    Text("Modèle associé: $modele"),
                    Text("Taille: $taille"),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Annuler", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text("Enregistrer", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await ApiService.updateMachine(
                    machine["_id"], nomController.text, etat);
                setState(() {
                  machine["etat"] = etat;
                });
                Navigator.pop(context);
                fetchMachinesParSalle();
              },
            ),
            if (etat == "disponible")
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
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
                child: Text("Ajouter un modèle",
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Machines par Salle",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 163, 228, 215),
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: machines.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: machines.length,
                itemBuilder: (context, index) {
                  var machine = machines[index];
                  return _buildMachineCard(machine);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMachineDialog,
        backgroundColor: Color(0xFF1ABC9C),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Ajouter une machine",
      ),
    );
  }

  Widget _buildMachineCard(dynamic machine) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditMachineDialog(machine),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.computer,
                size: 40,
                color: Color(int.parse(Machine.getEtatColor(machine["etat"]))),
              ),
              SizedBox(height: 8),
              Text(
                machine["nom"],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => _showEditMachineDialog(machine),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _confirmDeleteMachine(machine),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
