import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:frontend/models/salle.dart';
import 'package:frontend/providers/CommandeProvider.dart';
import 'package:frontend/providers/matiereProvider.dart';
import 'package:frontend/models/commande.dart';
import 'package:frontend/models/planification.dart';
import 'package:frontend/services/api_service.dart';
import 'package:http/http.dart' as http;

class PlanificationProvider with ChangeNotifier {
  final CommandeProvider commandeProvider;
  final MatiereProvider matiereProvider;
  List<Planification> _planifications = [];
  List<Planification> get planifications => _planifications;
  int _startHour = 7; // Default value
  int _endHour = 17;  // Default value
  String _timezone = 'Africa/Tunis';
  PlanificationProvider(this.commandeProvider, this.matiereProvider);
  int get startHour => _startHour;
  int get endHour => _endHour;
  String get timezone => _timezone;
  Future<void> updateWorkHours(int newStartHour, int newEndHour) async {
    try {
      final response = await ApiService.updateWorkHours(newStartHour, newEndHour);
      if (response['success']) {
        _startHour = response['workHoursConfig']['startHour'];
        _endHour = response['workHoursConfig']['endHour'];
        _timezone = response['workHoursConfig']['timezone'];
        notifyListeners(); // Notify UI of changes
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des heures de travail: $e');
      throw e;
    }
  }
  Future<void> autoPlanifierToutesLesCommandes() async {
    final url = Uri.parse('https://autoplanificationproductionproject.onrender.com/planifications/auto');
    final response = await http.post(url);

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchPlanifications();
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }


  Future<void> fetchPlanifications() async {
    try {
      final response = await ApiService.getPlanifications();
      if (response is List<Planification>) {
        print("La réponse est bien une liste avec ${response.length} éléments.");
        _planifications = response; // Directement assignée
        notifyListeners();
      } else {
        print("Réponse inattendue du serveur: ${response.runtimeType}");
        throw Exception("Réponse du serveur incorrecte");
      }
    } catch (e) {
      print(" Erreur lors du chargement des planifications: $e");
    }
  }

  Future<void> autoPlanifierCommande(String commandeId) async {
    try {
      bool success = await ApiService.autoPlanifierCommande(commandeId);
      if (success) {
        await fetchPlanifications();
        print("Planification automatique réussie");
      } else {
        throw Exception("Erreur lors de la planification automatique");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }


  Future<void> planifierCommande(String commandeId, List<Salle> salles) async {
    final commande = commandeProvider.commandes.firstWhere((cmd) => cmd.id == commandeId);

    for (var modele in commande.modeles) {
      double besoin = modele.calculerBesoinMatiere();
      final matiere = matiereProvider.getMatiereByCouleur(modele.couleur);

      if (matiere != null && matiere.estStockSuffisant(besoin)) {
        bool estFoncee = modele.estCouleurFoncee(modele.couleur);

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
