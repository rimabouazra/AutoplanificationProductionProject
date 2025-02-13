import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/machine.dart';

class MachineProvider with ChangeNotifier {
  List<Machine> _machines = [];

  List<Machine> get machines => _machines;

  Future<void> fetchMachinesBySalle(String salleId) async {
    final url = 'http://localhost:5000/api/machines/parSalle';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        var salleData = data.firstWhere((salle) => salle['_id'] == salleId, orElse: () => null);
        if (salleData != null) {
          _machines = (salleData['machines'] as List).map((machine) => Machine.fromJson(machine)).toList();
        } else {
          _machines = [];
        }
      } else {
        throw Exception("Échec du chargement des machines");
      }
      notifyListeners();
    } catch (error) {
      throw Exception("Erreur lors du chargement des machines: $error");
    }
  }
}
