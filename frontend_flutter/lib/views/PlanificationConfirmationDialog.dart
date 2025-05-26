import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/providers/PlanificationProvider%20.dart';
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
  bool _hasError = false;
  List<Matiere> _matieres = [];
  final Map<String, String?> _matieresSelectionnees = {};
  final Map<String, double> _quantitesConsommees = {};

  List<Salle?> _selectedSalles = [];
  List<List<String>> _selectedMachinesForPlanifications = [];
  List<DateTime> _startDates = [];
  List<DateTime> _endDates = [];
  List<List<Machine>> _availableMachines = [];
  List<Salle> _salles = [];

  bool _partialPlanning = false;

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
              setState(() => _partialPlanning = true);
              Navigator.pop(context);
            },
            child: const Text("Planifier partiellement"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _partialPlanning = false);
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
      setState(() => _isLoading = true);
      final sallesData = await ApiService.getSalles();
      final salleMap = {for (var s in sallesData) s.id: s};

      setState(() {
        _salles = sallesData;
        _selectedSalles =
            List.generate(widget.planifications.length, (_) => null);

        for (var i = 0; i < widget.planifications.length; i++) {
          final planification = widget.planifications[i];
          Salle? salle = planification.salle;
          if (salle != null) {
            _selectedSalles[i] = salleMap[salle.id];
          }
          final machines = planification.machines;
          for (var machine in machines) {
            final matchedSalle = salleMap[machine.salle.id] ??
                Salle(id: machine.salle.id, nom: '', type: '', machines: []);
            machine.salle.nom = matchedSalle.nom;
            machine.salle.type = matchedSalle.type;
          }
        }
        _hasError = false;
      });
    } catch (e) {
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Erreur lors du chargement des salles et machines"),
          action: SnackBarAction(
            label: "Réessayer",
            onPressed: _loadSallesAndMachines,
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMatieres() async {
    try {
      setState(() => _isLoading = true);
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
      setState(() => _hasError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Erreur lors du chargement des matières"),
          action: SnackBarAction(
            label: "Réessayer",
            onPressed: _loadMatieres,
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMachinesForSalle(int planIndex, String salleId) async {
    try {
      final machines = await ApiService.getMachinesParSalle(salleId);
      setState(() {
        _availableMachines[planIndex] =
            machines.where((m) => m.etat == "disponible").toList();
        _selectedMachinesForPlanifications[planIndex] =
            _selectedMachinesForPlanifications[planIndex]
                .where((id) =>
                    _availableMachines[planIndex].any((m) => m.id == id))
                .toList();
        if (_selectedMachinesForPlanifications[planIndex].isEmpty &&
            _availableMachines[planIndex].isNotEmpty) {
          _selectedMachinesForPlanifications[planIndex] = [
            _availableMachines[planIndex].first.id
          ];
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des machines")),
      );
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
      return 0;
    }
  }

  Map<String, bool> _checkStockAvailability(Planification plan) {
    bool hasStockIssue = false;
    bool hasMachineIssue = plan.machines.isEmpty;

    for (var commande in plan.commandes) {
      for (var modele in commande.modeles) {
        final key = '${modele.nomModele}_${modele.taille}';
        final matiereId = _matieresSelectionnees[key];
        final quantiteNecessaire = _quantitesConsommees[key] ?? 0;

        if (matiereId != null) {
          final matiere = _matieres.firstWhere((m) => m.id == matiereId);
          if (matiere.quantite < quantiteNecessaire) {
            hasStockIssue = true;
          }
        } else {
          hasStockIssue = true;
        }
      }
    }

    return {
      'stockIssue': hasStockIssue,
      'machineIssue': hasMachineIssue,
    };
  }

  Future<void> _confirmPlanification() async {
    print('Confirming planifications: ${widget.planifications.map((p) => p.toJson()).toList()}');//debug
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer les Planifications"),
        content: const Text(
            "Voulez-vous vraiment confirmer ces planifications ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final existingPlanifications = await ApiService.getWaitingPlanifications(
          commandeId: widget.commandeId);
      final Map<String, Planification> existingPlanMap = {
        for (var p in existingPlanifications) p.id!: p
      };

      for (var plan in widget.planifications) {
        for (var commande in plan.commandes) {
          for (var modele in commande.modeles) {
            final key = '${modele.nomModele}_${modele.taille}';
            if (_matieresSelectionnees[key] == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "Sélectionnez une matière pour tous les modèles")),
              );
              return;
            }
          }
        }
      }

      if (widget.hasInsufficientStock && !_partialPlanning) {
        List<Planification> waitingPlans = [];
        for (var plan in widget.planifications) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Planifications mises en attente de stock")),
          );
          Navigator.pop(context);
          return;
        }
      }

      List<Planification> updatedPlanifications = [];

      for (int i = 0; i < widget.planifications.length; i++) {
        final plan = widget.planifications[i];
        final existingPlan = existingPlanMap[plan.id ?? ''];
        if (plan.statut == "waiting_resources") {
          updatedPlanifications.add(existingPlan ?? plan);
          continue;
        }

        if (_selectedSalles[i] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("Sélectionnez une salle pour toutes les planifications")),
          );
          return;
        }

        if (_selectedMachinesForPlanifications[i].isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Sélectionnez au moins une machine pour toutes les planifications")),
          );
          return;
        }

        if (_startDates[i].isAfter(_endDates[i])) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("La date de début doit être avant la date de fin")),
          );
          return;
        }

        updatedPlanifications.add(Planification(
          id: existingPlan?.id ?? plan.id ?? '',
          commandes: plan.commandes,
          machines: _availableMachines[i]
              .where((m) => _selectedMachinesForPlanifications[i].contains(m.id))
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

      if (!_partialPlanning) {
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
      } else {
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
          updatedPlanifications = widget.planifications;
        } else {
          throw Exception("Erreur lors de la planification partielle");
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Planifications confirmées !")),
      );

      final planifProvider =
          Provider.of<PlanificationProvider>(context, listen: false);
      await planifProvider.fetchPlanifications();

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMatiereSelector(CommandeModele modele, String planificationStatus) {
    final modeleKey = '${modele.nomModele}_${modele.taille}';

    final quantiteNecessaire = _quantitesConsommees[modeleKey] ?? 0;
    var matieresParCouleur = _matieres
        .where((m) =>
            m.couleur.toLowerCase().contains(modele.couleur.toLowerCase()) ||
            modele.couleur.toLowerCase().contains(m.couleur.toLowerCase()))
        .toList();

    final matieresDisponibles = matieresParCouleur.map((m) {
      final suffisant = m.quantite >= quantiteNecessaire;
      return {'matiere': m, 'suffisant': suffisant};
    }).toList();

    final isWaiting = planificationStatus == "waiting_resources";
    final hasStockIssue = matieresDisponibles.any((entry) =>
        !(entry['suffisant'] as bool) &&
        (entry['matiere'] as Matiere).id == _matieresSelectionnees[modeleKey]);

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${modele.nomModele} (${modele.taille}, ${modele.couleur})",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                      semanticsLabel:
                          "Modèle ${modele.nomModele}, taille ${modele.taille}, couleur ${modele.couleur}",
                    ),
                  ),
                  if (isWaiting && hasStockIssue)
                    Tooltip(
                      message: "Stock insuffisant pour cette matière",
                      child: Icon(Icons.warning, color: Colors.red[700], size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Quantité nécessaire: ${quantiteNecessaire.toStringAsFixed(2)} m",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (matieresDisponibles.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _matieresSelectionnees[modeleKey],
                  decoration: InputDecoration(
                    labelText: isWaiting
                        ? "Matière sélectionnée (en attente)"
                        : "Sélectionner la matière",
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  onChanged: isWaiting
                      ? null
                      : (value) {
                          setState(() {
                            _matieresSelectionnees[modeleKey] = value;
                          });
                        },
                )
              else
                Text(
                  "Aucune matière disponible en stock",
                  style: TextStyle(color: Colors.red[700]),
                  semanticsLabel: "Aucune matière disponible",
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildPlanificationItem(int index, Planification planification) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final issues = _checkStockAvailability(planification);
    final waitingReason = issues['stockIssue']!
        ? "En attente de matière"
        : issues['machineIssue']!
            ? "En attente de machine/modèle"
            : "Ressources insuffisantes";

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (planification.statut == "waiting_resources") {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(
              "Planification ${index + 1} ($waitingReason)",
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
              semanticsLabel: "Planification ${index + 1}, $waitingReason",
            ),
            leading: Icon(
              issues['stockIssue']!
                  ? Icons.inventory
                  : Icons.build,
              color: Colors.orange[800],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        "Client: ${planification.commandes.isNotEmpty ? planification.commandes.first.client.name : 'N/A'}",
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: Text("Modèle: ${planification.modele?.nom ?? 'N/A'}"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.straighten),
                      title: Text("Taille: ${planification.taille ?? 'N/A'}"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: Text("Couleur: ${planification.couleur ?? 'N/A'}"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.numbers),
                      title: Text("Quantité: ${planification.quantite ?? 'N/A'}"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                          "Ajoutée le: ${planification.createdAt != null ? dateFormat.format(planification.createdAt!) : 'N/A'}"),
                    ),
                    if (planification.machines.isNotEmpty)
                      ListTile(
                        leading: const Icon(Icons.build),
                        title: Text(
                            "Machine assignée: ${planification.machines.first.nom ?? 'N/A'}"),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Planification ${index + 1}",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: "Planification ${index + 1}",
              ),
              const SizedBox(height: 16),
              if (_salles.isEmpty && !_hasError)
                const Center(child: CircularProgressIndicator())
              else if (_hasError)
                Center(
                  child: Column(
                    children: [
                      const Text("Erreur de chargement des salles"),
                      TextButton(
                        onPressed: _loadSallesAndMachines,
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Salle>(
                  value: _selectedSalles[index],
                  decoration: const InputDecoration(
                    labelText: "Salle",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        semanticsLabel: "Aucune machine disponible",
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedMachinesForPlanifications[index]
                                .isNotEmpty
                            ? _selectedMachinesForPlanifications[index].first
                            : null,
                        decoration: const InputDecoration(
                          labelText: "Machine",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
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
                          border: Border.all(color: Colors.blue[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Stack(
        children: [
          ConstrainedBox(
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
                      Icon(Icons.calendar_today,
                          color: Colors.blue[700], size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Confirmer la Planification",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                          semanticsLabel: "Confirmer la Planification",
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                        tooltip: "Fermer",
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...widget.planifications
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final planification = entry.value;
                                return _buildPlanificationItem(
                                    index, planification);
                              }).toList(),
                              const SizedBox(height: 20),
                              Text(
                                "Consommation de matière",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                                semanticsLabel: "Consommation de matière",
                              ),
                              const SizedBox(height: 8),
                              ...{
                                for (var p in widget.planifications)
                                  for (var c in p.commandes)
                                    for (var m in c.modeles)
                                      '${m.nomModele}_${m.taille}_${m.couleur}': m
                              }.values.map((modele) => _buildMatiereSelector(
                                  modele,
                                  widget.planifications
                                      .firstWhere((p) => p.commandes
                                          .any((c) => c.modeles.contains(modele)))
                                      .statut)),
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
                          foregroundColor: Colors.blue[900],
                          side: BorderSide(color: Colors.blue[900]!),
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
                          elevation: 4,
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
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
