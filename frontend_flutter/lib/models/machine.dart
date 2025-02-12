import 'salle.dart';
import 'modele.dart';

class Machine {
  String id;
  String nom;
  String etat;
  Salle salle;
  Modele modele;
  String taille;

  Machine({
    required this.id,
    required this.nom,
    required this.etat,
    required this.salle,
    required this.modele,
    required this.taille,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['_id'],
      nom: json['nom'],
      etat: json['etat'],
      salle: Salle.fromJson(json['salle']),
      modele: Modele.fromJson(json['modele']),
      taille: json['taille'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'etat': etat,
      'salle': salle.toJson(),
      'modele': modele.toJson(),
      'taille': taille,
    };
  }
}
