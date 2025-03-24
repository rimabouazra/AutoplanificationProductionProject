class Modele {
  String id;
  String nom;
  List<String> tailles;
  List<Modele>? derives;
  List<Consommation> consommation;

  Modele({
    required this.id,
    required this.nom,
    required this.tailles,
    this.derives,
    required this.consommation,
  });

  factory Modele.fromJson(Map<String, dynamic> json) {
    return Modele(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      tailles: List<String>.from(json['tailles'] ?? []),
      derives: json['derives'] != null
          ? List<Modele>.from(json['derives'].map((m) => Modele.fromJson(m)))
          : [],
      consommation: json['consommation'] != null
          ? List<Consommation>.from(json['consommation'].map((c) => Consommation.fromJson(c)))
          : [],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'tailles': tailles,
      'derives': derives?.map((m) => m.toJson()).toList(),
      'consommation': consommation.map((c) => c.toJson()).toList(),
    };
  }
}
class Consommation {
  String taille;
  double quantity;

  Consommation({required this.taille, required this.quantity});

  factory Consommation.fromJson(Map<String, dynamic> json) {
    return Consommation(
      taille: json['taille'] ?? '',
      quantity: (json['quantite'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taille': taille,
      'quantite': quantity,
    };
  }
}