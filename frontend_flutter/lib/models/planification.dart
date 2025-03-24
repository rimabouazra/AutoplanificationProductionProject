import 'machine.dart';

class Planification {
  String id;
  List<String> commandes;
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
      id: json["_id"],
      commandes: List<String>.from(json['commandes']),

      machines: (json["machines"] as List)
          .map((m) => Machine.fromJson(m))
          .toList(),
      debutPrevue: DateTime.parse(json["debutPrevue"]),
      finPrevue: DateTime.parse(json["finPrevue"]),
      statut: json["statut"],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'commandes': commandes,
      'machines': machines.map((m) => m.toJson()).toList(),
      'debutPrevue': debutPrevue?.toIso8601String(),
      'finPrevue': finPrevue?.toIso8601String(),
      'statut': statut,
    };
  }
}
