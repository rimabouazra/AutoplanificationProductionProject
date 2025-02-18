class Commande {
  String? id;  // Rendre id optionnel
  final String client;
  final int quantite;
  final String couleur;
  final String taille;
  final String conditionnement;
  final DateTime? delais; // Nullable
  final String status;
  final DateTime? createdAt; // Nullable
  final DateTime? updatedAt; // Nullable

  Commande({
     this.id,
    required this.client,
    required this.quantite,
    required this.couleur,
    required this.taille,
    required this.conditionnement,
    this.delais, // Nullable
    required this.status,
    this.createdAt, // Nullable
    this.updatedAt, // Nullable
  });

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "client": client,
      "quantite": quantite,
      "couleur": couleur,
      "taille": taille,
      "conditionnement": conditionnement,
      "delais": delais?.toIso8601String(), // Convertit DateTime en String
      "status": status,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
    };
  }

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['_id'] ?? '',
      client: json['client'] ?? '',
      quantite: json['quantite'] ?? 0,
      couleur: json['couleur'] ?? '',
      taille: json['taille'] ?? '',
      conditionnement: json['conditionnement'] ?? '',
      delais: json['delais'] != null ? DateTime.tryParse(json['delais']) : null, // Utilise tryParse()
      status: json['etat'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }
}
