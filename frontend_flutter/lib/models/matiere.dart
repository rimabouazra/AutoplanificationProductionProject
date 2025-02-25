class Matiere {
  final String id;
  final String reference;
  final String couleur;
  final int quantite;

  Matiere({
    required this.id,
    required this.reference,
    required this.couleur,
    required this.quantite,
  });

  // Convertir un JSON en objet Matiere
  factory Matiere.fromJson(Map<String, dynamic> json) {
    return Matiere(
      id: json['_id'],
      reference: json['reference'],
      couleur: json['couleur'],
      quantite: json['quantite'],
    );
  }

  // Convertir un objet Matiere en JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'reference': reference,
      'couleur': couleur,
      'quantite': quantite,
    };
  }
}
