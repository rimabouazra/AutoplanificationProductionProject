import 'package:frontend/models/modele.dart';

import 'machine.dart';
import 'salle.dart';

class Planification {
  String id;
  List<String> commandes;
  Salle? salle;
  String? salleId;

  List<Machine> machines;
  DateTime? debutPrevue;
  DateTime? finPrevue;
  String statut;

  Planification({
    required this.id,
    required this.commandes,
    this.salle,
    this.salleId,
    required this.machines,
    this.debutPrevue,
    this.finPrevue,
    required this.statut,
  });

  factory Planification.fromJson(Map<String, dynamic> json) {
    print("Désérialisation de la planification: $json");

    Salle? salle;
    print("Type de 'salle' reçu: ${json['salle'].runtimeType}");
    print("Valeur de 'salle': ${json['salle']}");

    // Si 'salle' est un objet, on le transforme en objet Salle
    if (json['salle'] is Map<String, dynamic>) {
      salle = Salle.fromJson(json['salle']);
      print("Désérialisé 'salle' en objet: $salle \n");

    } else {
      print("'salle' n'est ni un objet ni une chaîne, ignoré.");
    }

    // Désérialisation des machines
    List<Machine> machines = [];
    if (json['machines'] != null) {
      print("Désérialisation des machines: ${json['machines']}");
      machines = (json['machines'] as List).map<Machine>((m) {
        print("Désérialisation de la machine: $m");

        // Vérification et gestion du type de 'salle' dans chaque machine
        if (m['salle'] is Map<String, dynamic>) {
          m['salle'] = Salle.fromJson(m['salle']);
        } else if (m['salle'] is String) {
          print("'salle' dans la machine est un identifiant : ${m['salle']}");
        }
        return Machine.fromJson(m);
      }).toList();
    }

    return Planification(
      id: json['_id'],
      commandes: List<String>.from(json['commandes']),
      salle: salle,
      machines: machines,
      debutPrevue: json['debutPrevue'] != null ? DateTime.tryParse(json['debutPrevue']) : null,
      finPrevue: json['finPrevue'] != null ? DateTime.tryParse(json['finPrevue']) : null,
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
