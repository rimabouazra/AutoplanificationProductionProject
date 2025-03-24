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
      modele: json['modele'] != null ? Modele.fromJson(json['modele']) : Modele(id: '', nom: '', tailles: [], consommation: []),
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

  // Fonction pour déterminer la couleur en fonction de l'état
  static String getEtatColor(String etat) {
    switch (etat) {
      case 'disponible':
        return '0xFF4CAF50'; // Vert
      case 'occupee':
        return '0xFFFF9800'; // Orange
      case 'arretee':
        return '0xFFF44336'; // Rouge
      default:
        return '0xFF9E9E9E'; // Gris par défaut
    }
  }
}
