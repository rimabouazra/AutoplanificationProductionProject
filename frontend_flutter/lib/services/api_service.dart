import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/models/matiere.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/machine.dart';
import '../models/modele.dart';
import '../models/produits.dart';
import '../models/salle.dart';
import '../models/user.dart';
import '../models/planification.dart';
import '../models/commande.dart';
import '../models/client.dart';

class ApiService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? "https://autoplanificationproductionproject.onrender.com";
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('Tentative de connexion avec email: $email');
      print('Full login URL: ${baseUrl}/api/users/login');
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'motDePasse': password,
        }),
      );
      print('Statut: ${response.statusCode}');
      print('Réponse brute: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'utilisateur': data['utilisateur'] ??
              data['user'] // Selon ce que retourne réellement l'API
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur inconnue'
        };
      }
    } catch (e, stackTrace) {
      print('Erreur lors de la connexion: $e');
      print('Full error: $e');
      print('Type: ${e.runtimeType}');
    print('Message: ${e.toString()}');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Erreur de connexion réseau: $e'};
    }
  }

  Future<Map<String, dynamic>?> register(
      String username, String email, String password) async {
    try {
      print('Tentative d\'inscription: $username, $email');

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/add'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nom': username,
          'email': email,
          'motDePasse': password,
        }),
      );

      print('Statut: ${response.statusCode}');
      print('Réponse brute: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'user': data};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur inconnue'
        };
      }
    } catch (e) {
      print('Erreur d\'inscription: $e');
      return {'success': false, 'message': 'Erreur de connexion réseau'};
    }
  }

  static Future<List<Machine>> getMachines() async {
    final response = await http.get(Uri.parse('$baseUrl/machines'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Machine.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des machines");
    }
  }

  static Future<void> addMachine(
      {required String nom,
      required String salleId,
      String? modele,
      String? taille}) async {
    final token = await AuthService.getToken();
    print('Token utilisé pour la requête: ${token?.substring(0, 10)}...');
    final response = await http.post(
      Uri.parse('$baseUrl/machines/add'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nom": nom,
        "salle": salleId,
        "modele": modele,
        "taille": taille,
        "etat": "disponible",
      }),
    );
    print('Réponse API - Status: ${response.statusCode}');
    print('Réponse API - Body: ${response.body}');
    if (response.statusCode != 201) {
      throw Exception(
          "Erreur lors de l'ajout de la machine : ${response.body}");
    }
  }

  static Future<void> updateMachine(String id, String nom, String etat) async {
    final token = await AuthService.getToken();
    if (etat != "occupee") {
      final hasPlanification = await hasActivePlanification(id);
      if (hasPlanification) {
        throw Exception(
            "Cette machine est occupée dans une planification active.");
      }
    }
    await http.put(
      Uri.parse("$baseUrl/machines/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"nom": nom, "etat": etat}),
    );
  }

  static Future<void> deleteMachine(String id) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/machines/$id'),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la suppression de la machine : ${response.body}");
    }
  }

  static Future<List<Modele>> getModeles() async {
    final response = await http.get(Uri.parse('$baseUrl/modeles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      //print("Modèles récupérés: $jsonData"); // Debug des données reçues
      return jsonData.map((json) => Modele.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des modèles");
    }
  }

  // Ajouter un nouveau Modèle
  static Future<void> addModele(String nom, List<String> tailles,
      List<String>? bases, List<Consommation> consommation, String? description,
      [List<TailleBase> taillesBases = const []]) async {
    final response = await http.post(
      Uri.parse("$baseUrl/modeles/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "tailles": tailles,
        'bases': bases ?? [],
        if (consommation.isNotEmpty)
          'consommation': consommation.map((c) => c.toJson()).toList(),
        // Convertir la liste
        "taillesBases": taillesBases.map((tb) => tb.toJson()).toList(),
        'description': description,
      }),
    );
    print("Requête envoyée : ${jsonEncode({
          'nom': nom,
          'tailles': tailles,
          'bases': bases ?? [],
          'consommation': consommation.map((c) => c.toJson()).toList(),
          'taillesBases': taillesBases.map((tb) => tb.toJson()).toList(),
          'description': description,
        })}"); //debug
    print(
        "Réponse de l'API: ${response.statusCode} - ${response.body}"); //debug
    if (response.statusCode != 201) {
      throw Exception("Échec de l'ajout du modèle: ${response.body}");
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
        "etat": "occupee",
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Salle>> getSalles() async {
    final response = await http.get(Uri.parse('$baseUrl/salles'));
    print('Raw API response for getSalles: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      print('Parsed salles data: $jsonData');
      return jsonData.map((json) => Salle.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des salles");
    }
  }

  static Future<bool> ajouterSalle(String nom, String type) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/salles'),
      headers: {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json"
      },
      body: jsonEncode({"nom": nom, "type": type}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> supprimerSalle(String id) async {
    try {
      final token = await AuthService.getToken();
      print('🔑 Token utilisé: $token');
      if (token == null) {
        // Essayez de récupérer le token depuis SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final fallbackToken = prefs.getString('token');
        print('🔍 Token de fallback: $fallbackToken');

        if (fallbackToken == null) {
          throw Exception('Aucun token disponible');
        }
        // Réessayez avec le token de fallback
        return supprimerSalle(id); // Rappel récursif
      }

      final url = Uri.parse('$baseUrl/salles/$id');
      final request = http.Request("DELETE", url);
      request.headers.addAll({
        'authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔍 Status code: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200) return true;

      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Échec de la suppression');
    } catch (e) {
      print('🔥 Erreur lors de la suppression: $e');
      return false;
    }
  }

  static Future<bool> modifierSalle(String id, String nom) async {
    final response = await http.put(
      Uri.parse('$baseUrl/salles/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom}),
    );
    return response.statusCode == 200;
  }

  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des utilisateurs");
    }
  }

  static Future<bool> addUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateUser(String id, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(user.toJson()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteUser(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'));
    return response.statusCode == 200;
  }

  static Future<List<Planification>> getPlanifications() async {
    final response = await http.get(Uri.parse('$baseUrl/planifications/'));
    //print("Réponse brute de l'API fetch plan: ${response.body}"); // Log de débogage
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      //print("Données JSON décodées: $jsonData"); // Log de débogage
      return jsonData.map((json) => Planification.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des planifications");
    }
  }

  static Future<bool> autoPlanifierCommande(String commandeId) async {
    final url = Uri.parse('$baseUrl/planifications/auto');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "commandeId": commandeId,
        }),
      );

      if (response.statusCode == 201) {
        print('Planification réussie');
        return true;
      } else {
        print(
            'Erreur lors de la planification automatique : ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getPlanificationPreview(
      String commandeId) async {
    final uri = Uri.parse('$baseUrl/planifications/auto');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'commandeId': commandeId, 'preview': true}),
    );

    print('📩 getPlanificationPreview status: ${response.statusCode}');
    print('📩 Body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return {
        'planifications': (jsonData['planifications'] as List<dynamic>?)
                ?.map((json) => Planification.fromJson(json))
                .toList() ??
            [],
        'statut': jsonData['statut'] ?? 'planifiée'
      };
    } else {
      throw Exception('Erreur lors de la récupération des prévisualisations');
    }
  }

  static Future<bool> confirmerPlanification(
      List<Planification> planifications) async {
    try {
      if (planifications.isEmpty) return false;

      // Log planifications for debugging
      debugPrint('Planifications to confirm: ${planifications.length}');
      planifications.forEach((p) {
        debugPrint(
            'Planification: id=${p.id}, statut=${p.statut}, machines=${p.machines.length}');
      });

      final response = await http.post(
        Uri.parse('$baseUrl/planifications/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'planifications': planifications.map((p) => p.toJson()).toList(),
        }),
      );

      debugPrint('Status confirmation: ${response.statusCode}');
      debugPrint('Body confirmation: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Exception in confirmerPlanification: $e');
      return false;
    }
  }

  static Future<bool> addPlanification(Planification planification) async {
    final response = await http.post(
      Uri.parse('$baseUrl/planifications/'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(planification.toJson()),
    );
    return response.statusCode == 201;
  }

  static Future<List<Commande>> getCommandes() async {
    final response = await http.get(Uri.parse('$baseUrl/commandes'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Commande.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des commandes");
    }
  }

  static Future<Map<String, dynamic>> addCommande(Commande commande) async {
    final response = await http.post(
      Uri.parse('$baseUrl/commandes/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(commande.toJson()),
    );

    if (response.statusCode == 201) {
      final commandeData = jsonDecode(response.body);
      final commandeId = commandeData['_id'];
      // Obtenir la prévisualisation de la planification
      final planificationResponse = await http.post(
        Uri.parse('$baseUrl/planifications/auto'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "commandeId": commandeId,
          "preview": true,
        }),
      );

      if (planificationResponse.statusCode == 200) {
        final planificationData = jsonDecode(planificationResponse.body);
        return {
          'success': true,
          'commandeId': commandeId,
          'planifications': (planificationData['planifications'] as List)
              .map((json) => Planification.fromJson(json))
              .toList(),
          'hasInsufficientStock':
              planificationData['hasInsufficientStock'] ?? false,
          'partialAvailable': planificationData['partialAvailable'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la prévisualisation de la planification',
        };
      }
    } else {
      print("Erreur lors de l'ajout de la commande: ${response.body}");
      return {'success': false, 'message': response.body};
    }
  }

  static Future<List<dynamic>> fetchMachinesParSalle(String salleId) async {
    final url =
        '$baseUrl/machines/parSalle/$salleId'; // Ajout de salleId
    // print("🔍 Requête envoyée à: $url"); // Debug URL

    try {
      final response = await http.get(Uri.parse(url));

      //print("Réponse API: ${response.statusCode}"); // Code de réponse
      // print("Données brutes: ${response.body}"); // Debug JSON

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // print("Données reçues: $data"); // Vérification de la structure
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

  static Future<Map<String, dynamic>> addMatiere(Matiere matiere) async {
    final response = await http.post(
      Uri.parse('$baseUrl/matieres/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(matiere.toJson()),
    );
    // print("Réponse API : ${response.statusCode} - ${response.body}");
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors de l'ajout de la matière");
    }
  }

  static Future<void> deleteMatiere(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/matieres/$id'));
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de la matière");
    }
  }

  static Future<Matiere?> updateMatiere(String id, double newQuantite,
      {String? action}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/matieres/update/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "quantite": newQuantite,
          if (action != null) "action": action,
        }),
      );

      print("Requête API - URL: $baseUrl/matieres/update/$id");
      print("Requête API - Body envoyé: ${jsonEncode({
            "quantite": newQuantite,
            if (action != null) "action": action,
          })}");
      print("Réponse API - Status: ${response.statusCode}");
      print("Réponse API - Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData != null) {
          return Matiere.fromJson(responseData);
        }
        print("Erreur : responseData est null");
        return null;
      } else {
        print("Erreur API - Status: ${response.statusCode}");
        print("Erreur API - Body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau lors de la mise à jour: $e");
      return null;
    }
  }

  static Future<List<Historique>> getHistoriqueMatiere(String matiereId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/matieres/historique/$matiereId'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) {
        if (json is Map<String, dynamic>) {
          return Historique.fromJson(json);
        } else {
          throw Exception("Format de données invalide : $json");
        }
      }).toList();
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

  static Future<List<Produit>> getProduits() async {
    final response = await http.get(Uri.parse('$baseUrl/produits'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      //print(
      //  "Produits récupérés : $jsonData"); // Ajouter un print pour vérifier la réponse

      return jsonData.map((json) => Produit.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des produits");
    }
  }

  static Future<void> addProduit(Produit produit) async {
    final response = await http.post(
      Uri.parse('$baseUrl/produits/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(produit.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception("Erreur lors de l'ajout du produit : ${response.body}");
    }
  }

  static Future<void> updateProduit(
      String id, Map<String, dynamic> produitData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/produits/update/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(produitData), // On envoie tout l'objet JSON
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la mise à jour du produit : ${response.body}");
    }
  }

  static Future<void> deleteProduit(String id) async {
    final response =
        await http.delete(Uri.parse('$baseUrl/produits/delete/$id'));
    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la suppression du produit : ${response.body}");
    }
  }

  Future<String?> getModeleNom(String modeleId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/modeles/$modeleId"));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data["nom"];
      } else {
        print("Erreur récupération nom modèle: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur getModeleNom: $e");
      return null;
    }
  }

  Future<Modele?> getModeleParNom(String nomModele) async {
    try {
      // print("Début de getModeleParNom avec nomModele: $nomModele");

      String? modeleId = await getModeleId(nomModele);
      // print("Résultat de getModeleId: $modeleId");
      if (modeleId == null) {
        print("Erreur: Aucun ID trouvé pour le modèle '$nomModele'");
        return null;
      }
      String? modeleNom = await getModeleNom(modeleId);
      // print("Résultat de getModeleNom: $modeleNom");
      if (modeleNom == null) {
        print("Erreur: Aucun nom trouvé pour le modèle ID '$modeleId'");
        return null;
      }

      Modele modele =
          Modele(id: modeleId, nom: modeleNom, tailles: [], consommation: []);
      print("Modele construit avec succès: ${modele.id}, ${modele.nom}");
      return modele;
    } catch (e) {
      print("Erreur dans getModeleParNom: $e");
      return null;
    }
  }

  Future<String?> getModeleId(String nomModele) async {
    print("Recherche du modèle pour nomModele: $nomModele");
    try {
      // Make sure the model name is URL-encoded to handle special characters
      String encodedNomModele = Uri.encodeComponent(nomModele);
      var response = await http.get(Uri.parse(
          "$baseUrl/modeles/findByName/$encodedNomModele"));

      print("Réponse HTTP: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // print("Réponse du modèle : $data");

        if (data["_id"] != null) {
          String? modeleId = data["_id"].toString();
          print("ID du modèle trouvé: $modeleId");
          return modeleId;
        } else {
          print("Aucun ID trouvé dans la réponse.");
          return null;
        }
      } else {
        print(
            "Erreur lors de la récupération du modèle: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur dans getModeleId: $e");
      return null;
    }
  }

  static Future<void> updateModele(String id, String nom, List<String> tailles,
      String? base, List<Consommation> consommation,
      [List<TailleBase> taillesBases = const [],String? description]) async {
    final response = await http.put(
      Uri.parse("$baseUrl/modeles/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "tailles": tailles,
        "base": base,
        'consommation': consommation.map((c) => c.toJson()).toList(),
        'taillesBases': taillesBases.map((tb) => tb.toJson()).toList(),
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Échec de la modification du modèle");
    }
  }

  static Future<void> deleteModele(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/modeles/delete/$id"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return; // Suppression réussie
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(
              errorData['message'] ?? "Échec de la suppression du modèle");
        } catch (_) {
          throw Exception("Échec de la suppression: ${response.body}");
        }
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Erreur de connexion: $e");
    }
  }

  static Future<bool> updateConsommation(
      String modeleId, String taille, double quantite) async {
    final url = Uri.parse('$baseUrl/modeles/$modeleId/consommation');

    final body = jsonEncode({
      "modeleId": modeleId,
      "taille": taille,
      "quantite": quantite,
    });

    //print("Envoi de la requête à $url");
    //print("Body: $body");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      //print("Réponse HTTP: ${response.statusCode}");
      //print("Body: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Erreur: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return false;
    }
  }

  static Future<void> addTailleToProduit(
      String produitId, Map<String, dynamic> tailleData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/produits/$produitId/addTaille'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(tailleData),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de l'ajout de la taille : ${response.body}");
    }
  }

  static Future<void> deleteTailleFromProduit(
      String produitId, int tailleIndex) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/produits/$produitId/deleteTaille/$tailleIndex'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la suppression de la taille : ${response.body}");
    }
  }

  static Future<bool> approveUser(String id, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/approve/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> rejectUser(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/reject/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<List<Client>> getClients() async {
    final response = await http.get(Uri.parse('$baseUrl/clients'));
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((e) => Client.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }

  static Future<Client> addClient(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/clients'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Client.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add client');
    }
  }

  Future<void> updateQuantiteReelle(
      String commandeId, String modeleId, int quantiteReelle) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/commandes/$commandeId/modele/$modeleId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quantiteReelle': quantiteReelle}),
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de la mise à jour de la quantité réelle');
    }
  }

  static Future<List<Planification>> getWaitingPlanifications(
      {String? commandeId}) async {
    final uri = commandeId != null
        ? Uri.parse(
            '$baseUrl/planifications/get/waiting?commandeId=$commandeId')
        : Uri.parse('$baseUrl/planifications/get/waiting');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Planification.fromJson(json)).toList();
    } else {
      throw Exception(
          "Erreur lors de la récupération des planifications en attente");
    }
  }

  static Future<bool> hasActivePlanification(String machineId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/planifications/active/$machineId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasActivePlanification'] ?? false;
      } else {
        throw Exception("Erreur lors de la vérification des planifications");
      }
    } catch (e) {
      print("Erreur lors de la vérification des planifications: $e");
      throw Exception("Erreur de connexion");
    }
  }

  static Future<void> updateWaitingPlanificationOrder(
      List<String?> order) async {
    try {
      final token = await AuthService.getToken();

      final response = await http.put(
        Uri.parse('$baseUrl/planifications/waiting/order'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"orderedIds": order}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            "Erreur lors de la mise à jour de l'ordre des planifications en attente: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print('Error in updateWaitingPlanificationOrder: $e');
      throw Exception(
          "Erreur lors de la mise à jour de l'ordre des planifications en attente: $e");
    }
  }
  static Future<Map<String, dynamic>> terminerPlanification(String planificationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Aucun token disponible');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/planifications/terminate/$planificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Terminer Planification - Status: ${response.statusCode}');
      debugPrint('Terminer Planification - Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'planification': Planification.fromJson(jsonData['planification']),
          'message': jsonData['message'],
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la terminaison de la planification',
        };
      }
    } catch (e) {
      debugPrint('Erreur dans terminerPlanification: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
