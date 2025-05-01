import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/providers/PlanificationProvider%20.dart';
import 'package:frontend/views/PlanificationView.dart';
import 'package:frontend/views/admin_home_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/planification.dart';
import '../models/matiere.dart';
import '../models/commande.dart';

import '../providers/PlanificationProvider .dart';
 import'../services/api_service.dart';
import '../views/CommandePage.dart';

class PlanificationConfirmationDialog extends StatefulWidget {
  final Planification planification;
  final String commandeId;
  
  const PlanificationConfirmationDialog({
    Key? key,
    required this.planification,
    required this.commandeId,
  }) : super(key: key);

  @override
  _PlanificationConfirmationDialogState createState() => _PlanificationConfirmationDialogState();
}

class _PlanificationConfirmationDialogState extends State<PlanificationConfirmationDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;
  List<Matiere> _matieres = [];
  Map<String, String?> _matieresSelectionnees = {};
  Map<String, double> _quantitesConsommees = {};


  @override
  void initState() {
    super.initState();
    _startDate = widget.planification.debutPrevue ?? DateTime.now();
    _endDate = widget.planification.finPrevue ?? DateTime.now().add(const Duration(hours: 1));
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final matieresData = await ApiService.getMatieres();
      setState(() {
        _matieres = matieresData.map((m) => Matiere.fromJson(m)).toList();
        
        // Initialiser les sélections de matières pour chaque modèle
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
              _quantitesConsommees[modeleKey] = _calculerConsommation(modele);
            }
          }
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors du chargement des matières");
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
      return modele.quantite * 0.5; // Exemple: 0.5 m par unité
    } catch (e) {
      print("Erreur calcul consommation: $e");
      return 0;
    }
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);
    try {
      // Vérifier que toutes les matières sont sélectionnées
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
        }
      }

      // Mettre à jour les stocks de matière
      for (var commande in widget.planification.commandes) {
        for (var modele in commande.modeles) {
          final modeleKey = '${modele.nomModele}_${modele.taille}';
          final matiereId = _matieresSelectionnees[modeleKey]!;
          final quantite = _quantitesConsommees[modeleKey]!;
          
          await ApiService.updateMatiere(matiereId, quantite, action: "consommation");
        }
      }

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
        Fluttertoast.showToast(
          msg: "Planification confirmée avec succès !",
          backgroundColor: Colors.blue[700],
          textColor: Colors.white,
        );
        final planifProvider = Provider.of<PlanificationProvider>(context, listen: false);
        await planifProvider.fetchPlanifications();
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => PlanificationView()),
          (route) => false,
        );
      } else {
        Fluttertoast.showToast(msg: "Erreur lors de la confirmation");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur: ${e.toString()}");
      debugPrint('Confirmation error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMatiereSelector(CommandeModele modele) {
    final modeleKey = '${modele.nomModele}_${modele.taille}';
    final quantiteNecessaire = _quantitesConsommees[modeleKey] ?? 0;
    var matieresParCouleur = _matieres.where((m) => 
      m.couleur.toLowerCase().contains(modele.couleur.toLowerCase()) ||
      modele.couleur.toLowerCase().contains(m.couleur.toLowerCase()))
    .toList();
    final matieresDisponibles = matieresParCouleur.map((m) {
    final suffisant = m.quantite >= quantiteNecessaire;
    return {
      'matiere': m,
      'suffisant': suffisant,
    };
  }).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${modele.nomModele} (${modele.taille}, ${modele.couleur})",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Quantité nécessaire: ${quantiteNecessaire.toStringAsFixed(2)} m",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (matieresDisponibles.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _matieresSelectionnees[modeleKey],
              decoration: InputDecoration(
                labelText: "Sélectionner la matière",
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              items: matieresDisponibles.map((entry) {
              final matiere = entry['matiere'] as Matiere;
              final suffisant = entry['suffisant'] as bool;
              return DropdownMenuItem<String>(
                value: matiere.id,
                child: Text(
                  "${matiere.reference} (${matiere.quantite.toStringAsFixed(2)} m)",
                  style: TextStyle(
                    color: suffisant ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _matieresSelectionnees[modeleKey] = value;
                });
              },
            )
          else
            Text(
              "Aucune matière disponible en stock",
              style: TextStyle(color: Colors.red[700]),
            ),
        ],
      ),
    );
  }
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _startDate = newDateTime);
      }
    }
  }
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _endDate = newDateTime);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(' le dd/MM/yyyy à  HH:mm');
    final theme = Theme.of(context);
    
return Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  elevation: 8,
  child: Container(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.of(context).size.width * 0.9,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
    ),
    child: SingleChildScrollView(
            child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  "Confirmer la Planification",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Détails de la planification:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.planification.commandes.isNotEmpty)
                          Text(
                            "Client: ${widget.planification.commandes.first.client.name}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[900],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "Machines affectées: ${widget.planification.machines.first.nom}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Consommation de matière:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.planification.commandes.expand((commande) => 
                    commande.modeles.map((modele) => 
                      _buildMatiereSelector(modele),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Dates proposées:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerCard(
                    label: "Début",
                    date: _startDate,
                    formatter: dateFormat,
                    onTap: () => _selectStartDate(context),
                  ),
                  const SizedBox(height: 12),
                  _DatePickerCard(
                    label: "Fin",
                    date: _endDate,
                    formatter: dateFormat,
                    onTap: () => _selectEndDate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Annuler modifications"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmPlanification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirmer"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat formatter;
  final VoidCallback onTap;
  
  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  formatter.format(date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit, color: Colors.blue[700], size: 18),
          ],
        ),
      ),
    );
  }
}