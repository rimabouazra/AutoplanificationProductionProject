import 'dart:convert';

import 'machine.dart';
import 'commande.dart';
class Planification {
  String id;
  List<Commande> commandes;
  List<Machine> machines;
  DateTime? debutPrevue;
  DateTime? finPrevue;
  String statut;

  Planification({
    required this.id,
    required this.commandes,
    required this.machines,
    this.debutPrevue,
    this.finPrevue,
    required this.statut,
  });
  factory Planification.fromJson(Map<String, dynamic> json) {
    try {
      return Planification(
        id: json["_id"].toString(),
        commandes: (json['commandes'] as List<dynamic>?)
            ?.map((cmdJson) => Commande.fromJson(cmdJson))
            .toList() ?? [],
        machines: (json["machines"] as List).map((machineJson) {
          if (machineJson is Map<String, dynamic>) {
            // Create a deep copy to avoid modifying the original
            final machineData = jsonDecode(jsonEncode(machineJson)) as Map<String, dynamic>;

            // Convert all IDs to strings throughout the entire structure
            machineData["_id"] = machineData["_id"].toString();

            if (machineData["salle"] is Map<String, dynamic>) {
              machineData["salle"] = {
                "_id": machineData["salle"]["_id"].toString(),
                "type": machineData["salle"]["type"]?.toString() ?? "",
                "nom": machineData["salle"]["nom"]?.toString() ?? "",
              };
            }

            if (machineData["modele"] is String) {
              machineData["modele"] = {
                "_id": machineData["modele"].toString(),
                // Add minimum required fields for Modele
                "nom": "",
                "tailles": [],
                "consommation": []
              };
            } else if (machineData["modele"] is Map<String, dynamic>) {
              machineData["modele"]["_id"] = machineData["modele"]["_id"].toString();
            }

            return Machine.fromJson(machineData);
          } else {
            throw Exception("Invalid machine data in planification: Expected Map but got ${machineJson.runtimeType}");
          }
        }).toList(),
        debutPrevue: DateTime.parse(json["debutPrevue"].toString()),
        finPrevue: DateTime.parse(json["finPrevue"].toString()),
        statut: json["statut"].toString(),
      );
    } catch (e, stack) {
      print('Error parsing Planification: $e');
      print('Stack trace: $stack');
      print('Problematic JSON: ${jsonEncode(json)}');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'commandes': commandes.map((c) => c.toJson()).toList(),
      'machines': machines.map((m) => m.toJson()).toList(),
      'debutPrevue': debutPrevue?.toIso8601String(),
      'finPrevue': finPrevue?.toIso8601String(),
      'statut': statut,
    };
  }
}
