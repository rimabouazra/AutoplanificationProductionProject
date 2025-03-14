import 'package:flutter/material.dart';
import '../models/produits.dart';
import '../services/api_service.dart';

class ProduitProvider with ChangeNotifier {
  List<Produit> _produits = [];

  List<Produit> get produits => _produits;

  Future<void> fetchProduits() async {
    try {
      _produits = await ApiService.getProduits();
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des produits : $e");
    }
  }

  Future<void> ajouterProduit(Produit produit) async {
    try {
      await ApiService.addProduit(produit);
      await fetchProduits();
    } catch (e) {
      print("Erreur lors de l'ajout du produit : $e");
    }
  }

  Future<void> modifierProduit(Produit produit) async {
    try {
      await ApiService.updateProduit(produit.id, produit.toJson()); // ✅ Correction
      await fetchProduits();
    } catch (e) {
      print("Erreur lors de la modification du produit : $e");
    }
  }

  Future<void> supprimerProduit(String id) async {
    try {
      await ApiService.deleteProduit(id);
      await fetchProduits();
    } catch (e) {
      print("Erreur lors de la suppression du produit : $e");
    }
  }
  Future<void> ajouterTailleAuProduit(String produitId, Map<String, dynamic> tailleData) async {
    try {
      await ApiService.addTailleToProduit(produitId, tailleData);
      notifyListeners();
    } catch (e) {
      print("Erreur lors de l'ajout de la taille : $e");
    }
  }

  Future<void> supprimerTaille(String produitId, int tailleIndex) async {
    try {
      await ApiService.deleteTailleFromProduit(produitId, tailleIndex);
      int produitIndex = _produits.indexWhere((produit) => produit.id == produitId);
      if (produitIndex != -1) {
        _produits[produitIndex].tailles.removeAt(tailleIndex);
        notifyListeners();
      }
    } catch (e) {
      print("Erreur lors de la suppression de la taille : $e");
    }
  }


}
