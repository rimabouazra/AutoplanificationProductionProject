import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/commande.dart'; // Gardez uniquement cette importation

class CommandeProvider with ChangeNotifier {
  final String _baseUrl = "http://192.168.1.17:5000/api/commandes";

  List<Commande> _commandes = [];

  List<Commande> get commandes => _commandes;

  Future<bool> addCommande(Commande commande) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(commande.toJson()),
      );

      if (response.statusCode == 201) {
        fetchCommandes();
        return true;
      } else {
        return false;
      }
    } catch (error) {
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
      }
    } catch (error) {
      print("Erreur lors de la récupération des commandes: $error");
    }
  }
}
