import 'package:flutter/material.dart';
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
      setState(() {
        machines = data;
      });
    } catch (e) {
      print("Erreur lors du chargement des machines : $e");
    }
  }

  Future<void> _showAddMachineDialog() async {
    TextEditingController nomController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ajouter une Machine"),
          content: TextField(
            controller: nomController,
            decoration: InputDecoration(labelText: "Nom de la machine"),
          ),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Ajouter"),
              onPressed: () async {
                String nom = nomController.text;
                if (nom.isNotEmpty) {
                  await ApiService.addMachine(
                      nom: nom, salleId: widget.salleId);
                  Navigator.pop(context);
                  fetchMachinesParSalle();
                } else {
                  print("Veuillez remplir le champ.");
                }
              },
            ),
          ],
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
