import 'package:frontend/models/salle.dart';

import 'commande.dart';
import 'machine.dart';
import 'modele.dart';

class Planification {
  final String? id;
  final List<Commande> commandes;
  final List<Machine> machines;
  final Salle? salle;
  final DateTime? debutPrevue;
  final DateTime? finPrevue;
  final String statut;
  final Modele? modele;
  final String? taille;
  final String? couleur;
  final int? quantite;
  final DateTime? createdAt;
  final int? order;

  Planification({
    this.id,
    required this.commandes,
    required this.machines,
    this.salle,
    this.debutPrevue,
    this.finPrevue,
    required this.statut,
    this.modele,
    this.taille,
    this.couleur,
    this.quantite,
    this.createdAt,
    this.order,
  });

  factory Planification.fromJson(Map<String, dynamic> json) {
    return Planification(
      id: json['_id']?.toString(),
      commandes: (json['commandes'] as List<dynamic>?)
          ?.map((cmdJson) => Commande.fromJson(cmdJson))
          .toList() ?? [],
      machines: (json["machines"] as List).map((machineJson) {
        if (machineJson is Map<String, dynamic>) {

          if (machineJson["salle"] is Map<String, dynamic>) {
            var salleJson = machineJson["salle"];
            machineJson["salle"] = {
              "_id": salleJson["_id"],  // Extract only the ID from salle
              "type": salleJson["type"] ?? "",
              "nom": salleJson["nom"] ?? "",
            };
          }

          if (machineJson["modele"] is String) {
            print("modele est un string");
            machineJson["modele"] = {
              "_id": machineJson["modele"],
            };
          }

          return Machine.fromJson(machineJson);
        } else {
          throw Exception("Invalid machine data in planification");
        }
      }).toList(),

      salle: json['salle'] != null
          ? (json['salle'] is Map<String, dynamic>
          ? Salle.fromJson(json['salle'])
          : Salle(
        id: json['salle'].toString(),
        nom: '',
        type: '',
      ))
          : null,
      debutPrevue: json['debutPrevue'] != null ? DateTime.parse(json['debutPrevue']) : null,
      finPrevue: json['finPrevue'] != null ? DateTime.parse(json['finPrevue']) : null,
      statut: json['statut']?.toString() ?? 'en attente',
      modele: json['modele'] != null ? Modele.fromJson(json['modele']) : null,
      taille: json['taille']?.toString(),
      couleur: json['couleur']?.toString(),
      quantite: json['quantite'] != null ? int.parse(json['quantite'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      order: json['order'] != null ? int.parse(json['order'].toString()) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'commandes': commandes.map((c) => c.id).toList(),
      'machines': machines.map((m) => m.id).toList(),
      if (salle != null) 'salle': salle!.id,
      if (debutPrevue != null) 'debutPrevue': debutPrevue!.toIso8601String(),
      if (finPrevue != null) 'finPrevue': finPrevue!.toIso8601String(),
      'statut': statut,
      if (modele != null) 'modele': modele!.id,
      if (taille != null) 'taille': taille,
      if (couleur != null) 'couleur': couleur,
      if (quantite != null) 'quantite': quantite,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (order != null) 'order': order,
    };
  }
}