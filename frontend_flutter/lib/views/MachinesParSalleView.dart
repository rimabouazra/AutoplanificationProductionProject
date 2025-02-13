import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../services/api_service.dart'; // Service pour récupérer les données

class MachinesParSalleView extends StatefulWidget {
  final String salleId; 

  const MachinesParSalleView({Key? key, required this.salleId}) : super(key: key);

  @override
  _MachinesParSalleViewState createState() => _MachinesParSalleViewState();
}

class _MachinesParSalleViewState extends State<MachinesParSalleView> {
  List<dynamic> sallesAvecMachines = [];

  @override
  void initState() {
    super.initState();
    fetchMachinesParSalle();
  }

  Future<void> fetchMachinesParSalle() async {
  try {
    var data = await ApiService.fetchMachinesParSalle(widget.salleId); // Filtrer par salleId
    setState(() {
      sallesAvecMachines = data;
    });
  } catch (e) {
    print("Erreur lors du chargement des machines : $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Machines par Salle")),
      body: sallesAvecMachines.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: sallesAvecMachines.length,
              itemBuilder: (context, index) {
                var salleData = sallesAvecMachines[index];
                var salle = salleData["salle"];
                var machines = salleData["machines"];

                return Card(
                  margin: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          salle["nom"],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Affichage en grille (3 colonnes)
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: machines.length,
                          itemBuilder: (context, i) {
                            var machine = machines[i];
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
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
