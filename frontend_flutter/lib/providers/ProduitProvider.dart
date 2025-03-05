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

  Future<void> modifierProduit(
      String id,
      String taille,
      String couleur,
      int quantite,
      String etat,
      ) async {
    try {
      await ApiService.updateProduit(id, taille, couleur, quantite, etat);
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
}
