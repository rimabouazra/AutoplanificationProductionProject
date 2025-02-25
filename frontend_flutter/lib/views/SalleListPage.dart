import 'package:flutter/material.dart';
import 'MachinesParSalleView.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalleListPage extends StatefulWidget {
  const SalleListPage({Key? key}) : super(key: key);

  @override
  _SalleListPageState createState() => _SalleListPageState();
}

class _SalleListPageState extends State<SalleListPage> {
  List salles = [];

  @override
  void initState() {
    super.initState();
    fetchSalles();
  }

  Future<void> fetchSalles() async {
    final response =
        await http.get(Uri.parse('http://localhost:5000/api/salles'));

    if (response.statusCode == 200) {
      setState(() {
        salles = json.decode(response.body);
        print("Salles mises à jour: $salles"); // DEBUG
      });
    } else {
      throw Exception('Échec du chargement des salles');
    }
  }

  // Ajouter une salle
  Future<void> ajouterSalle(String nom, String type) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/salles'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom, "type": type}),
    );

    if (response.statusCode == 201) {
      fetchSalles(); // Rafraîchir la liste après l'ajout
    } else {
      print("Erreur lors de l'ajout de la salle: ${response.body}"); //DEBUG
      throw Exception('Erreur lors de l\'ajout de la salle');
    }
  }

  // Modifier une salle
  Future<void> modifierSalle(
      String id, String nouveauNom, String nouveauType) async {
    final response = await http.put(
      Uri.parse('http://localhost:5000/api/salles/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nouveauNom,
        "type": nouveauType,
      }),
    );
  print("Réponse du serveur: ${response.statusCode} - ${response.body}"); // DEBUG
    if (response.statusCode == 200) {
      fetchSalles(); // Rafraîchir la liste après la modification
    } else {
      throw Exception('Erreur lors de la modification de la salle');
    }
  }

  // Supprimer une salle
  Future<void> supprimerSalle(String id) async {
    final response =
        await http.delete(Uri.parse('http://localhost:5000/api/salles/$id'));

    if (response.statusCode == 200) {
      fetchSalles(); // Rafraîchir la liste après la suppression
    } else {
      throw Exception('Erreur lors de la suppression de la salle');
    }
  }

  // Afficher le dialogue pour ajouter/modifier une salle
  void afficherDialogueSalle(
      {String? id,
      String? nomActuel,
      String? typeActuel,
      bool isModification = false}) {
    TextEditingController nomController =
        TextEditingController(text: nomActuel ?? "");
    String selectedType = typeActuel ?? "noir"; // Valeur par défaut

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // Ajout de StatefulBuilder pour la mise à jour du DropdownButton
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                  isModification ? "Modifier la salle" : "Ajouter une salle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomController,
                    decoration:
                        const InputDecoration(labelText: "Nom de la salle"),
                  ),
                  const SizedBox(height: 10), // Espacement
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: ["noir", "blanc"].map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedType = newValue?? "noir";
                      });
                    },
                    decoration:
                        const InputDecoration(labelText: "Type de salle"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isModification) {
                      modifierSalle(id!, nomController.text,
                          selectedType);
                    } else {
                      ajouterSalle(nomController.text, selectedType);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isModification ? "Modifier" : "Ajouter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Afficher le dialogue de confirmation de suppression
  void afficherConfirmationSuppression(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Voulez-vous vraiment supprimer cette salle ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                supprimerSalle(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Supprimer"),
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
        title: const Text('Liste des Salles'),
        backgroundColor: const Color.fromARGB(255, 35, 99, 132),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => afficherDialogueSalle(), // Ajouter une salle
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900,
              const Color.fromARGB(255, 69, 129, 157)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: salles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: salles.length,
                itemBuilder: (context, index) {
                  final salle = salles[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.meeting_room,
                          color: Color.fromARGB(255, 116, 162, 185)),
                      title: Text(
                        salle['nom'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Type : ${salle['type'].toUpperCase()}", // Affichage du type de salle
                            style: TextStyle(
                                color: salle['type'] == 'noir'
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                          Text(
                            "Nombre de machines: ${salle['machines'].length}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => afficherDialogueSalle(
                              id: salle['_id'],
                              nomActuel: salle['nom'],
                              typeActuel: salle['type'],
                              isModification: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                afficherConfirmationSuppression(salle['_id']),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MachinesParSalleView(salleId: salle['_id']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
