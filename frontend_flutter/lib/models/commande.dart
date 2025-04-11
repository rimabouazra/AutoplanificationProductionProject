import 'package:flutter/painting.dart';

class CommandeModele {
  String? modele; // Référence à un Modele (ID)
  String nomModele; // Ajout du nom du modèle
  String taille;
  String couleur;
  int quantite; // Quantité demandée par le client
  int quantiteCalculee; // Quantité calculée automatiquement
  int quantiteReelle; // Quantité réelle saisie par l'utilisateur

  CommandeModele({
    this.modele,
    required this.nomModele,
    required this.taille,
    required this.couleur,
    required this.quantite,
    this.quantiteCalculee = 0, // Par défaut à 0
    this.quantiteReelle = 0, // Par défaut à 0
  });

  factory CommandeModele.fromJson(Map<String, dynamic> json) {
    return CommandeModele(
      modele: json['modele'],
      nomModele: json['nomModele'] ?? '',
      taille: json['taille'],
      couleur: json['couleur'],
      quantite: json['quantite'] ?? 0,
      quantiteCalculee: json['quantiteCalculee'] ?? 0,
      quantiteReelle: json['quantiteReelle'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modele': modele,
      'nomModele': nomModele, // Inclusion du nom du modèle dans la requête
      'taille': taille,
      'couleur': couleur,
      'quantite': quantite,
      'quantiteCalculee': quantiteCalculee,
      'quantiteReelle': quantiteReelle,
    };
  }
  //A ameliorer pour qu'elle soit modifiable
   double calculerBesoinMatiere() {
    return quantite / 40; 
  }
  bool estCouleurFoncee(String couleurHex) {
  try {
    // Convertir le code hexadécimal en RGB
    Color couleur = Color(int.parse("0xFF" + couleurHex.replaceAll("#", "")));
    // Calculer la luminosité avec la formule relative
    double luminosite = (0.299 * couleur.red + 0.587 * couleur.green + 0.114 * couleur.blue) / 255;
    // Si la luminosité est inférieure à 0.5 → couleur foncée
    return luminosite < 0.5;
  } catch (e) {
    print("Erreur lors de l'analyse de la couleur : $e");
    return false; // Par défaut, considérer la couleur comme claire
  }
}
}

class Commande {
  String? id;
  String client;
  List<CommandeModele> modeles;
  String? conditionnement;
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
    this.conditionnement,
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
              .toList() ??
          [],
      conditionnement: json['conditionnement'] ?? '',
      delais: json['delais'] != null ? DateTime.tryParse(json['delais']) : null,
      etat: json['etat'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      salleAffectee: json['salleAffectee'],
      machinesAffectees: (json['machinesAffectees'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
