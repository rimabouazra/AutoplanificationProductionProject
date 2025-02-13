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
}
