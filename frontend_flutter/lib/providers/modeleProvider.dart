import 'package:flutter/material.dart';
import '../models/modele.dart';
import '../services/api_service.dart'; // Service pour récupérer les modèles

class ModeleProvider with ChangeNotifier {
  List<Modele> _modeles = [];

  List<Modele> get modeles => _modeles;

  Future<void> fetchModeles() async {
    try {
      List<Modele> fetchedModeles = await ApiService.getModeles(); // Récupérer depuis le backend
      _modeles = fetchedModeles;
      notifyListeners(); // Met à jour l'UI
    } catch (e) {
      print("Erreur lors du chargement des modèles: $e");
    }
  }

  /// Convertit la liste en un `Map` pour une recherche rapide par ID
  Map<String, Modele> get modeleMap {
    return {for (var m in _modeles) m.id: m};
  }
}
