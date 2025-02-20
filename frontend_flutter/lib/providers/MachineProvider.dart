import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/machine.dart';

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];

  List<Machine> get machines => _machines;

  Future<void> fetchMachinesBySalle(String salleId) async {
  final url = 'http://localhost:5000/api/machines/parSalle/$salleId';
  print("🔍 URL requête: $url"); 

  try {
    final response = await http.get(Uri.parse(url));
    print("Code réponse: ${response.statusCode}");
    print("Réponse: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Machines reçues: $data");

       _machines = (data as List).map((machine) {
        return Machine.fromJson(machine);
      }).toList();
    } else {
      print("Erreur API: ${response.body}");
      throw Exception("Échec du chargement des machines");
    }

    notifyListeners();
  } catch (error) {
    print("Erreur de chargement des machines: $error");
    throw Exception("Erreur de connexion");
  }
}

}
