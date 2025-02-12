import 'machine.dart';
import 'salle.dart';

class Planification {
  String id;
  List<String> commandes;
  Salle? salle;
  Machine? machine;
  DateTime? debutPrevue;
  DateTime? finPrevue;
  String statut;

  Planification({
    required this.id,
    required this.commandes,
    this.salle,
    this.machine,
    this.debutPrevue,
    this.finPrevue,
    required this.statut,
  });

  factory Planification.fromJson(Map<String, dynamic> json) {
    return Planification(
      id: json['_id'],
      commandes: List<String>.from(json['commandes']),
      salle: json['salle'] != null ? Salle.fromJson(json['salle']) : null,
      machine: json['machine'] != null ? Machine.fromJson(json['machine']) : null,
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
      'machine': machine?.toJson(),
      'debutPrevue': debutPrevue?.toIso8601String(),
      'finPrevue': finPrevue?.toIso8601String(),
      'statut': statut,
    };
  }
}
