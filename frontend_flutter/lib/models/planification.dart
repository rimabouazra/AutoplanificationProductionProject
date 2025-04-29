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
    return Planification(
      id: json["_id"]?.toString() ?? "",
      commandes: (json['commandes'] as List<dynamic>?)
          ?.map((cmdJson) => Commande.fromJson(cmdJson))
          .toList() ?? [],
      machines: (json["machines"] as List).map((machineJson) {
      if (machineJson is Map<String, dynamic>) {

        if (machineJson["salle"] is Map<String, dynamic>) {
          var salleJson = machineJson["salle"];
          machineJson["salle"] = {
            "_id": salleJson["_id"],  // Extract only the ID from salle
            "type": salleJson["type"] ?? "",
            "nom": salleJson["nom"] ?? "",
          };
        }

        if (machineJson["modele"] is String) {
          print("modele est un string");
          machineJson["modele"] = {
            "_id": machineJson["modele"],
          };
        }

        return Machine.fromJson(machineJson);
      } else {
        throw Exception("Invalid machine data in planification");
      }
    }).toList(),
      debutPrevue: DateTime.parse(json["debutPrevue"]),
      finPrevue: DateTime.parse(json["finPrevue"]),
      statut: json["statut"],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'commandes': commandes.map((c) => c.id).toList(),  // juste les IDs des commandes
      'machines': machines.map((m) => m.id).toList(),    // juste les IDs des machines
      'debutPrevue': debutPrevue?.toIso8601String(),
      'finPrevue': finPrevue?.toIso8601String(),
      'statut': statut,
    };
  }

}
