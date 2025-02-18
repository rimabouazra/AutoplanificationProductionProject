import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../services/api_service.dart';

class MachinesParSalleView extends StatefulWidget {
  final String salleId;
  const MachinesParSalleView({Key? key, required this.salleId}) : super(key: key);

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
      print("🔄 Chargement des machines pour salle: ${widget.salleId}");
      var data = await ApiService.fetchMachinesParSalle(widget.salleId);
      if (data.isNotEmpty) {
        setState(() {
          machines = data;
        });
      } else {
        print("⚠️ Aucune machine trouvée pour cette salle.");
      }
    } catch (e) {
      print("❌ Erreur lors du chargement des machines : $e");
    }
  }

  // ➕ Fonction pour afficher la boîte de dialogue et ajouter une machine
  Future<void> _showAddMachineDialog() async {
    TextEditingController nomController = TextEditingController();
    TextEditingController etatController = TextEditingController();
    TextEditingController modeleController = TextEditingController();
    TextEditingController tailleController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Ajouter une Machine"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: InputDecoration(labelText: "Nom de la machine"),
              ),
              TextField(
                controller: etatController,
                decoration: InputDecoration(labelText: "État (disponible, occupée, arrêtée)"),
              ),
              TextField(
                controller: modeleController,
                decoration: InputDecoration(labelText: "ID du modèle"),
              ),
              TextField(
                controller: tailleController,
                decoration: InputDecoration(labelText: "Taille"),
              ),
            ],
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
                String etat = etatController.text;
                String modele = modeleController.text;
                String taille = tailleController.text;

                if (nom.isNotEmpty && etat.isNotEmpty && modele.isNotEmpty && taille.isNotEmpty) {
                  await ApiService.addMachine(
                    nom: nom,
                    etat: etat,
                    salleId: widget.salleId,
                    modele: modele,
                    taille: taille,
                  );
                  Navigator.pop(context);
                  fetchMachinesParSalle(); // Rafraîchir la liste après ajout
                } else {
                  print("⚠️ Veuillez remplir tous les champs.");
                }
              },
            ),
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
                return Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse(Machine.getEtatColor(machine["etat"]))),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      machine["nom"],
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
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
