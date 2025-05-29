import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
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
    try {
      final response = await http.get(Uri.parse('https://autoplanificationproductionproject.onrender.com/api/salles'));
      if (response.statusCode == 200) {
        setState(() {
          salles = json.decode(response.body);
        });
      } else {
        throw Exception('Échec du chargement des salles');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement des salles : $e"),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> ajouterSalle(String nom, String type) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://autoplanificationproductionproject.onrender.com/api/salles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"nom": nom, "type": type}),
      );

      if (response.statusCode == 201) {
        fetchSalles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Salle ajoutée avec succès !"),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception('Erreur lors de l\'ajout de la salle');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'ajout de la salle : $e"),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> modifierSalle(String id, String nouveauNom, String nouveauType) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('https://autoplanificationproductionproject.onrender.com/api/salles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "nom": nouveauNom,
          "type": nouveauType,
        }),
      );

      if (response.statusCode == 200) {
        fetchSalles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Salle modifiée avec succès !"),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception('Erreur lors de la modification de la salle');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la modification de la salle : $e"),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> supprimerSalle(String id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Utilisateur non authentifié');
      }

      final response = await http.delete(
        Uri.parse('https://autoplanificationproductionproject.onrender.com/api/salles/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchSalles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Salle supprimée avec succès !"),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception('Erreur lors de la suppression de la salle');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression : $e"),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void afficherDialogueSalle(
      {String? id, String? nomActuel, String? typeActuel, bool isModification = false}) {
    TextEditingController nomController = TextEditingController(text: nomActuel ?? "");
    String selectedType = typeActuel ?? "noir";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: FadeInDown(
                child: Text(
                  isModification ? "Modifier la salle" : "Ajouter une salle",
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInUp(
                      child: TextField(
                        controller: nomController,
                        decoration: InputDecoration(
                          labelText: "Nom de la salle",
                          prefixIcon: const Icon(Icons.meeting_room, color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      child: DropdownButtonFormField<String>(
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
                        decoration: InputDecoration(
                          labelText: "Type de salle",
                          prefixIcon: const Icon(Icons.category, color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler", style: TextStyle(color: Colors.blueGrey)),
                ),
                ZoomIn(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nomController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Veuillez entrer un nom pour la salle."),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }
                      if (isModification) {
                        modifierSalle(id!, nomController.text, selectedType);
                      } else {
                        ajouterSalle(nomController.text, selectedType);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isModification ? "Modifier" : "Ajouter",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void afficherConfirmationSuppression(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Confirmer la suppression",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          content: const Text("Voulez-vous vraiment supprimer cette salle ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler", style: TextStyle(color: Colors.blueGrey)),
            ),
            ZoomIn(
              child: ElevatedButton(
                onPressed: () async {
                  await supprimerSalle(id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la déconnexion",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.blueGrey)),
          ),
          ZoomIn(
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Déconnexion", style: TextStyle(color: Colors.white)),
            ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        final role = snapshot.data!;
        final isAdminOrManager = role == 'admin' || role == 'manager';

        return Scaffold(
          backgroundColor: Colors.blueGrey[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blueGrey[800],
            title: FadeInDown(
              child: const Text(
                "Liste des Salles",
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              FadeInRight(
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => _confirmLogout(context),
                ),
              ),
              if (isAdminOrManager)
                FadeInRight(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.blueGrey[600],
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => afficherDialogueSalle(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[50]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: salles.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: salles.length,
                    itemBuilder: (context, index) {
                      final salle = salles[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: Icon(Icons.meeting_room, color: Colors.blueGrey[800]),
                            title: Text(
                              salle['nom'],
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Type: ${salle['type'].toUpperCase()}",
                                  style: TextStyle(
                                    color: salle['type'] == 'noir' ? Colors.blueGrey[600] : Colors.blue,
                                  ),
                                ),
                                Text(
                                  "Nombre de machines: ${salle['machines'].length}",
                                  style: TextStyle(color: Colors.blueGrey[600]),
                                ),
                              ],
                            ),
                            trailing: isAdminOrManager
                                ? Wrap(
                                    spacing: 8,
                                    children: [
                                      ZoomIn(
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => afficherDialogueSalle(
                                            id: salle['_id'],
                                            nomActuel: salle['nom'],
                                            typeActuel: salle['type'],
                                            isModification: true,
                                          ),
                                        ),
                                      ),
                                      ZoomIn(
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => afficherConfirmationSuppression(salle['_id']),
                                        ),
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