import 'package:frontend/models/modele.dart';

import 'machine.dart';
import 'salle.dart';

class Planification {
  String id;
  List<String> commandes;
  Salle? salle;
  List<Machine> machines;
  DateTime? debutPrevue;
  DateTime? finPrevue;
  String statut;

  Planification({
    required this.id,
    required this.commandes,
    this.salle,
    required this.machines,
    this.debutPrevue,
    this.finPrevue,
    required this.statut,
  });

  factory Planification.fromJson(Map<String, dynamic> json) {
  print("Désérialisation de la planification: $json"); // Log de débogage
  return Planification(
    id: json['_id'],
    commandes: List<String>.from(json['commandes']),
    salle: json['salle'] != null ? Salle.fromJson(json['salle']) : null,
    machines: json['machines'] != null
        ? (json['machines'] as List).map<Machine>((m) {
            print("Désérialisation de la machine: $m"); // Log de débogage
            return Machine.fromJson(m);
          }).toList()
        : [],
    debutPrevue: json['debutPrevue'] != null ? DateTime.parse(json['debutPrevue']) : null,
    finPrevue: json['finPrevue'] != null ? DateTime.parse(json['finPrevue']) : null,
    statut: json['statut'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'commandes': commandes,
      'salle': salle?.toJson(),
      'machines': machines?.map((m) => m.toJson()).toList(),
      'debutPrevue': debutPrevue?.toIso8601String(),
      'finPrevue': finPrevue?.toIso8601String(),
      'statut': statut,
    };
  }
  void affecterSalleEtMachines(Salle salle, List<Machine> machines) {
    this.salle = salle;
    // Ajouter la logique pour affecter les machines
  }
}
