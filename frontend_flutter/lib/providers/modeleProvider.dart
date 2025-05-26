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
   Future<void> addModele(String nom, List<String> tailles, List<String>? bases, List<Consommation> consommation,[List<TailleBase> taillesBases = const []]) async {
    try {
      await ApiService.addModele(nom, tailles, bases, consommation, taillesBases);
      fetchModeles(); // Rafraîchir la liste des modèles
    } catch (e) {
      print("Erreur lors de l'ajout du modèle: $e");
    }
  }

  Map<String, Modele> get modeleMap {
    return {for (var m in _modeles) m.id: m};
  }
  List<String> getTaillesByModele(String modeleNom) {
    final modele = _modeles.firstWhere((m) => m.nom == modeleNom, orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []));
    return modele.tailles;
  }
  Future<void> updateModele(String id, String nom, List<String> tailles, String? base, List<Consommation> consommation,[List<TailleBase> taillesBases = const []]) async {
  try {
    await ApiService.updateModele(id, nom, tailles, base, consommation, taillesBases);
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
Future<void> updateConsommation(String modeleId, String taille, double quantite) async {
  try {
    print("Mise à jour de la consommation...");
    print("ModeleID: $modeleId, Taille: $taille, Quantité: $quantite");

    bool success = await ApiService.updateConsommation(modeleId, taille, quantite);
    
    if (success) {
      print("Mise à jour réussie !");
      await fetchModeles(); // Rafraîchir les modèles après modification
    } else {
      print("Échec de la mise à jour !");
    }
  } catch (e) {
    print("Erreur lors de la mise à jour de la consommation: $e");
  }
}


}
