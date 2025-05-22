import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/providers/PlanificationProvider .dart';
import 'package:frontend/views/admin_home_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/machine.dart';
import '../models/matiere.dart';
import '../models/commande.dart';
import '../models/planification.dart';
import '../models/salle.dart';
import '../services/api_service.dart';

class PlanificationConfirmationDialog extends StatefulWidget {
  final List<Planification> planifications;
  final String commandeId;
  final bool hasInsufficientStock;
  final bool partialAvailable;

  const PlanificationConfirmationDialog({
    required this.planifications,
    required this.commandeId,
    this.hasInsufficientStock = false,
    this.partialAvailable = false,
    Key? key,
  }) : super(key: key);

  @override
  _PlanificationConfirmationDialogState createState() =>
      _PlanificationConfirmationDialogState();
}

class _PlanificationConfirmationDialogState
    extends State<PlanificationConfirmationDialog> {
  bool _isLoading = false;
  List<Matiere> _matieres = [];
  final Map<String, String?> _matieresSelectionnees = {};
  final Map<String, double> _quantitesConsommees = {};

  List<Salle?> _selectedSalles = [];
  List<List<String>> _selectedMachinesForPlanifications = [];
  List<DateTime> _startDates = [];
  List<DateTime> _endDates = [];
  List<List<Machine>> _availableMachines = [];
  List<Salle> _salles = []; // Added missing field

  bool _showStockOptions = false;
  bool _partialPlanning = false;
  String _stockMessage = '';
  @override
  void initState() {
    super.initState();
    _selectedSalles = List<Salle?>.filled(widget.planifications.length, null);
    _selectedMachinesForPlanifications = List<List<String>>.generate(
        widget.planifications.length,
        (index) =>
            widget.planifications[index].machines.map((m) => m.id).toList());
    _startDates = widget.planifications
        .map((p) => p.debutPrevue ?? DateTime.now())
        .toList();
    _endDates = widget.planifications
        .map((p) => p.finPrevue ?? DateTime.now().add(const Duration(hours: 1)))
        .toList();
    _availableMachines =
        List<List<Machine>>.filled(widget.planifications.length, []);

    _loadMatieres();
    _loadSallesAndMachines();
    if (widget.hasInsufficientStock && widget.partialAvailable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStockChoiceDialog();
      });
    }
  }

  Future<void> _showStockChoiceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Stock Insuffisant"),
        content: const Text(
          "Le stock de matières est insuffisant pour cette commande. Voulez-vous :\n"
          "- Planifier la quantité réalisable et mettre le reste en attente ?\n"
          "- Mettre toute la commande en attente ?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _partialPlanning = true;
              });
              Navigator.pop(context);
            },
            child: const Text("Planifier partiellement"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _partialPlanning = false;
              });
              Navigator.pop(context);
            },
            child: const Text("Mettre en attente"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSallesAndMachines() async {
    try {
      print('Starting _loadSallesAndMachines...');
      final sallesData = await ApiService.getSalles();
      final salleMap = {for (var s in sallesData) s.id: s};
      print(
          'Fetched ${sallesData.length} salles: ${sallesData.map((s) => 'ID: ${s.id}, Nom: ${s.nom}').join(', ')}');

      setState(() {
        _salles = sallesData; // Store the fetched salles in state
        _selectedSalles =
            List.generate(widget.planifications.length, (_) => null);

        for (var i = 0; i < widget.planifications.length; i++) {
          final planification = widget.planifications[i];
          print('Processing Planification $i:');

          Salle? salle = planification.salle;
          print('Salle field type: ${salle.runtimeType}');
          print('Salle field value: $salle');

          if (salle != null) {
            print('Salle is Salle object, ID: ${salle.id}, Nom: ${salle.nom}');
            final matchedSalle = salleMap[salle.id] ??
                Salle(
                    id: salle.id,
                    nom: 'Unknown',
                    type: 'Unknown',
                    machines: []);
            print(
                'Matched salle: ${matchedSalle.id}, Nom: ${matchedSalle.nom}');
            _selectedSalles[i] =
                salleMap[salle.id]; // Use the Salle instance from salleMap
            print(
                'Selected salle for index $i: ${matchedSalle.nom} (ID: ${matchedSalle.id})');
          } else {
            print('Salle is null for planification $i');
            _selectedSalles[i] = null;
          }

          final machines = planification.machines;
          print('Found ${machines.length} machines for planification $i');
          for (var machine in machines) {
            print(
                'Machine: ID=${machine.id}, Nom=${machine.nom}, Salle ID=${machine.salle.id}');
            final matchedSalle = salleMap[machine.salle.id] ??
                Salle(
                    id: machine.salle.id,
                    nom: 'Unknown',
                    type: 'Unknown',
                    machines: []);
            machine.salle.nom = matchedSalle.nom;
            machine.salle.type = matchedSalle.type;
            print(
                'Updated machine salle: Nom=${machine.salle.nom}, Type=${matchedSalle.type}');
          }
        }
      });
    } catch (e, stackTrace) {
      print('Error in _loadSallesAndMachines: $e');
      print('Stack trace: $stackTrace');
      Fluttertoast.showToast(
          msg: "Erreur lors du chargement des salles et machines");
    }
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
                  reference: 'Non disponible',
                  couleur: modele.couleur,
                  quantite: 0,
                  dateAjout: DateTime.now(),
                  historique: [],
                ),
              );

              _matieresSelectionnees[modeleKey] =
                  matiereCorrespondante.id.isNotEmpty
                      ? matiereCorrespondante.id
                      : null;
              _quantitesConsommees[modeleKey] = _calculerConsommation(modele);
            }
          }
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors du chargement des matières: $e");
    }
  }

  Future<void> _loadMachinesForSalle(int planIndex, String salleId) async {
    try {
      final machines = await ApiService.getMachinesParSalle(salleId);
      setState(() {
        _availableMachines[planIndex] =
            machines.where((m) => m.etat == "disponible").toList();
        // If current selected machines are not in available machines, reset selection
        _selectedMachinesForPlanifications[planIndex] =
            _selectedMachinesForPlanifications[planIndex]
                .where((id) =>
                    _availableMachines[planIndex].any((m) => m.id == id))
                .toList();
        // If no machines selected but available, select first available machine
        if (_selectedMachinesForPlanifications[planIndex].isEmpty &&
            _availableMachines[planIndex].isNotEmpty) {
          _selectedMachinesForPlanifications[planIndex] = [
            _availableMachines[planIndex].first.id
          ];
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur lors du chargement des machines");
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

  bool _checkStockAvailability() {
    for (var plan in widget.planifications) {
      if (plan.statut == "waiting_resources") continue;

      for (var commande in plan.commandes) {
        for (var modele in commande.modeles) {
          final key = '${modele.nomModele}_${modele.taille}';
          final matiereId = _matieresSelectionnees[key];
          final quantiteNecessaire = _quantitesConsommees[key] ?? 0;

          if (matiereId != null) {
            final matiere = _matieres.firstWhere((m) => m.id == matiereId);
            if (matiere.quantite < quantiteNecessaire) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);
    try {
      final existingPlanifications = await ApiService.getWaitingPlanifications(
          commandeId: widget.commandeId);
      final Map<String, Planification> existingPlanMap = {
        for (var p in existingPlanifications) p.id!: p
      };
      if (widget.hasInsufficientStock && !_partialPlanning) {
        List<Planification> waitingPlans = [];
        for (var plan in widget.planifications) {
          // Check if planification already exists
          final existingPlan = existingPlanMap[plan.id ?? ''];
          if (existingPlan != null) {
            waitingPlans.add(existingPlan);
          } else {
            waitingPlans.add(Planification(
              id: plan.id ?? '',
              commandes: plan.commandes,
              machines: [],
              salle: plan.salle,
              quantite: plan.quantite,
              taille: plan.taille,
              couleur: plan.couleur,
              statut: "waiting_resources",
              createdAt: DateTime.now(),
            ));
          }
        }

        final success = await ApiService.confirmerPlanification(waitingPlans);
        if (success) {
          Fluttertoast.showToast(
            msg: "Planifications mises en attente de stock",
            backgroundColor: Colors.blue[700],
          );
          Navigator.pop(context);
          return;
        }
      }

      if (!_checkStockAvailability() && _partialPlanning) {
        final response = await http.post(
          Uri.parse('${ApiService.baseUrl}/planifications/auto'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "commandeId": widget.commandeId,
            "partial": true,
            "preview": false,
          }),
        );

        if (response.statusCode == 201) {
          final jsonData = json.decode(response.body);
          widget.planifications.clear();
          widget.planifications.addAll(
            (jsonData['planifications'] as List<dynamic>)
                .map((json) => Planification.fromJson(json))
                .toList(),
          );
        } else {
          throw Exception("Erreur lors de la planification partielle");
        }
      }

      List<Planification> updatedPlanifications = [];

      for (int i = 0; i < widget.planifications.length; i++) {
        final plan = widget.planifications[i];
        final existingPlan = existingPlanMap[plan.id ?? ''];
        if (plan.statut == "waiting_resources") {
          updatedPlanifications.add(plan);
          continue;
        }

        if (_selectedSalles[i] == null) {
          Fluttertoast.showToast(
            msg: "Sélectionnez une salle pour toutes les planifications",
            backgroundColor: Colors.red,
          );
          return;
        }

        if (_selectedMachinesForPlanifications[i].isEmpty) {
          Fluttertoast.showToast(
            msg:
                "Sélectionnez au moins une machine pour toutes les planifications",
            backgroundColor: Colors.red,
          );
          return;
        }

        if (_startDates[i].isAfter(_endDates[i])) {
          Fluttertoast.showToast(
            msg: "La date de début doit être avant la date de fin",
            backgroundColor: Colors.red,
          );
          return;
        }

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

        updatedPlanifications.add(Planification(
          id: existingPlan?.id ?? plan.id ?? '',
          commandes: plan.commandes,
          machines: _availableMachines[i]
              .where(
                  (m) => _selectedMachinesForPlanifications[i].contains(m.id))
              .toList(),
          salle: _selectedSalles[i],
          debutPrevue: _startDates[i],
          finPrevue: _endDates[i],
          quantite: plan.quantite,
          taille: plan.taille,
          couleur: plan.couleur,
          statut: "planifiée",
        ));
      }

      for (var plan in updatedPlanifications) {
        if (plan.statut != "waiting_resources") {
          for (var commande in plan.commandes) {
            for (var modele in commande.modeles) {
              final key = '${modele.nomModele}_${modele.taille}';
              final matiereId = _matieresSelectionnees[key]!;
              final quantite = _quantitesConsommees[key]!;

              await ApiService.updateMatiere(matiereId, quantite,
                  action: "consommation");
            }
          }
        }
      }

      final success =
          await ApiService.confirmerPlanification(updatedPlanifications);

      if (!success) {
        throw Exception("Failed to confirm planifications");
      }
      widget.planifications.clear();
      widget.planifications.addAll(await ApiService.getWaitingPlanifications(
          commandeId: widget.commandeId));
      Fluttertoast.showToast(
        msg: "Planifications confirmées !",
        backgroundColor: Colors.blue[700],
        textColor: Colors.white,
      );

      final planifProvider =
          Provider.of<PlanificationProvider>(context, listen: false);
      await planifProvider.fetchPlanifications();

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
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
    //print('Building matiere selector for modele: ${modele.nomModele}');
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
    print(
        'Found ${matieresParCouleur.length} matieres for couleur ${modele.couleur}');

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

  Widget _buildPlanificationItem(int index, Planification planification) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    if (planification.statut == "waiting_resources") {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Planification ${index + 1} (En attente de ressources)",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                  "Client: ${planification.commandes.isNotEmpty ? planification.commandes.first.client.name : 'N/A'}"),
              Text("Modèle: ${planification.modele?.nom ?? 'N/A'}"),
              Text("Taille: ${planification.taille ?? 'N/A'}"),
              Text("Couleur: ${planification.couleur ?? 'N/A'}"),
              Text("Quantité: ${planification.quantite ?? 'N/A'}"),
              Text(
                  "Ajoutée le: ${planification.createdAt != null ? DateFormat('dd/MM/yyyy à HH:mm').format(planification.createdAt!) : 'N/A'}"),
              if (planification.machines.isNotEmpty)
                Text(
                    "Machine assignée: ${planification.machines.first.nom ?? 'N/A'}"),
              Text(
                "Matières sélectionnées:",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...planification.commandes.expand((c) => c.modeles).map((m) {
                final key = '${m.nomModele}_${m.taille}';
                final matiereId = _matieresSelectionnees[key];
                final matiere = matiereId != null
                    ? _matieres.firstWhere((m) => m.id == matiereId,
                        orElse: () => Matiere(
                              id: '',
                              reference: 'Non sélectionnée',
                              couleur: m.couleur,
                              quantite: 0,
                              dateAjout: DateTime.now(),
                              historique: [],
                            ))
                    : null;
                return Text(
                  "- ${m.nomModele} (${m.taille}): ${matiere?.reference ?? 'Non sélectionnée'}",
                  style: theme.textTheme.bodySmall,
                );
              }).toList(),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Planification ${index + 1}",
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Use the shared _salles list instead of making a new API call
            _salles.isEmpty
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<Salle>(
                    value: _selectedSalles[index],
                    decoration: const InputDecoration(
                      labelText: "Salle",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _salles
                        .map((salle) => DropdownMenuItem<Salle>(
                              value: salle,
                              child: Text("${salle.nom} (${salle.type})"),
                            ))
                        .toList(),
                    onChanged: (Salle? newValue) {
                      setState(() {
                        _selectedSalles[index] = newValue;
                        _selectedMachinesForPlanifications[index] = [];
                        if (newValue != null) {
                          _loadMachinesForSalle(index, newValue.id);
                        }
                      });
                    },
                  ),
            const SizedBox(height: 16),

            if (_selectedSalles[index] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Machines disponibles dans ${_selectedSalles[index]!.nom}:",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_availableMachines[index].isEmpty)
                    Text(
                      "Aucune machine disponible",
                      style: TextStyle(color: Colors.red[700]),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value:
                          _selectedMachinesForPlanifications[index].isNotEmpty
                              ? _selectedMachinesForPlanifications[index].first
                              : null,
                      decoration: const InputDecoration(
                        labelText: "Machine",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: _availableMachines[index]
                          .map((machine) => DropdownMenuItem<String>(
                                value: machine.id,
                                child: Text(
                                    "${machine.nom} (${machine.modele.nom})"),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          if (newValue != null) {
                            _selectedMachinesForPlanifications[index] = [
                              newValue
                            ];
                          } else {
                            _selectedMachinesForPlanifications[index] = [];
                          }
                        });
                      },
                    ),
                ],
              ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true, index),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Début",
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(dateFormat.format(_startDates[index])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false, index),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fin",
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(dateFormat.format(_endDates[index])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, bool isStartDate, int planIndex) async {
    final initialDate =
        isStartDate ? _startDates[planIndex] : _endDates[planIndex];

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDates[planIndex] = newDateTime;
          } else {
            _endDates[planIndex] = newDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //print('Building PlanificationConfirmationDialog with:');
    //print('- Planifications count: ${widget.planifications.length}');

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
                    ...widget.planifications.asMap().entries.map((entry) {
                      final index = entry.key;
                      final planification = entry.value;
                      return _buildPlanificationItem(index, planification);
                    }).toList(),
                    const SizedBox(height: 20),
                    Text(
                      "Consommation de matière",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...{
                      for (var p in widget.planifications)
                        //if (p.statut != "waiting_resources")
                        for (var c in p.commandes)
                          for (var m in c.modeles)
                            '${m.nomModele}_${m.taille}_${m.couleur}': m
                    }.values.map(_buildMatiereSelector),
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
