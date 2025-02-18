import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/commande.dart'; // Gardez uniquement cette importation

class CommandeProvider with ChangeNotifier {
  final String _baseUrl = "http://localhost:5000/api/commandes";

  List<Commande> _commandes = [];

  List<Commande> get commandes => _commandes;

  Future<bool> updateCommande(Commande commande) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/${commande.id}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(commande.toJson()),
      );
      if (response.statusCode == 200) {
        fetchCommandes(); // Recharger les commandes après mise à jour
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }


  Future<bool> deleteCommande(String id) async {
    try {
      final response = await http.delete(Uri.parse("$_baseUrl/$id"));
      if (response.statusCode == 200) {
        fetchCommandes(); // Recharger les commandes après suppression
        return true;
      } else {
        return false;
      }
    } catch (error) {
      return false;
    }
  }

  Future<bool> addCommande(Commande commande) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "client": commande.client,
        "quantite": commande.quantite,
        "couleur": commande.couleur,
        "taille": commande.taille,
        "conditionnement": commande.conditionnement,
        "delais": commande.delais != null ? commande.delais!.toIso8601String() : null,
        "status": commande.status,
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
