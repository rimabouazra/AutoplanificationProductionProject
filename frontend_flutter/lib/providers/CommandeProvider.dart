import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/machine.dart';
import 'package:frontend/models/salle.dart';
import 'package:frontend/providers/matiereProvider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/commande.dart';
import '../providers/client_provider.dart';
class CommandeProvider with ChangeNotifier {
  final String _baseUrl = "http://localhost:5000/api/commandes";

  List<Commande> _commandes = [];

  List<Commande> get commandes => _commandes;


  Future<bool> updateCommande(String commandeId, List<CommandeModele> updatedModeles) async {
    try {
      Commande? commandeExistante;
      try {
        commandeExistante = _commandes.firstWhere((cmd) => cmd.id == commandeId);
      } catch (e) {
        commandeExistante = null;
      }

      if (commandeExistante == null) {
        print("Commande non trouvée");
        return false;
      }

      for (int i = 0; i < updatedModeles.length; i++) {
        if (updatedModeles[i].modele == null || updatedModeles[i].modele!.isEmpty) {
          print("Récupération de l'ID pour le modèle: ${updatedModeles[i].nomModele}");
          String? modeleId = await getModeleId(updatedModeles[i].nomModele);
          if (modeleId != null) {
            updatedModeles[i].modele = modeleId;
          } else {
            print("Impossible de récupérer l'ID du modèle: ${updatedModeles[i].nomModele}");
            return false;
          }
        }
      }

      commandeExistante.modeles = updatedModeles;

      // Envoi au backend
      print("Envoi des données au backend : ${jsonEncode(updatedModeles)}");
      final response = await http.put(
        Uri.parse("$_baseUrl/$commandeId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": commandeExistante.client,
          "modeles": updatedModeles.map((modele) => {
            // Assure-toi que l'objet envoyé est conforme au format attendu par l'API
            "modele": modele.modele,
            "nomModele": modele.nomModele,
            "taille": modele.taille,
            "couleur": modele.couleur,
            "quantiteDemandee": modele.quantite,
          }).toList(),
          "conditionnement": commandeExistante.conditionnement,
          "delais": commandeExistante.delais?.toIso8601String(),
          "etat": commandeExistante.etat,
          "salleAffectee": commandeExistante.salleAffectee,
          "machinesAffectees": commandeExistante.machinesAffectees,
        }),
      );

      if (response.statusCode == 200) {
        _commandes = _commandes.map((commande) {
          return commande.id == commandeId ? commandeExistante! : commande;
        }).toList();

        notifyListeners();
        print("Commande mise à jour avec succès !");
        return true;
      } else {
        print("Erreur HTTP ${response.statusCode}: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Erreur updateCommande: $error");
      return false;
    }
  }

  Future<bool> deleteCommande(String id) async {
    try {
      final response = await http.delete(Uri.parse("$_baseUrl/$id"));

      if (response.statusCode == 200) {
        // Supprimer la commande localement sans recharger toute la liste
        _commandes.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      } else {
        print("Erreur suppression: ${response.body}");
        return false;
      }
    } catch (error) {
      print("Erreur réseau deleteCommande: $error");
      return false;
    }
  }


  Future<String?> getModeleId(String nomModele) async {
    print("Recherche du modèle pour nomModele: $nomModele");
    try {
      var response = await http.get(Uri.parse("http://localhost:5000/api/modeles/findByName/$nomModele"));

      // Vérifiez si la réponse est bien reçue
      print("Réponse HTTP: ${response.statusCode}");
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String? modeleId = data["_id"]?.toString(); // Vérifie aussi si ton backend utilise "_id" au lieu de "id"
        print("ID du modèle trouvé: $modeleId");
        return modeleId;
      } else {
        print("Erreur lors de la récupération du modèle: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur dans getModeleId: $e");
      return null;
    }
  }



  Future<String?> getModeleNom(String modeleId) async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/api/modeles/$modeleId"));

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
  Future<bool> updateCommandeEtat(String commandeId, String newEtat) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/$commandeId/etat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"etat": newEtat}),
      );

      if (response.statusCode == 200) {
        // Update the local state
        final index = _commandes.indexWhere((cmd) => cmd.id == commandeId);
        if (index != -1) {
          _commandes[index].etat = newEtat;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (error) {
      print("Erreur updateCommandeEtat: $error");
      return false;
    }
  }



  Future<bool> addCommande(Commande commande) async {

    final response = await http.post(
      Uri.parse("$_baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "client": commande.client,
        "modeles": commande.modeles.map((modele) => modele.toJson()).toList(),
        "conditionnement": commande.conditionnement,
        "delais": commande.delais?.toIso8601String(),
        "etat": commande.etat,
      }),
    );

    print("Statut HTTP: ${response.statusCode}");
    print("Réponse: ${response.body}");

    if (response.statusCode == 201) {
      // Add the new commande to the local list directly
      _commandes.add(commande);
      notifyListeners(); // Notify listeners to update the UI
      return true;
    } else {
      return false;
    }
  }


  Future<void> fetchCommandes() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        Iterable data = jsonDecode(response.body);
        _commandes = data.map((e) => Commande.fromJson(e)).toList();
        notifyListeners();
      } else {
        print("Erreur HTTP: ${response.statusCode}");
      }
    } catch (error) {
      print("Erreur lors de la récupération des commandes: $error");
    }
  }
  List<String> getClients() {
    return _commandes.map((c) => c.client.name).toSet().toList();
  }

  Future<List<Map<String, dynamic>>> fetchModeles() async {
    try {
      final response = await http.get(Uri.parse("http://localhost:5000/api/modeles"));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => {"id": e["_id"], "nom": e["nom"], "tailles": e["tailles"]}).toList();
      }
    } catch (e) {
      print("Erreur fetchModeles: $e");
    }
    return [];
  }
  Future<void> planifierCommande(BuildContext context, String commandeId, List<Salle> salles) async {
    final commande = _commandes.firstWhere((cmd) => cmd.id == commandeId);
    final matiereProvider = Provider.of<MatiereProvider>(context, listen: false);

    for (var modele in commande.modeles) {
      double besoin = modele.calculerBesoinMatiere();
      final matiere = matiereProvider.getMatiereByCouleur(modele.couleur);

      if (matiere != null && matiere.estStockSuffisant(besoin)) {
        bool estFoncee = modele.estCouleurFoncee(modele.couleur);

        for (var salle in salles) {
          if ((estFoncee && salle.nom == "Salle Noire") || (!estFoncee && salle.nom == "Salle Blanche")) {
            await affecterSalleEtMachines(commande, salle, salle.machines);
            break;
          }
        }
      } else {
        throw Exception("Stock insuffisant ou matière introuvable pour le modèle ${modele.nomModele}");
      }
    }
  }



  Future<void> affecterSalleEtMachines(Commande commande, Salle salle, List<Machine>? machines) async {
    if (salle.id == null || machines == null) {
      print("Erreur : Salle ou machines null");
      return;
    }

    commande.salleAffectee = salle.id!;
    commande.machinesAffectees = machines.map((m) => m.id!).toList();
    await updateCommande(commande.id!, commande.modeles);
  }


}
