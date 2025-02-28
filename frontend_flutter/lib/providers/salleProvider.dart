import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalleProvider with ChangeNotifier {
  List<dynamic> _salles = [];

  List<dynamic> get salles => _salles;

  Future<void> fetchSalles() async {
    try {
      _salles = await ApiService.getSalles();
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des salles : $e");
    }
  }

  // Ajouter une salle
  Future<void> ajouterSalle(String nom, String type) async {
    try {
      await ApiService.ajouterSalle(nom, type);
      await fetchSalles(); // Rafraîchir après ajout
    } catch (e) {
      print("Erreur lors de l'ajout de la salle : $e");
    }
  }

  // Modifier une salle
  Future<void> modifierSalle(String id, String nouveauNom) async {
    try {
      await ApiService.modifierSalle(id, nouveauNom);
      await fetchSalles(); // Rafraîchir après modification
    } catch (e) {
      print("Erreur lors de la modification de la salle : $e");
    }
  }

  // Supprimer une salle
  Future<void> supprimerSalle(String id) async {
    try {
      await ApiService.supprimerSalle(id);
      await fetchSalles();
    } catch (e) {
      print("Erreur lors de la suppression de la salle : $e");
    }
  }
}
