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
    print("JSON reçu pour Modele: $json");  // Debug pour voir les données reçues
    return Modele(
      id: json.containsKey('_id') ? json['_id'] ?? '' : '', 
      nom: json['nom'],
      tailles: List<String>.from(json['tailles']),
      derives: json['derives'] != null
          ? (json['derives'] as List).map((m) => Modele.fromJson(m)).toList()
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
