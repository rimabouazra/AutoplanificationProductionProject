import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/providers/PlanificationProvider .dart';
import 'package:frontend/views/PlanificationView.dart';
import 'package:frontend/views/admin_home_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/planification.dart';
import '../models/matiere.dart';
import '../models/commande.dart';
import '../providers/PlanificationProvider .dart';
import '../services/api_service.dart';
import '../views/CommandePage.dart';

class PlanificationConfirmationDialog extends StatefulWidget {
  final List<Planification> planifications;
  final String commandeId;

  const PlanificationConfirmationDialog({
    required this.planifications,
    required this.commandeId,
    Key? key,
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
  Map<String, String?> _matieresSelectionnees = {};
  Map<String, double> _quantitesConsommees = {};
  List<String> _selectedMachines = [];

  @override
  void initState() {
    super.initState();
    _startDate = widget.planifications.first.debutPrevue ?? DateTime.now();
    _endDate = widget.planifications.first.finPrevue ??
        DateTime.now().add(const Duration(hours: 1));
    _selectedMachines =
        widget.planifications.expand((p) => p.machines.map((m) => m.id)).toList();
    _loadMatieres();
  }

  Future<void> _loadMatieres() async {
    try {
      final matieresData = await ApiService.getMatieres();
      setState(() {
        _matieres = matieresData.map((m) => Matiere.fromJson(m)).toList();

        for (var planification in widget.planifications) {
          for (var commande in planification.commandes) {
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
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors du chargement des matières");
    }
  }

  double _calculerConsommation(CommandeModele modele) {
    try {
      if (modele.modele is Modele &&
          (modele.modele as Modele).consommation.isNotEmpty) {
        final consommation = (modele.modele as Modele).consommation.firstWhere(
              (c) => c.taille == modele.taille,
              orElse: () => Consommation(taille: modele.taille, quantity: 0),
            );
        return consommation.quantity * modele.quantite;
      }
      return modele.quantite * 0.5;
    } catch (e) {
      print("Erreur calcul consommation: $e");
      return 0;
    }
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);
    try {
      for (var plan in widget.planifications) {
        // Vérifications matières
        for (var commande in plan.commandes) {
          for (var modele in commande.modeles) {
            final key = '${modele.nomModele}_${modele.taille}';
            if (_matieresSelectionnees[key] == null) {
              Fluttertoast.showToast(
                msg: "Sélectionnez une matière pour tous les modèles",
                backgroundColor: Colors.red,
              );
              return;
            }
          }
        }

        // Mise à jour des stocks
        for (var commande in plan.commandes) {
          for (var modele in commande.modeles) {
            final key = '${modele.nomModele}_${modele.taille}';
            final matiereId = _matieresSelectionnees[key]!;
            final quantite = _quantitesConsommees[key]!;

            await ApiService.updateMatiere(matiereId, quantite,
                action: "consommation");
          }
        }

        // Filtrer les machines sélectionnées
        final selectedMachines = plan.machines
            .where((m) => _selectedMachines.contains(m.id))
            .toList();

        final updated = Planification(
          id: plan.id,
          commandes: plan.commandes,
          machines: selectedMachines,
          salle: plan.salle,
          debutPrevue: _startDate,
          finPrevue: _endDate,
          statut: "confirmée",
        );

        final success = await ApiService.confirmerPlanification(widget.planifications);

      }

      Fluttertoast.showToast(
        msg: "✅ Planifications confirmées !",
        backgroundColor: Colors.blue[700],
        textColor: Colors.white,
      );

      final planifProvider =
          Provider.of<PlanificationProvider>(context, listen: false);
      await planifProvider.fetchPlanifications();

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PlanificationView()),
        (route) => false,
      );
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
    var matieresParCouleur = _matieres
        .where((m) =>
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

  Widget _buildMachineSelector() {
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
            "Machines disponibles:",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
          ),
          const SizedBox(height: 8),
          ...widget.planifications
              .expand((p) => p.machines)
              .map((machine) => CheckboxListTile(
                    title: Text("${machine.nom}"),
                    value: _selectedMachines.contains(machine.id),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedMachines.add(machine.id);
                        } else {
                          _selectedMachines.remove(machine.id);
                        }
                      });
                    },
                    secondary: Icon(Icons.computer, color: Colors.blue[700]),
                    controlAffinity: ListTileControlAffinity.leading,
                  )),
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
    final dateFormat = DateFormat(' le dd/MM/yyyy à HH:mm');
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Résumé de la planification",
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SummaryItem(
                              icon: Icons.person,
                              label: "Client",
                              value: widget.planifications.expand((p) => p.commandes)
                                  .map((c) => c.client.name)
                                  .toSet()
                                  .join(', '),
                            ),

                            _SummaryItem(
                              icon: Icons.assignment,
                              label: "Commande",
                              value: widget.planifications.expand((p) => p.commandes)
                                  .map((c) => c.client.name)
                                  .toSet()
                                  .join(', '),
                            ),
                            _SummaryItem(
                              icon: Icons.date_range,
                              label: "Date de début",
                              value: dateFormat.format(_startDate),
                            ),
                            _SummaryItem(
                              icon: Icons.date_range,
                              label: "Date de fin",
                              value: dateFormat.format(_endDate),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Machines Section
                    Text(
                      "Machines affectées",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMachineSelector(),
                    const SizedBox(height: 20),

                    // Materials Section
                    Text(
                      "Consommation de matière",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.planifications.expand((p) => p.commandes).expand(
                          (commande) => commande.modeles.map(
                            (modele) => _buildMatiereSelector(modele),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dates Section
                    Text(
                      "Dates de production",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DatePickerCard(
                      label: "Début prévu",
                      date: _startDate,
                      formatter: dateFormat,
                      onTap: () => _selectStartDate(context),
                    ),
                    const SizedBox(height: 12),
                    _DatePickerCard(
                      label: "Fin prévue",
                      date: _endDate,
                      formatter: dateFormat,
                      onTap: () => _selectEndDate(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      side: BorderSide(color: Colors.blue[800]!),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Annuler"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmPlanification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
                        : const Text("Confirmer la planification"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
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
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue[700], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(date),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.blue[700], size: 20),
          ],
        ),
      ),
    );
  }
}
