class Modele {
  String id;
  String nom;
  List<String> tailles;
  List<Modele>? derives;

  Modele({
    required this.id,
    required this.nom,
    required this.tailles,
    this.derives,
  });

  factory Modele.fromJson(Map<String, dynamic> json) {
    return Modele(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',  // nom est toujours présent
      tailles: List<String>.from(json['tailles'] ?? []), //  tailles est une liste valide
      derives: json['derives'] != null
          ? List<Modele>.from(json['derives'].map((m) => Modele.fromJson(m)))
          : [],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'tailles': tailles,
      'derives': derives?.map((m) => m.toJson()).toList(),
    };
  }
}
