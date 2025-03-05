import 'package:flutter/material.dart';
import 'package:frontend/models/commande.dart';
import '../models/matiere.dart';
import '../services/api_service.dart';

class MatiereProvider with ChangeNotifier {
  List<Matiere> _matieres = [];

  List<Matiere> get matieres => _matieres;

  // Charger les matières depuis l'API
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
      await ApiService.addMatiere(matiere);
      await fetchMatieres();
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
      print(
          "Début de updateMatiere pour l'ID : $id avec quantité : $newQuantite"); //DEBUG
      final updatedMatiere = await ApiService.updateMatiere(id, newQuantite);
      print("Réponse de l'API (updateMatiere) : $updatedMatiere"); //DEBUG
      if (updatedMatiere != null) {
        int index = _matieres.indexWhere((m) => m.id == id);
        print("Index trouvé dans _matieres : $index"); //DEBUG
        if (index != -1) {
          _matieres[index] = updatedMatiere; // Met à jour la matière
          notifyListeners(); // Rafraîchit la liste
          print("Matière mise à jour avec succès !"); //DEBUG
        } else {
          print("Matière non trouvée dans la liste !"); //DEBUG
        }
      } else {
        print(
            "Erreur : L'API n'a pas retourné la matière mise à jour !"); //DEBUG
      }
    } catch (e) {
      print("Erreur de mise à jour : $e");
    }
  }

  Future<List<Historique>> fetchHistorique(String matiereId) async {
    try {
      final response = await ApiService.getHistoriqueMatiere(matiereId);
      print("Réponse reçue : $response");
      print("Type de la réponse : ${response.runtimeType}");
      if (response is List) {
        return response.map<Historique>((json) {
          if (json is Map<String, dynamic>) {
            return Historique.fromJson(json);
          } else {
            throw Exception("Format inattendu des données de l'historique !");
          }
        }).toList();
      } else {
        throw Exception("Format inattendu de la réponse API !");
      }
    } catch (e) {
      print("Erreur lors du chargement de l'historique : $e");
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> fetchCommandes() async {
  try {
    final List<Commande> commandes = await ApiService.getCommandes();
    return commandes.map((commande) {
      return commande.modeles.map((modele) {
        return {
          'id': commande.id,
          'modele': modele.nomModele,
          'taille': modele.taille, 
        };
      }).toList();
    }).expand((x) => x).toList();
  } catch (e) {
    print("Erreur lors du chargement des commandes : $e");
    return [];
  }
}
// Renommer une matière
Future<void> renameMatiere(String id, String newReference) async {
  try {
    final response = await ApiService.renameMatiere(id, newReference);
    if (response != null) {
      int index = _matieres.indexWhere((m) => m.id == id);
      if (index != -1) {
        _matieres[index] = Matiere(
          id: _matieres[index].id,
          reference: newReference,
          couleur: _matieres[index].couleur,
          quantite: _matieres[index].quantite,
          dateAjout: _matieres[index].dateAjout,
          historique: _matieres[index].historique,
        );
        notifyListeners(); // Rafraîchit la liste
      }
    }
  } catch (e) {
    print("Erreur lors du renommage de la matière : $e");
  }
}


}
