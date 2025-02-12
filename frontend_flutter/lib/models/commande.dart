class Commande {
  final String client;
  final int quantite;
  final String couleur;
  final String taille;
  final String conditionnement;
  final DateTime delais;

  Commande({
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
      "client": client,
      "quantite": quantite,
      "couleur": couleur,
      "taille": taille,
      "conditionnement": conditionnement,
      "delais": delais.toIso8601String(),
    };
  }
}
