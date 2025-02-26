import 'package:flutter/material.dart';
import '../models/matiere.dart';
import '../services/api_service.dart';

class MatiereProvider with ChangeNotifier {
  List<Matiere> _matieres = [];

  List<Matiere> get matieres => _matieres;

  Future<void> fetchMatieres() async {
    try {
      final response = await ApiService.getMatieres();
      _matieres = response.map((json) => Matiere.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des matières : $e");
    }
  }

  // Ajouter une matière
  Future<void> addMatiere(Matiere matiere) async {
    try {
      final newMatiere = await ApiService.addMatiere(matiere);
      _matieres.add(Matiere.fromJson(newMatiere));
      notifyListeners();
    } catch (e) {
      print("Erreur lors de l'ajout de la matière : $e");
    }
  }

  // Supprimer une matière
  Future<void> deleteMatiere(String id) async {
    try {
      await ApiService.deleteMatiere(id);
      _matieres.removeWhere((matiere) => matiere.id == id);
      notifyListeners();
    } catch (e) {
      print("Erreur lors de la suppression de la matière : $e");
    }
  }
  Future<void> updateMatiere(String id, int newQuantite) async {
  try {
    final updatedMatiere = await ApiService.updateMatiere(id, newQuantite);
    if (updatedMatiere != null) {
      int index = _matieres.indexWhere((m) => m.id == id);
      if (index != -1) {
        _matieres[index] = updatedMatiere; // Met à jour la matière
        notifyListeners();
      }
    }
  } catch (e) {
    print("Erreur de mise à jour : $e");
  }
}

}
