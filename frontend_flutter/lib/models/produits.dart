import 'modele.dart';
import 'matiere.dart';

class Produit {
  String id;
  Modele modele;
  List<Map<String, dynamic>> tailles; // Contient taille, couleur, état, matière et quantité

  Produit({
    required this.id,
    required this.modele,
    required this.tailles,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['_id'] ?? '',
      modele: Modele.fromJson(json['modele']),
      tailles: List<Map<String, dynamic>>.from(json['tailles'].map((item) {
        return {
          'taille': item['taille'] ?? '',
          'couleur': item['couleur'] ?? '',
          'etat': item['etat'] ?? '',
          'matiere': item['matiere'] != null ? Matiere.fromJson(item['matiere']) : null,
          'quantite': item['quantite'] ?? 0,
        };
      })),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'modeleId': modele.id,
      'tailles': tailles.map((item) => {
        'taille': item['taille'],
        'couleur': item['couleur'],
        'etat': item['etat'],
        'matiere': item['matiere']?.toJson(),
        'quantite': item['quantite'],
      }).toList(),
    };
  }
}
