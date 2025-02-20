class CommandeModele {
  String? modele; // Référence à un Modele
  String taille;
  String couleur;
  int quantite;

  CommandeModele({
    this.modele,
    required this.taille,
    required this.couleur,
    required this.quantite,
  });

  factory CommandeModele.fromJson(Map<String, dynamic> json) {
    return CommandeModele(
      modele: json['modele'],
      taille: json['taille'],
      couleur: json['couleur'],
      quantite: json['quantite'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modele': modele,
      'taille': taille,
      'couleur': couleur,
      'quantite': quantite,
    };
  }
}


class Commande {
  String? id;
  String client;
  List<CommandeModele> modeles;
  String conditionnement;
  DateTime? delais;
  String etat;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? salleAffectee;
  List<String>? machinesAffectees; // Ensure this is a List

  Commande({
    this.id,
    required this.client,
    required this.modeles,
    required this.conditionnement,
    this.delais,
    required this.etat,
    this.createdAt,
    this.updatedAt,
    this.salleAffectee,
    this.machinesAffectees,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['_id'],
      client: json['client'] ?? '',
      modeles: (json['modeles'] as List<dynamic>?)
          ?.map((item) => CommandeModele.fromJson(item))
          .toList() ?? [],
      conditionnement: json['conditionnement'] ?? '',
      delais: json['delais'] != null ? DateTime.tryParse(json['delais']) : null,
      etat: json['etat'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      salleAffectee: json['salleAffectee'],
      machinesAffectees: (json['machinesAffectees'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'client': client,
      'modeles': modeles.map((m) => m.toJson()).toList(),
      'conditionnement': conditionnement,
      'delais': delais?.toIso8601String(),
      'etat': etat,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'salleAffectee': salleAffectee,
      'machinesAffectees': machinesAffectees,
    };
  }
}