import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/planification.dart';
import '../providers/PlanificationProvider .dart';

class PlanificationView extends StatefulWidget {
  @override
  _PlanificationViewState createState() => _PlanificationViewState();
}

class _PlanificationViewState extends State<PlanificationView> {
  @override
  void initState() {
    super.initState();
    Provider.of<PlanificationProvider>(context, listen: false).fetchPlanifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
      ),
      body: Consumer<PlanificationProvider>(
        builder: (context, provider, child) {
          if (provider.planifications.isEmpty) {
            return const Center(child: Text("Aucune planification disponible"));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: _buildPlanifications(provider),
          );
        },
      ),
    );
  }

  /// Construction des cartes de planification, groupées par date.
  List<Widget> _buildPlanifications(PlanificationProvider provider) {
    Map<String, List<Planification>> groupedPlanifications = {};

    // Grouper par jour
    for (var planification in provider.planifications) {
      String dateKey = planification.debutPrevue != null
          ? DateFormat('EEEE dd MMM yyyy', 'fr_FR').format(planification.debutPrevue!)
          : "Date inconnue";

      if (!groupedPlanifications.containsKey(dateKey)) {
        groupedPlanifications[dateKey] = [];
      }
      groupedPlanifications[dateKey]!.add(planification);
    }

    List<Widget> widgets = [];

    groupedPlanifications.forEach((date, planifications) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            date,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
      );

      for (var planification in planifications) {
        widgets.add(_buildPlanificationCard(planification));
      }
    });

    return widgets;
  }

  Widget _buildPlanificationCard(Planification planification) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
            "Salle : ${planification.machines.isNotEmpty ? planification.machines.first.salle.nom : 'Non assignée'}"
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Commandes : ${planification.commandes.join(", ")}"),
            Text("Machines : ${planification.machines.isNotEmpty ? planification.machines.map((m) => m.nom).join(", ") : 'Aucune'}"),
            Text("Début prévu : ${_formatDate(planification.debutPrevue)}"),
            Text("Fin prévue : ${_formatDate(planification.finPrevue)}"),
            _buildStatut(planification.statut),
          ],
        ),
      ),
    );
  }

  /// Affichage du statut de la commande avec une couleur
  Widget _buildStatut(String statut) {
    Color statutColor;
    switch (statut) {
      case "en attente":
        statutColor = Colors.orange;
        break;
      case "en cours":
        statutColor = Colors.blue;
        break;
      case "terminée":
        statutColor = Colors.green;
        break;
      default:
        statutColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.circle, color: statutColor, size: 12),
          const SizedBox(width: 5),
          Text(
            statut.toUpperCase(),
            style: TextStyle(color: statutColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Formatage des dates pour un affichage clair
  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : "Non défini";
  }
}
