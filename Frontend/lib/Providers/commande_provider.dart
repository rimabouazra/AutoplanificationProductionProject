import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/commande.dart';

class CommandeProvider with ChangeNotifier {
  final String _baseUrl = "http://192.168.1.17:8080/Commande/add";

  Future<void> envoyerCommande(Commande commande) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(commande.toJson()),
      );

      if (response.statusCode == 201) {
        print("Commande envoyée avec succès");
      } else {
        print("Erreur lors de l'envoi de la commande: ${response.body}");
      }
    } catch (error) {
      print("Erreur de connexion: $error");
    }
  }
}
