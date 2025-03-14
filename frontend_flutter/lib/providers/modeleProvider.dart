import 'package:flutter/material.dart';
import '../models/modele.dart';
import '../services/api_service.dart';

class ModeleProvider with ChangeNotifier {
  List<Modele> _modeles = [];

  List<Modele> get modeles => _modeles;

  Future<void> fetchModeles() async {
    try {
      List<Modele> fetchedModeles = await ApiService.getModeles();
      _modeles = fetchedModeles;
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des modèles: $e");
    }
  }
   Future<void> addModele(String nom, List<String> tailles, String? base) async {
    try {
      await ApiService.addModele(nom, tailles, base);
      fetchModeles(); // Rafraîchir la liste des modèles
    } catch (e) {
      print("Erreur lors de l'ajout du modèle: $e");
    }
  }

  Map<String, Modele> get modeleMap {
    return {for (var m in _modeles) m.id: m};
  }
  List<String> getTaillesByModele(String modeleNom) {
    final modele = _modeles.firstWhere((m) => m.nom == modeleNom, orElse: () => Modele(id: '', nom: '', tailles: []));
    return modele.tailles;
  }
  Future<void> updateModele(String id, String nom, List<String> tailles, String? base) async {
  try {
    await ApiService.updateModele(id, nom, tailles, base);
    fetchModeles(); // Rafraîchir la liste des modèles
  } catch (e) {
    print("Erreur lors de la modification du modèle: $e");
  }
}

Future<void> deleteModele(String id) async {
  try {
    await ApiService.deleteModele(id);
    fetchModeles(); // Rafraîchir la liste des modèles
  } catch (e) {
    print("Erreur lors de la suppression du modèle: $e");
  }
}
}
