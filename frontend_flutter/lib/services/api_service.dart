import 'dart:convert';
import 'package:frontend/models/matiere.dart';
import 'package:http/http.dart' as http;
import '../models/machine.dart';
import '../models/modele.dart';
import '../models/produits.dart';
import '../models/salle.dart';
import '../models/user.dart';
import '../models/planification.dart';
import '../models/commande.dart';

class ApiService {
  static const String baseUrl = "http://localhost:5000/api";

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
    final response = await http.post(
      Uri.parse('$baseUrl/machines/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "salle": salleId,
        "modele": modele,
        "taille": taille,
        "etat": "disponible",
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(
          "Erreur lors de l'ajout de la machine : ${response.body}");
    }
  }

  static Future<void> updateMachine(String id, String nom, String etat) async {
    await http.put(
      Uri.parse("$baseUrl/machines/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nom": nom, "etat": etat}),
    );
  }

  static Future<void> deleteMachine(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/machines/$id'));

    if (response.statusCode != 200) {
      throw Exception(
          "Erreur lors de la suppression de la machine : ${response.body}");
    }
  }

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
  static Future<void> addModele(String nom, List<String> tailles, String? base,
      List<Consommation> consommation) async {
    final response = await http.post(
      Uri.parse("$baseUrl/modeles/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "tailles": tailles,
        'base': base,
        if (consommation.isNotEmpty)
          'consommation': consommation.map((c) => c.toJson()).toList(),
        // Convertir la liste
      }),
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
        "etat": "occupee",
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<Salle>> getSalles() async {
    final response = await http.get(Uri.parse('$baseUrl/salles'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => Salle.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des salles");
    }
  }

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

  // Récupérer toutes les Planifications
  static Future<List<Planification>> getPlanifications() async {
    final response = await http.get(Uri.parse('$baseUrl/planifications/'));
    print("Réponse brute de l'API: ${response.body}"); // Log de débogage
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      print("Données JSON décodées: $jsonData"); // Log de débogage
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
        print('Erreur lors de la planification automatique : ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception: $e');
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

  static Future<void> deleteMatiere(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/matieres/$id'));
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de la matière");
    }
  }

  static Future<Matiere?> updateMatiere(String id, double newQuantite) async {
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
          .get(Uri.parse("http://localhost:5000/api/modeles/$modeleId"));

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
      print("Début de getModeleParNom avec nomModele: $nomModele");

      String? modeleId = await getModeleId(nomModele);
      print("Résultat de getModeleId: $modeleId");
      if (modeleId == null) {
        print("Erreur: Aucun ID trouvé pour le modèle '$nomModele'");
        return null;
      }
      String? modeleNom = await getModeleNom(modeleId);
      print("Résultat de getModeleNom: $modeleNom");
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
          "http://localhost:5000/api/modeles/findByName/$encodedNomModele"));

      print("Réponse HTTP: ${response.statusCode}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("Réponse du modèle : $data");

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
      String? base, List<Consommation> consommation) async {
    final response = await http.put(
      Uri.parse("$baseUrl/modeles/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nom": nom,
        "tailles": tailles,
        "base": base,
        'consommation': consommation.map((c) => c.toJson()).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Échec de la modification du modèle");
    }
  }

  static Future<void> deleteModele(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/modeles/$id"),
    );
    if (response.statusCode != 200) {
      throw Exception("Échec de la suppression du modèle");
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

    print("Envoi de la requête à $url");
    print("Body: $body");

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("Réponse HTTP: ${response.statusCode}");
      print("Body: ${response.body}");

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
}
