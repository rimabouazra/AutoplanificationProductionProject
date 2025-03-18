import 'package:flutter/material.dart';
import 'package:frontend/models/salle.dart';
import 'package:frontend/providers/CommandeProvider.dart';
import 'package:frontend/providers/matiereProvider.dart';
import 'package:frontend/models/commande.dart';
import 'package:frontend/models/planification.dart';
import 'package:frontend/services/api_service.dart';

class PlanificationProvider with ChangeNotifier {
  final CommandeProvider commandeProvider;
  final MatiereProvider matiereProvider;
  List<Planification> _planifications = [];
  List<Planification> get planifications => _planifications;

  PlanificationProvider(this.commandeProvider, this.matiereProvider);
  Future<void> fetchPlanifications() async {
    try {
      final response = await ApiService.getPlanifications(); // Ajoutez une fonction API pour récupérer les planifications
      _planifications = response.map((json) => Planification.fromJson(json as Map<String, dynamic>)).toList();
      notifyListeners();
    } catch (e) {
      print("Erreur lors du chargement des planifications: $e");
    }
  }
  Future<void> planifierCommande(String commandeId, List<Salle> salles) async {
    final commande = commandeProvider.commandes.firstWhere((cmd) => cmd.id == commandeId);

    for (var modele in commande.modeles) {
      double besoin = modele.calculerBesoinMatiere();
      final matiere = matiereProvider.getMatiereByCouleur(modele.couleur);

      if (matiere != null && matiere.estStockSuffisant(besoin)) { // ✅ Vérification null
        bool estFoncee = modele.estCouleurFoncee(modele.couleur); // ✅ Utilisation de la classification RGB

        for (var salle in salles) {
          if ((estFoncee && salle.nom == "Salle Noire") || (!estFoncee && salle.nom == "Salle Blanche")) {
            await commandeProvider.affecterSalleEtMachines(commande, salle, salle.machines);
            break;
          }
        }
      } else {
        throw Exception("Stock insuffisant ou matière introuvable pour le modèle ${modele.nomModele}");
      }
    }
  }
}
