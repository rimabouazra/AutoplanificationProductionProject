import 'dart:math';
class TailleBase {
  String baseId;
  List<String> tailles;

  TailleBase({required this.baseId, required this.tailles});

  factory TailleBase.fromJson(Map<String, dynamic> json) {
    return TailleBase(
      baseId: json['baseId'] ?? '',
      tailles: List<String>.from(json['tailles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseId': baseId,
      'tailles': tailles,
    };
  }
}

class Modele {
  String id;
  String nom;
  List<String> tailles;
  List<Modele>? derives;
  List<Consommation> consommation;
  List<TailleBase> taillesBases;

  Modele({
    required this.id,
    required this.nom,
    required this.tailles,
    this.derives,
    required this.consommation,
    this.taillesBases = const [], // Initialisation par défaut
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
      taillesBases: json['taillesBases'] != null
          ? List<TailleBase>.from(json['taillesBases'].map((tb) => TailleBase.fromJson(tb)))
          : [], // Ajout du parsing de taillesBases
    );
  }


  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'tailles': tailles,
      'derives': derives?.map((m) => m.toJson()).toList(),
      'consommation': consommation.map((c) => c.toJson()).toList(),
      'taillesBases': taillesBases.map((tb) => tb.toJson()).toList(), 
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
      quantity: double.parse((json['quantite'] ?? 0).toStringAsFixed(4)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taille': taille,
      'quantite': double.parse(quantity.toStringAsFixed(4)),
    };
  }
}