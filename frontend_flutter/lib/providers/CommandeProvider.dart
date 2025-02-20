import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/commande.dart';
import '../models/modele.dart';
class CommandeProvider with ChangeNotifier {
  final String _baseUrl = "http://localhost:5000/api/commandes";

  List<Commande> _commandes = [];

  List<Commande> get commandes => _commandes;

  Future<bool> updateCommande(String commandeId, List<CommandeModele> updatedModeles) async {
    try {
      // Récupérer la commande existante dans la liste locale
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

      // Mise à jour des modèles localement
      commandeExistante.modeles = updatedModeles;

      // Envoi de la mise à jour au backend
      final response = await http.put(
        Uri.parse("$_baseUrl/$commandeId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client": commandeExistante.client,
          "modeles": commandeExistante.modeles.map((modele) => {
            "modele": modele.modele, // Ensure the modele ID is passed
            "taille": modele.taille,
            "couleur": modele.couleur,
            "quantite": modele.quantite,
          }).toList(),
          "conditionnement": commandeExistante.conditionnement,
          "delais": commandeExistante.delais?.toIso8601String(),
          "etat": commandeExistante.etat,
          "salleAffectee": commandeExistante.salleAffectee,
          "machinesAffectees": commandeExistante.machinesAffectees,
        }),
      );


      if (response.statusCode == 200) {
        // La commande a été mise à jour avec succès, on met à jour localement sans recharger
        _commandes = _commandes.map((commande) {
          return commande.id == commandeId ? commandeExistante! : commande;
        }).toList();

        notifyListeners(); // Notifier les widgets écoutant pour qu'ils se mettent à jour
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
      print("Fetching commandes depuis $_baseUrl");
      final response = await http.get(Uri.parse(_baseUrl));
      print("Statut HTTP: ${response.statusCode}");
      print("Réponse: ${response.body}");

      if (response.statusCode == 200) {
        Iterable data = jsonDecode(response.body);
        _commandes = data.map((e) => Commande.fromJson(e)).toList();
        print("Commandes récupérées: $_commandes");
        notifyListeners();
      } else {
        print("Erreur HTTP: ${response.statusCode}");
      }
    } catch (error) {
      print("Erreur lors de la récupération des commandes: $error");
    }
  }

}
