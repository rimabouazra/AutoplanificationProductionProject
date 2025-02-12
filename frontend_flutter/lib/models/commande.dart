class Commande {
  String? id; // Rendre l'id optionnel , le backend génère l'ID
  final String client;
  final int quantite;
  final String couleur;
  final String taille;
  final String conditionnement;
  final DateTime delais;

  Commande({
    this.id,
    required this.client,
    required this.quantite,
    required this.couleur,
    required this.taille,
    required this.conditionnement,
    required this.delais,
  });

  // Convertir une commande en JSON (pour l'API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id, // Ne pas envoyer d'ID si non défini
      "client": client,
      "quantite": quantite,
      "couleur": couleur,
      "taille": taille,
      "conditionnement": conditionnement,
      "delais": delais.toIso8601String(),
    };
  }

  // Créer une instance de Commande à partir du JSON
  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json["_id"],
      client: json["client"],
      quantite: json["quantite"],
      couleur: json["couleur"],
      taille: json["taille"],
      conditionnement: json["conditionnement"],
      delais: DateTime.parse(json["delais"]),
    );
  }
}
