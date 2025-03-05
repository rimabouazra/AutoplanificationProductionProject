import 'dart:convert';
import 'package:frontend/models/matiere.dart';
import 'package:http/http.dart' as http;
import '../models/machine.dart';
import '../models/modele.dart';
import '../models/salle.dart';
import '../models/user.dart';
import '../models/planification.dart';
import '../models/commande.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5000/api";

  // Récupérer toutes les Machines
  static Future<List<Machine>> getMachines() async {
    final response = await http.get(Uri.parse('$baseUrl/machines'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Machine.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des machines");
    }
  }

  // Ajouter une nouvelle Machine
  static Future<void> addMachine(
      {required String nom,
      required String salleId,
      String? modele,
      String? taille}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/machines/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "salle": salleId,
        "modele": modele, // Peut être null
        "taille": taille // Peut être null
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(
          "Erreur lors de l'ajout de la machine : ${response.body}");
    }
  }

  //Mettre à jour une machine
  static Future<void> updateMachine(String id, String nom, String etat) async {
    await http.put(
      Uri.parse("$baseUrl/machines/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom, "etat": etat}),
    );
  }

  // Supprimer une machine
  static Future<void> deleteMachine(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/machines/$id'));

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la suppression de la machine : ${response.body}");
    }
  }

  // Récupérer tous les Modèles
  static Future<List<Modele>> getModeles() async {
    final response = await http.get(Uri.parse('$baseUrl/modeles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      print("Modèles récupérés: $jsonData"); // Debug des données reçues
      return jsonData.map((json) => Modele.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des modèles");
    }
  }

  // Ajouter un nouveau Modèle
  static Future<void> addModele(String nom, List<String> tailles) async {
    final response = await http.post(
      Uri.parse("$baseUrl/modeles/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom, "tailles": tailles}),
    );
    if (response.statusCode != 201) {
      throw Exception("Échec de l'ajout du modèle");
    }
  }

  static Future<bool> updateMachineModele(
      String machineId, String modeleId, String taille) async {
    final response = await http.put(
      Uri.parse('$baseUrl/machines/$machineId'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "modele": modeleId,
        "taille": taille,
      }),
    );

    return response.statusCode == 200;
  }

  // Récupérer toutes les Salles
  static Future<List<Salle>> getSalles() async {
    final response = await http.get(Uri.parse('$baseUrl/salles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Salle.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des salles");
    }
  }

  // Ajouter une nouvelle Salle
  static Future<bool> ajouterSalle(String nom, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salles'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom, "type": type}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> supprimerSalle(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/salles/$id'));
    return response.statusCode == 200;
  }

  static Future<bool> modifierSalle(String id, String nom) async {
    final response = await http.put(
      Uri.parse('$baseUrl/salles/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom}),
    );
    return response.statusCode == 200;
  }

  // Récupérer tous les Utilisateurs
  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des utilisateurs");
    }
  }

  // Ajouter un nouvel Utilisateur
  static Future<bool> addUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    return response.statusCode == 201;
  }

  // Récupérer toutes les Planifications
  static Future<List<Planification>> getPlanifications() async {
    final response = await http.get(Uri.parse('$baseUrl/planifications'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Planification.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des planifications");
    }
  }

  // Ajouter une nouvelle Planification
  static Future<bool> addPlanification(Planification planification) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planifications'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(planification.toJson()),
    );
    return response.statusCode == 201;
  }

  // Récupérer toutes les Commandes
  static Future<List<Commande>> getCommandes() async {
    final response = await http.get(Uri.parse('$baseUrl/commandes'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Commande.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des commandes");
    }
  }

  // Ajouter une nouvelle Commande
  static Future<bool> addCommande(Commande commande) async {
    final response = await http.post(
      Uri.parse('$baseUrl/commandes/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(commande.toJson()),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      print("Erreur lors de l'ajout de la commande: ${response.body}");
      return false;
    }
  }

  static Future<List<dynamic>> fetchMachinesParSalle(String salleId) async {
    final url =
        'http://localhost:5000/api/machines/parSalle/$salleId'; // Ajout de salleId
    print("🔍 Requête envoyée à: $url"); // Debug URL

    try {
      final response = await http.get(Uri.parse(url));

      print("Réponse API: ${response.statusCode}"); // Code de réponse
      print("Données brutes: ${response.body}"); // Debug JSON

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Données reçues: $data"); // Vérification de la structure
        return data; // Retourne directement la liste des machines
      } else {
        print("Erreur API: ${response.body}");
        throw Exception("Échec du chargement des machines");
      }
    } catch (e) {
      print("Erreur lors de la récupération des machines: $e");
      throw Exception("Erreur de connexion");
    }
  }

  static Future<List<Machine>> getMachinesParSalle(String salleId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/salles/$salleId/machines'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Machine.fromJson(json)).toList();
    } else {
      throw Exception(
          "Erreur lors de la récupération des machines pour la salle $salleId");
    }
  }

  // Récupérer les matières
  static Future<List<dynamic>> getMatieres() async {
    final response = await http.get(Uri.parse('$baseUrl/matieres'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors du chargement des matières");
    }
  }

  // Ajouter une matière
  static Future<Map<String, dynamic>> addMatiere(Matiere matiere) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matieres/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(matiere.toJson()),
    );
    print("Réponse API : ${response.statusCode} - ${response.body}");
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors de l'ajout de la matière");
    }
  }

  // Supprimer une matière
  static Future<void> deleteMatiere(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/matieres/$id'));
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de la matière");
    }
  }

  static Future<Matiere?> updateMatiere(String id, int newQuantite) async {
    final response = await http.put(
      Uri.parse('$baseUrl/matieres/update/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"quantite": newQuantite}),
    );

    if (response.statusCode == 200) {
      return Matiere.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }
  static Future<List<dynamic>> getHistoriqueMatiere(String matiereId) async {
  final response = await http.get(Uri.parse('$baseUrl/matieres/$matiereId/historique'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception("Erreur lors de la récupération de l'historique");
  }
}
static Future<Matiere?> renameMatiere(String id, String newReference) async {
  try {
    final response = await http.patch(
      Uri.parse('$baseUrl/matieres/$id/rename'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reference': newReference}),
    );

    if (response.statusCode == 200) {
      return Matiere.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Erreur lors du renommage de la matière");
    }
  } catch (e) {
    throw Exception("Erreur de connexion : $e");
  }
}
}
