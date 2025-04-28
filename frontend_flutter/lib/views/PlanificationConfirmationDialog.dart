import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/planification.dart';
import '../services/api_service.dart';
import '../models/matiere.dart';
import '../models/commande.dart';
import '../models/modele.dart';
class PlanificationConfirmationDialog extends StatefulWidget {
  final Planification planification;
  final String commandeId;

  const PlanificationConfirmationDialog({
    Key? key,
    required this.planification,
    required this.commandeId,
  }) : super(key: key);

  @override
  _PlanificationConfirmationDialogState createState() =>
      _PlanificationConfirmationDialogState();
}

class _PlanificationConfirmationDialogState
    extends State<PlanificationConfirmationDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  List<Matiere> _matieres = [];
  Map<String, double> _quantitesConsommees = {};
  Map<String, String?> _matieresSelectionnees = {};
  Map<String, bool> _stockSuffisant = {};
  @override
  void initState() {
    super.initState();
    _startDate = widget.planification.debutPrevue ?? DateTime.now();
    _endDate = widget.planification.finPrevue ??
        DateTime.now().add(Duration(hours: 1));
  }

  Future<void> _loadMatieres() async {
    try {
      final matieresData = await ApiService.getMatieres();
      setState(() {
        _matieres = matieresData.map((m) => Matiere.fromJson(m)).toList();
        
        for (var commande in widget.planification.commandes) {
          for (var modele in commande.modeles) {
            final modeleKey = '${modele.nomModele}_${modele.taille}';
            final matiereCorrespondante = _matieres.firstWhere(
              (m) => m.couleur.toLowerCase() == modele.couleur.toLowerCase(),
              orElse: () => Matiere(
                id: '',
                reference: '',
                couleur: '',
                quantite: 0,
                dateAjout: DateTime.now(),
                historique: [],
              ),
            );

            if (matiereCorrespondante.id.isNotEmpty) {
              _matieresSelectionnees[modeleKey] = matiereCorrespondante.id;
              final consommation = _calculerConsommation(modele);
              _quantitesConsommees[modeleKey] = consommation;
              _stockSuffisant[modeleKey] = matiereCorrespondante.quantite >= consommation;
            }
          }
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors du chargement des matières: ${e.toString()}");
    }
  }

  double _calculerConsommation(CommandeModele modele) {
    try {
      // Si le modèle a une consommation définie, l'utiliser
      if (modele.modele is Modele && (modele.modele as Modele).consommation.isNotEmpty) {
        final consommation = (modele.modele as Modele).consommation.firstWhere(
          (c) => c.taille == modele.taille,
          orElse: () => Consommation(taille: modele.taille, quantity: 0),
        );
        return consommation.quantity * modele.quantite;
      }
      // Sinon, utiliser une valeur par défaut
      return modele.quantite * 0.5; // Exemple: 0.5 kg par unité
    } catch (e) {
      print("Erreur calcul consommation: $e");
      return 0;
    }
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);

    try {
      // Vérifier que toutes les matières ont été sélectionnées
     for (var commande in widget.planification.commandes) {
        for (var modele in commande.modeles) {
          final modeleKey = '${modele.nomModele}_${modele.taille}';
          
          if (_matieresSelectionnees[modeleKey] == null) {
            Fluttertoast.showToast(
              msg: "Veuillez sélectionner une matière pour tous les modèles",
              backgroundColor: Colors.red,
            );
            return;
          }
          
          if (_stockSuffisant[modeleKey] == false) {
            Fluttertoast.showToast(
              msg: "Stock insuffisant pour ${modele.nomModele} (${modele.couleur})",
              backgroundColor: Colors.red,
            );
            return;
          }
        }
      }

      // Mettre à jour les stocks de matière
      for (var commande in widget.planification.commandes) {
        for (var modele in commande.modeles) {
          final modeleKey = '${modele.nomModele}_${modele.taille}';
          final matiereId = _matieresSelectionnees[modeleKey]!;
          final quantite = _quantitesConsommees[modeleKey]!;
          
          await ApiService.updateMatiere(
            matiereId, 
            quantite,
            action: "consommation",
          );
        }
      }
      // Update the planification with the edited dates
      final updatedPlanif = Planification(
        id: widget.planification.id,
        commandes: widget.planification.commandes,
        machines: widget.planification.machines,
        debutPrevue: _startDate,
        finPrevue: _endDate,
        statut: "confirmée",
      );

      final success = await ApiService.confirmerPlanification(updatedPlanif);

      if (success) {
        Fluttertoast.showToast(msg: "Planification confirmée avec succès !");
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Fluttertoast.showToast(msg: "Erreur lors de la confirmation");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

    Widget _buildMatiereSelector(CommandeModele modele) {
    final modeleKey = '${modele.nomModele}_${modele.taille}';
    final quantiteNecessaire = _quantitesConsommees[modeleKey] ?? 0;
    final matieresDisponibles = _matieres
        .where((m) => 
            m.couleur.toLowerCase() == modele.couleur.toLowerCase() &&
            m.quantite >= quantiteNecessaire)
        .toList();

    if (matieresDisponibles.isEmpty) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${modele.nomModele} (${modele.taille}, ${modele.couleur})",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "Quantité nécessaire: ${quantiteNecessaire.toStringAsFixed(2)} kg",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                "Aucune matière disponible en stock",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${modele.nomModele} (${modele.taille}, ${modele.couleur})",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "Quantité à consommer: ${quantiteNecessaire.toStringAsFixed(2)} kg",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _matieresSelectionnees[modeleKey],
              decoration: InputDecoration(
                labelText: "Sélectionner la matière",
                border: OutlineInputBorder(),
              ),
              items: matieresDisponibles.map((matiere) {
                return DropdownMenuItem<String>(
                  value: matiere.id,
                  child: Text(
                    "${matiere.reference} - ${matiere.quantite.toStringAsFixed(2)} kg",
                    style: TextStyle(
                      color: matiere.quantite >= quantiteNecessaire 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _matieresSelectionnees[modeleKey] = value;
                  final matiere = _matieres.firstWhere((m) => m.id == value);
                  _stockSuffisant[modeleKey] = matiere.quantite >= quantiteNecessaire;
                });
              },
            ),
            if (_matieresSelectionnees[modeleKey] != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  _stockSuffisant[modeleKey] == true
                      ? "Stock suffisant"
                      : "Stock insuffisant",
                  style: TextStyle(
                    color: _stockSuffisant[modeleKey] == true 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: Text("Confirmer la Planification"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Détails de la planification:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (widget.planification.commandes.isNotEmpty)
              Text(
                  "Commande: ${widget.planification.commandes.first.client.name}"),
            SizedBox(height: 10),
            Text("Machines affectées: ${widget.planification.machines.length}"),
            SizedBox(height: 20),
            Text("Consommation de matière:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.planification.commandes
                .expand((commande) => commande.modeles.map((modele) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: _buildMatiereSelector(modele),
                    ))),
            SizedBox(height: 20),
            Text("Dates proposées:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListTile(
              title: Text("Début: ${dateFormat.format(_startDate)}"),
              trailing: Icon(Icons.edit),
              onTap: () => _selectStartDate(context),
            ),
            ListTile(
              title: Text("Fin: ${dateFormat.format(_endDate)}"),
              trailing: Icon(Icons.edit),
              onTap: () => _selectEndDate(context),
            ),
          ],
        ),
      ),
      actions: [
        // Bouton Annuler
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // L'utilisateur a annulé
          },
          child: Text("Annuler"),
        ),
        // Bouton Confirmer
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  // Appel de la fonction pour confirmer la planification
                  await _confirmPlanification();
                  Navigator.of(context).pop(true); // L'utilisateur a confirmé
                },
          child: _isLoading ? CircularProgressIndicator() : Text("Confirmer"),
        ),
      ],
    );
  }
}
