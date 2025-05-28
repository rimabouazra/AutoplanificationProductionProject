import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/commande.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
Future<void> updateMatiere(String id, double newQuantite, {String? action}) async {
  try {
    print("Début de updateMatiere pour l'ID : $id avec quantité : $newQuantite, action : $action");
    final updatedMatiere = await ApiService.updateMatiere(id, newQuantite, action: action);
    print("Réponse de l'API (updateMatiere) : $updatedMatiere");
    if (updatedMatiere != null) {
      int index = _matieres.indexWhere((m) => m.id == id);
      print("Index trouvé dans _matieres : $index");
      if (index != -1) {
        _matieres[index] = updatedMatiere; // Met à jour la matière
        notifyListeners(); // Rafraîchit la liste
        print("Matière mise à jour avec succès !");
      } else {
        print("Matière non trouvée dans la liste !");
      }
    } else {
      print("Erreur : L'API n'a pas retourné la matière mise à jour !");
    }
  } catch (e) {
    print("Erreur de mise à jour : $e");
  }
}
Future<List<Historique>> fetchHistorique(String id) async {
  try {
    final response = await ApiService.getHistoriqueMatiere(id);
    if (response is List<Historique>) {
      return response;
    } else {
      print("Erreur : La réponse de l'API n'est pas une liste d'Historique.");
      return [];
    }
  } catch (e) {
    print("Erreur lors du chargement de l'historique : $e");
    return [];
  }
}
Future<List<Matiere>> getMatieresByDate(DateTime date) async {
  try {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.get(Uri.parse("https://autoplanificationproductionproject.onrender.com/matieres?date=$dateStr"));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Matiere.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    print("Erreur getMatieresByDate: $e");
    return [];
  }
}
Future<List<Map<String, dynamic>>> fetchCommandes() async {
  try {
    final List<Commande> commandes = await ApiService.getCommandes();
    return commandes.asMap().entries.expand((entry) {
      final int commandeIndex = entry.key;
      final Commande commande = entry.value;
      return commande.modeles.asMap().entries.map((modeleEntry) {
        final int modeleIndex = modeleEntry.key;
        final modele = modeleEntry.value;
        return {
          'id': '${commande.id}_${commandeIndex}_${modeleIndex}', // ID unique
          'commandeId': commande.id, // Garder l'ID original pour référence
          'modele': modele.nomModele,
          'taille': modele.taille,
        };
      });
    }).toList();
  } catch (e) {
    print("Erreur lors du chargement des commandes : $e");
    return [];
  }
}
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
Matiere? getMatiereByCouleur(String couleur) {
  return _matieres.firstWhere((m) => m.couleur.toLowerCase() == couleur.toLowerCase(), orElse: () => Matiere(id: '', reference: '', couleur: '', quantite: 0, dateAjout: DateTime.now(), historique: []));
}
bool checkStockForCommande(Commande commande) {
  for (var modele in commande.modeles) {
    final matiere = getMatiereByCouleur(modele.couleur);
    if (matiere == null || matiere.quantite < modele.calculerBesoinMatiere()) {
      return false;
    }
  }
  return true;
}

}
