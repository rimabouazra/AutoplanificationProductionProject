import 'modele.dart';
import 'matiere.dart';

class Produit {
  String id;
  Modele modele;
  String taille;
  String couleur;
  String etat;
  Matiere matiere;  // Modifié pour être un objet de type Matiere
  int quantite;

  Produit({
    required this.id,
    required this.modele,
    required this.taille,
    required this.couleur,
    required this.etat,
    required this.matiere,  // Modifié pour être un objet Matiere
    required this.quantite,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['_id'] ?? '',
      modele: Modele.fromJson(json['modele']),
      taille: json['taille'] ?? '',
      couleur: json['couleur'] ?? '',
      etat: json['etat'] ?? '',
      matiere: Matiere.fromJson(json['matiere']),  // Modification ici pour traiter 'matiere' comme un objet
      quantite: json['quantite'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'modele': modele.toJson(),
      'taille': taille,
      'couleur': couleur,
      'etat': etat,
      'matiere': matiere.toJson(),
      'quantite': quantite,
    };
  }
}
