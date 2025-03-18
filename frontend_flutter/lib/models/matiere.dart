class Historique {
  final String action;
  final double quantite;
  final DateTime date;

  Historique({required this.action, required this.quantite, required this.date});

  factory Historique.fromJson(Map<String, dynamic> json) {
    return Historique(
      action: json['action'],
      quantite: (json['quantite'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'action': action,
       'quantite': quantite,
      'date': date.toIso8601String(),
    };
  }
}
class Matiere {
  final String id;
  String reference;
  final String couleur;
  final double quantite;
  final DateTime dateAjout;
  final List<Historique> historique;

  Matiere({
    required this.id,
    required this.reference,
    required this.couleur,
    required this.quantite,
    required this.dateAjout,
    required this.historique,
  });

  // Convertir un JSON en objet Matiere
  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      id: json['_id']?.toString() ?? '',
    reference: json['reference'] ?? '', 
    couleur: json['couleur'] ?? '',
    quantite:(json['quantite'] as num).toDouble() ?? 0,
    dateAjout: DateTime.parse(json['dateAjout']),
      historique: (json['historique'] as List).map((item) => Historique.fromJson(item)).toList(),
    );
  }

  // Convertir un objet Matiere en JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reference': reference,
      'couleur': couleur,
      'quantite': quantite,
      'dateAjout': dateAjout.toIso8601String(),
      'historique': historique.map((h) => h.toJson()).toList(),
    };
  }
  bool estStockSuffisant(double besoin) {
    return quantite >= besoin;
  }
}
