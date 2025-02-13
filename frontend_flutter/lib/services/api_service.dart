import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/machine.dart';
import '../models/modele.dart';
import '../models/salle.dart';
import '../models/user.dart';
import '../models/planification.dart';
import '../models/commande.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5000/api";

  // ✅ Récupérer toutes les Machines
  static Future<List<Machine>> getMachines() async {
    final response = await http.get(Uri.parse('$baseUrl/machines'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Machine.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des machines");
    }
  }

  // ✅ Ajouter une nouvelle Machine
  static Future<bool> addMachine(Machine machine) async {
    final response = await http.post(
      Uri.parse('$baseUrl/machines'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(machine.toJson()),
    );
    return response.statusCode == 201;
  }

  // ✅ Récupérer tous les Modèles
  static Future<List<Modele>> getModeles() async {
    final response = await http.get(Uri.parse('$baseUrl/modeles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Modele.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des modèles");
    }
  }

  // ✅ Ajouter un nouveau Modèle
  static Future<bool> addModele(Modele modele) async {
    final response = await http.post(
      Uri.parse('$baseUrl/modeles'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(modele.toJson()),
    );
    return response.statusCode == 201;
  }

  // ✅ Récupérer toutes les Salles
  static Future<List<Salle>> getSalles() async {
    final response = await http.get(Uri.parse('$baseUrl/salles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Salle.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des salles");
    }
  }

  // ✅ Ajouter une nouvelle Salle
  static Future<bool> addSalle(Salle salle) async {
    final response = await http.post(
      Uri.parse('$baseUrl/salles'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(salle.toJson()),
    );
    return response.statusCode == 201;
  }

  // ✅ Récupérer tous les Utilisateurs
  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des utilisateurs");
    }
  }

  // ✅ Ajouter un nouvel Utilisateur
  static Future<bool> addUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    return response.statusCode == 201;
  }

  // ✅ Récupérer toutes les Planifications
  static Future<List<Planification>> getPlanifications() async {
    final response = await http.get(Uri.parse('$baseUrl/planifications'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Planification.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des planifications");
    }
  }

  // ✅ Ajouter une nouvelle Planification
  static Future<bool> addPlanification(Planification planification) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planifications'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(planification.toJson()),
    );
    return response.statusCode == 201;
  }

  // ✅ Récupérer toutes les Commandes
  static Future<List<Commande>> getCommandes() async {
    final response = await http.get(Uri.parse('$baseUrl/commandes'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Commande.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des commandes");
    }
  }

  // ✅ Ajouter une nouvelle Commande
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
}
