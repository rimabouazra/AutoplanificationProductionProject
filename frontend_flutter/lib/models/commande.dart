class Commande {
  String? id;
  final String client;
  final int quantite;
  final String couleur;
  final String taille;
  final String conditionnement;
  final DateTime delais;
  final String status; // Ajout du statut

  Commande({
    this.id,
    required this.client,
    required this.quantite,
    required this.couleur,
    required this.taille,
    required this.conditionnement,
    required this.delais,
    required this.status, // Nécessaire pour filtrer et afficher
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json["_id"],
      client: json["client"],
      quantite: json["quantite"],
      couleur: json["couleur"],
      taille: json["taille"],
      conditionnement: json["conditionnement"],
      delais: DateTime.parse(json["delais"]),
      status: json["status"], // Assurez-vous que l'API renvoie bien un `status`
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      "client": client,
      "quantite": quantite,
      "couleur": couleur,
      "taille": taille,
      "conditionnement": conditionnement,
      "delais": delais.toIso8601String(),
      "status": status, // Ajout dans le JSON envoyé à l'API
    };
  }
}
