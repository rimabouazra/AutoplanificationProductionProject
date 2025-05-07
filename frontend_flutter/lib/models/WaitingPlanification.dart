import 'commande.dart';
import 'modele.dart';

class WaitingPlanification {
  final String id;
  final Commande commande;
  final Modele modele;
  final String taille;
  final String couleur;
  final double quantite;
  final DateTime createdAt;

  WaitingPlanification({
    required this.id,
    required this.commande,
    required this.modele,
    required this.taille,
    required this.couleur,
    required this.quantite,
    required this.createdAt,
  });

  factory WaitingPlanification.fromJson(Map<String, dynamic> json) {
    return WaitingPlanification(
      id: json['_id'],
      commande: Commande.fromJson(json['commande']),
      modele: Modele.fromJson(json['modele']),
      taille: json['taille'],
      couleur: json['couleur'],
      quantite: (json['quantite'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}