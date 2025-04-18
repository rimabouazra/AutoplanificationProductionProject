import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'MachinesParSalleView.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<String?> _getUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('role');
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
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/salles'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
        final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse('http://localhost:5000/api/salles/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "nom": nouveauNom,
        "type": nouveauType,
      }),
    );
    print(
        "Réponse du serveur: ${response.statusCode} - ${response.body}"); // DEBUG
    if (response.statusCode == 200) {
      fetchSalles(); // Rafraîchir la liste après la modification
    } else {
      throw Exception('Erreur lors de la modification de la salle');
    }
  }

  // Supprimer une salle
  Future<void> supprimerSalle(String id) async {
  try {
    print('🔍 Tentative de suppression de salle $id');
    final token = await AuthService.getToken();
    print('🔑 Token récupéré: ${token != null ? "présent" : "absent"}');
    
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/salles/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('🔄 Réponse du serveur: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      fetchSalles();
    } else {
      throw Exception('Erreur lors de la suppression de la salle: ${response.body}');
    }
  } catch (e) {
    print('🔥 Erreur dans supprimerSalle: $e');
    throw e;
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
                        selectedType = newValue ?? "noir";
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
                      modifierSalle(id!, nomController.text, selectedType);
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
            onPressed: () async {
              try {
                await supprimerSalle(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salle supprimée avec succès')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
          ],
        );
      },
    );
  }
  void _confirmLogout(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Confirmer la déconnexion"),
      content: Text("Voulez-vous vraiment vous déconnecter ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Annuler"),
        ),
        TextButton(
          onPressed: () async {
            await AuthService.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: Text("Déconnexion", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        final role = snapshot.data!;
        final isAdminOrManager = role == 'admin' || role == 'manager';

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
      icon: Icon(Icons.logout),
      onPressed: () => _confirmLogout(context),
    ),
              if (isAdminOrManager)
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    backgroundColor: Color(0xFF1ABC9C),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => afficherDialogueSalle(),
                    ),
                  ),
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF4F6F7), Colors.white],
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
                          leading: const Icon(Icons.meeting_room, color: Color(0xFF1ABC9C)),
                          title: Text(
                            salle['nom'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Type : ${salle['type'].toUpperCase()}",
                                style: TextStyle(
                                  color: salle['type'] == 'noir' ? Colors.black : Color(0xFF3498DB)),
                              ),
                              Text(
                                "Nombre de machines: ${salle['machines'].length}",
                                style: TextStyle(color: Color(0xFF7F8C8D)),
                              ),
                            ],
                          ),
                          trailing: isAdminOrManager
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Color(0xFF3498DB)),
                                      onPressed: () => afficherDialogueSalle(
                                        id: salle['_id'],
                                        nomActuel: salle['nom'],
                                        typeActuel: salle['type'],
                                        isModification: true,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                      onPressed: () => afficherConfirmationSuppression(salle['_id']),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MachinesParSalleView(salleId: salle['_id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}