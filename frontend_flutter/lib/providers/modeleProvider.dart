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


  Map<String, Modele> get modeleMap {
    return {for (var m in _modeles) m.id: m};
  }
  List<String> getTaillesByModele(String modeleNom) {
    final modele = _modeles.firstWhere((m) => m.nom == modeleNom, orElse: () => Modele(id: '', nom: '', tailles: []));
    return modele.tailles;
  }
}
