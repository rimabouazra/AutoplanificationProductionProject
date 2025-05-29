import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../models/modele.dart';
import '../models/planification.dart';
import '../providers/PlanificationProvider .dart';
import '../services/api_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
class PlanificationView extends StatefulWidget {
  @override
  _PlanificationViewState createState() => _PlanificationViewState();
}

class _PlanificationViewState extends State<PlanificationView> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSalleType = 'tous';
  String _selectedViewMode = 'semaine';
  String _selectedStatus = 'tous';
  int _startHour = 7;
  int _endHour = 17;
  bool _isDateRangeInitialized = false;
  List<Planification> _waitingPlanifications = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PlanificationProvider>(context, listen: false);
    _startHour = provider.startHour;
    _endHour = provider.endHour;
    _startDate = DateTime.now();
    provider.fetchPlanifications();
    _fetchWaitingPlanifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDateRangeInitialized && provider.planifications.isNotEmpty) {
        _calculateDateRange(provider.planifications);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
  Future<void> _terminerPlanification(String planificationId) async {
    try {
      final result = await ApiService.terminerPlanification(planificationId);
      if (result['success']) {
        _showSuccessSnackbar(result['message']);
        final provider = Provider.of<PlanificationProvider>(context, listen: false);
        await provider.fetchPlanifications(); // Refresh planifications
      } else {
        _showErrorSnackbar(result['message']);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _fetchWaitingPlanifications() async {
    try {
      final waitingPlans = await ApiService.getWaitingPlanifications();
      print("API Response: $waitingPlans");
      setState(() {
        _waitingPlanifications = waitingPlans;
      });
    } catch (e) {
      print("Erreur lors de la récupération des planifications en attente: $e");
    }
  }

  Future<void> _updateWaitingPlanificationOrder() async {
    try {
      final order = _waitingPlanifications.map((wp) => wp.id).toList();
      await ApiService.updateWaitingPlanificationOrder(order);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ordre des planifications mis à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour de l\'ordre')),
      );
    }
  }
  void _showUpdateWorkHoursDialog(BuildContext context) async {
    final provider = Provider.of<PlanificationProvider>(context, listen: false);
    int newStartHour = provider.startHour;
    int newEndHour = provider.endHour;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Modifier les heures de travail",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHourDropdown(
              value: newStartHour,
              onChanged: (value) => newStartHour = value !,
              hint: 'Heure de début',
            ),
            SizedBox(height: 8),
            _buildHourDropdown(
              value: newEndHour,
              onChanged: (value) => newEndHour = value !,
              hint: 'Heure de fin',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.deepPurple)),
          ),
          FutureBuilder<bool>(
            future: AuthService.isAdminOrManager(),
            builder: (context, snapshot) {
              final isAdminOrManager = snapshot.data ?? false;
              return TextButton(
                onPressed: isAdminOrManager && newStartHour != null && newEndHour != null
                    ? () async {
                  try {
                    await provider.updateWorkHours(newStartHour, newEndHour);
                    Navigator.pop(context);
                    _showSuccessSnackbar('Heures de travail mises à jour');
                    setState(() {
                      _startHour = newStartHour;
                      _endHour = newEndHour;
                    });
                  } catch (e) {
                    _showErrorSnackbar('Erreur: $e');
                  }
                }
                    : null,
                child: Text("Confirmer", style: TextStyle(color: Colors.deepPurple)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showWaitingPlanificationsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Planifications en Attente",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: _waitingPlanifications.isEmpty
              ? Center(
            child: Text(
              "Aucune planification en attente",
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
              : ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _waitingPlanifications.removeAt(oldIndex);
                _waitingPlanifications.insert(newIndex, item);
              });
              _updateWaitingPlanificationOrder();
            },
            children: _waitingPlanifications.asMap().entries.map((entry) {
              final index = entry.key;
              final waitingPlan = entry.value;
              final commande =
              waitingPlan.commandes.isNotEmpty ? waitingPlan.commandes.first : null;
              final modeleData =
              commande?.modeles.isNotEmpty == true ? commande!.modeles.first : null;

              Future<String?> getModelName() async {
                if (modeleData?.modele != null) {
                  if (modeleData!.modele is String) {
                    return await ApiService().getModeleNom(modeleData.modele as String);
                  } else if (modeleData!.modele is Modele) {
                    return (modeleData.modele as Modele).nom;
                  }
                }
                return 'Non spécifié';
              }

              return FadeInUp(
                key: ValueKey(waitingPlan.id),
                duration: Duration(milliseconds: 300 + index * 100),
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FutureBuilder<String?>(
                    future: getModelName(),
                    builder: (context, snapshot) {
                      final modelName = snapshot.data ?? 'Chargement...';
                      return ListTile(
                        contentPadding: EdgeInsets.all(12),
                        title: Text(
                          "Client: ${commande?.client.name ?? 'Inconnu'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.deepPurple,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                              "Modele: $modelName",
                              style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                            ),
                            Text(
                              "Taille: ${waitingPlan.taille ?? modeleData?.taille ?? 'Non spécifié'}",
                              style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                            ),
                            Text(
                              "Couleur: ${waitingPlan.couleur ?? modeleData?.couleur ?? 'Non spécifié'}",
                              style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                            ),
                            Text(
                              "Quantité: ${waitingPlan.quantite?.toString() ?? modeleData?.quantite?.toString() ?? 'Non spécifié'}",
                            style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                            ),
                            Text(
                              "Ajouté le :  ${waitingPlan.createdAt != null ? DateFormat("dd/MM/yyyy HH:mm").format(waitingPlan.createdAt!) : 'Non spécifié'}",
                              style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Fermer",
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmer la déconnexion"),
        content: Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
            child: Text("Déconnexion", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Planifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.access_time),
            onPressed: () => _showUpdateWorkHoursDialog(context),
            tooltip: 'Modifier les heures de travail',
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => _showWaitingPlanificationsDialog(context),
            tooltip: 'Voir les planifications en attente',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<PlanificationProvider>(context, listen: false);
              provider.fetchPlanifications();
              _fetchWaitingPlanifications();
              _isDateRangeInitialized = false;
              setState(() {
                _startDate = DateTime.now();
                _endDate = null;
              });
              if (provider.planifications.isNotEmpty) {
                _calculateDateRange(provider.planifications);
              }
            },
            tooltip: 'Rafraîchir les planifications',
          ),
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _startDate = DateTime.now();
                _endDate = null;
                _isDateRangeInitialized = false;
              });
            },
            tooltip: 'Réinitialiser la plage de dates',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Consumer<PlanificationProvider>(
        builder: (context, provider, child) {
          if (provider.planifications.isEmpty && _waitingPlanifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Chargement des planifications..."),
                ],
              ),
            );
          }

          if (!_isDateRangeInitialized && provider.planifications.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _calculateDateRange(provider.planifications);
            });
          }

          final filteredPlans = _filterPlanifications(provider.planifications);

          return Column(
            children: [
              _buildFilterBar(context, provider),
              Expanded(child: _buildPlanificationTable(filteredPlans)),
            ],
          );
        },
      ),
    );
  }

  List<Planification> _filterPlanifications(List<Planification> plans) {
    final provider = Provider.of<PlanificationProvider>(context, listen: false);
    return plans.where((p) {
      final date = p.debutPrevue;
      if (date == null) return false;

      DateTime rangeStart = _startDate ?? DateTime.now();
      DateTime rangeEnd;

      switch (_selectedViewMode) {
        case 'journée':
          rangeStart = DateTime(rangeStart.year, rangeStart.month, rangeStart.day, provider.startHour);
          rangeEnd = DateTime(rangeStart.year, rangeStart.month, rangeStart.day, provider.endHour);
          break;
        case 'semaine':
          rangeStart = rangeStart.subtract(Duration(days: rangeStart.weekday - 1));
          rangeStart = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
          rangeEnd = rangeStart.add(Duration(days: 6, hours: 23, minutes: 59));
          break;
        case 'mois':
          rangeStart = DateTime(rangeStart.year, rangeStart.month, 1);
          rangeEnd = DateTime(rangeStart.year, rangeStart.month + 1, 0, 23, 59);
          break;
        default:
          rangeEnd = _endDate ?? DateTime.now();
      }

      final timeMatch = !date.isBefore(rangeStart) && !date.isAfter(rangeEnd);
      final statusMatch = _selectedStatus == 'tous' ||
          p.statut == _selectedStatus ||
          (_selectedStatus == 'en attente' && p.statut == 'waiting_resources');
      final salleMatch =
          _selectedSalleType == 'tous' || (p.machines.isNotEmpty && p.machines.first.salle.type == _selectedSalleType);

      return timeMatch && statusMatch && salleMatch;
    }).toList();
  }
  void _calculateDateRange(List<Planification> planifications) {
    if (planifications.isEmpty || _isDateRangeInitialized) return;

    DateTime? maxDate;
    for (var plan in planifications) {
      if (plan.finPrevue != null && (maxDate == null || plan.finPrevue!.isAfter(maxDate))) {
        maxDate = plan.finPrevue!;
      }
    }

    setState(() {
      _endDate = maxDate?.add(Duration(days: 1)) ??
          switch (_selectedViewMode) {
            'journée' => _startDate!.add(Duration(days: 1, minutes: -1)),
            'semaine' => _startDate!
                .subtract(Duration(days: _startDate!.weekday - 1))
                .add(Duration(days: 6, hours: 23, minutes: 59)),
            'mois' => DateTime(_startDate!.year, _startDate!.month + 1, 0, 23, 59),
            _ => _startDate!.add(Duration(days: 7)),
          };
      _isDateRangeInitialized = true;
    });
  }


  Widget _buildFilterBar(BuildContext context, PlanificationProvider provider) {
    return FadeIn(
      duration: Duration(milliseconds: 500),
      child: Container(
        padding: EdgeInsets.all(8),
        color: Colors.grey[100],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDateSelector(context, true),
              if (_selectedViewMode == 'mois') ...[
                Text('à', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDateSelector(context, false),
              ],
              _buildDropdown(
                value: _selectedSalleType,
                items: ['tous', 'noir', 'blanc'],
                hint: 'Type de salle',
                onChanged: (value) => setState(() => _selectedSalleType = value),
                width: 120,
              ),
              _buildDropdown(
                value: _selectedViewMode,
                items: ['journée', 'semaine', 'mois'],
                hint: 'Mode de vue',
                onChanged: (value) {
                  setState(() {
                    _selectedViewMode = value!;
                    if (_startDate != null) {
                      switch (value) {
                        case 'journée':
                          _endDate = _startDate!.add(Duration(days: 1, minutes: -1));
                          break;
                        case 'semaine':
                          _endDate = _startDate!
                              .subtract(Duration(days: _startDate!.weekday - 1))
                              .add(Duration(days: 6, hours: 23, minutes: 59));
                          break;
                        case 'mois':
                          _endDate = DateTime(_startDate!.year, _startDate!.month + 1, 0, 23, 59);
                          break;
                      }
                    }
                  });
                },
                width: 120,
              ),
              if (_selectedViewMode == 'journée') ...[
                _buildHourDropdown(
                  value: _startHour,
                  onChanged: (value) => setState(() => _startHour = value!),
                  hint: 'Début',
                ),
                _buildHourDropdown(
                  value: _endHour,
                  onChanged: (value) => setState(() => _endHour = value!),
                  hint: 'Fin',
                ),
              ],
              _buildDropdown(
                value: _selectedStatus,
                items: ['tous', 'en attente', 'en cours', 'terminée'],
                hint: 'État',
                onChanged: (value) => setState(() => _selectedStatus = value!),
                width: 120,
              ),
              _buildZoomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, bool isStartDate) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
      label: Text(
        isStartDate
            ? (_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Date début')
            : (_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Date fin'),
        style: TextStyle(color: Colors.deepPurple, fontSize: 12),
      ),
      onPressed: () => _selectDate(context, isStartDate: isStartDate),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    double width = 120,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 12)),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item[0].toUpperCase() + item.substring(1),
              style: TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        underline: SizedBox(),
      ),
    );
  }

  Widget _buildHourDropdown({
    required int value,
    required ValueChanged<int?> onChanged,
    required String hint,
  }) {
    return Container(
      width: 70,
      padding: EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: DropdownButton<int>(
        isExpanded: true,
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 12)),
        items: List.generate(24, (index) => index)
            .map((hour) => DropdownMenuItem(
          value: hour,
          child: Text('$hour h', style: TextStyle(fontSize: 12)),
        ))
            .toList(),
        onChanged: onChanged,
        underline: SizedBox(),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [],
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          switch (_selectedViewMode) {
            case 'journée':
              _endDate = picked.add(Duration(days: 1, minutes: -1));
              break;
            case 'semaine':
              _endDate = picked
                  .subtract(Duration(days: picked.weekday - 1))
                  .add(Duration(days: 6, hours: 23, minutes: 59));
              break;
            case 'mois':
              _endDate = DateTime(picked.year, picked.month + 1, 0, 23, 59);
              break;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildPlanificationTable(List<Planification> planifications) {
    // Sort planifications by debutPrevue
    planifications.sort((a, b) => a.debutPrevue!.compareTo(b.debutPrevue!));
    Map<String, List<Planification>> groupedPlans = {};
    if (_selectedViewMode == 'semaine') {
      for (var plan in planifications) {
        final dayKey = DateFormat('EEEE dd/MM').format(plan.debutPrevue!);
        groupedPlans.putIfAbsent(dayKey, () => []).add(plan);
      }
    }

    // Define consistent text styles
    const headerTextStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
    const cellTextStyle = TextStyle(fontSize: 16);
    const dayHeaderStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 20);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: _selectedViewMode == 'semaine' && groupedPlans.isNotEmpty
            ? Column(
          children: groupedPlans.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    entry.key,
                    style: dayHeaderStyle,
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: DataTable(
                    columnSpacing: 12,
                    dataRowHeight: 70,
                    headingRowColor: MaterialStateColor.resolveWith(
                            (states) => Colors.deepPurple.withOpacity(0.1)),
                    columns: [
                      DataColumn(label: Text('Client', style: headerTextStyle)),
                      DataColumn(label: Text('Modèle', style: headerTextStyle)),
                      DataColumn(label: Text('Taille', style: headerTextStyle)),
                      DataColumn(label: Text('Machine', style: headerTextStyle)),
                      DataColumn(label: Text('Salle', style: headerTextStyle)),
                      DataColumn(label: Text('Début', style: headerTextStyle)),
                      DataColumn(label: Text('Fin', style: headerTextStyle)),
                      DataColumn(label: Text('Statut', style: headerTextStyle)),
                      DataColumn(label: Text('Actions', style: headerTextStyle)),
                    ],
                    rows: entry.value.asMap().entries.map((rowEntry) {
                      final plan = rowEntry.value;
                      final commande =
                      plan.commandes.isNotEmpty ? plan.commandes.first : null;
                      final modeleData = commande?.modeles.isNotEmpty == true
                          ? commande!.modeles.first
                          : null;

                      Future<String?> getModelName() async {
                        if (plan.modele != null) {
                          return plan.modele!.nom;
                        } else if (modeleData?.modele != null) {
                          if (modeleData!.modele is String) {
                            return await ApiService()
                                .getModeleNom(modeleData.modele as String);
                          } else if (modeleData!.modele is Modele) {
                            return (modeleData.modele as Modele).nom;
                          }
                        }
                        return 'Non spécifié';
                      }

                      return DataRow(
                        cells: [
                          DataCell(Text(
                            plan.commandes.isNotEmpty
                                ? plan.commandes.first.client.name
                                : 'Aucun client',
                            style: cellTextStyle,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(FutureBuilder<String?>(
                            future: getModelName(),
                            builder: (context, snapshot) {
                              final modelName = snapshot.data ?? 'Chargement...';
                              return Text(
                                modelName,
                                style: cellTextStyle,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          )),
                          DataCell(Text(
                            plan.taille ?? modeleData?.taille ?? 'Non spécifié',
                            style: cellTextStyle,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(
                            plan.machines.isNotEmpty
                                ? plan.machines.first.nom
                                : 'Aucune machine',
                            style: cellTextStyle,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(
                            plan.machines.isNotEmpty
                                ? plan.machines.first.salle.nom
                                : 'N/A',
                            style: cellTextStyle,
                            overflow: TextOverflow.ellipsis,
                          )),
                          DataCell(Text(
                            _formatDateTime(plan.debutPrevue),
                            style: cellTextStyle,
                          )),
                          DataCell(Text(
                            _formatDateTime(plan.finPrevue),
                            style: cellTextStyle,
                          )),
                          DataCell(_buildStatusBadge(plan.statut)),
                          DataCell(
                            FutureBuilder<bool>(
                              future: AuthService.isAdminOrManager(),
                              builder: (context, snapshot) {
                                final isAdminOrManager = snapshot.data ?? false;
                                return isAdminOrManager && plan.id != null
                                    ? ElevatedButton(
                                  onPressed: plan.statut == 'terminée'
                                      ? null
                                      : () => _terminerPlanification(plan.id !),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size(80, 30),
                                    textStyle: TextStyle(fontSize: 12),
                                  ),
                                  child: Text('Terminer'),
                                )
                                    : SizedBox.shrink();
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }).toList(),
        )
            : DataTable(
          columnSpacing: 12,
          dataRowHeight: 70,
          headingRowColor: MaterialStateColor.resolveWith(
                  (states) => Colors.deepPurple.withOpacity(0.1)),
          columns: [
            DataColumn(label: Text('Client', style: headerTextStyle)),
            DataColumn(label: Text('Modèle', style: headerTextStyle)),
            DataColumn(label: Text('Taille', style: headerTextStyle)),
            DataColumn(label: Text('Machine', style: headerTextStyle)),
            DataColumn(label: Text('Salle', style: headerTextStyle)),
            DataColumn(label: Text('Début', style: headerTextStyle)),
            DataColumn(label: Text('Fin', style: headerTextStyle)),
            DataColumn(label: Text('Statut', style: headerTextStyle)),
            DataColumn(label: Text('Actions', style: headerTextStyle)),
          ],
          rows: planifications.asMap().entries.map((entry) {
            final plan = entry.value;
            final commande =
            plan.commandes.isNotEmpty ? plan.commandes.first : null;
            final modeleData = commande?.modeles.isNotEmpty == true
                ? commande!.modeles.first
                : null;

            Future<String?> getModelName() async {
              if (plan.modele != null) {
                return plan.modele!.nom;
              } else if (modeleData?.modele != null) {
                if (modeleData!.modele is String) {
                  return await ApiService()
                      .getModeleNom(modeleData.modele as String);
                } else if (modeleData!.modele is Modele) {
                  return (modeleData.modele as Modele).nom;
                }
              }
              return 'Non spécifié';
            }

            return DataRow(
              cells: [
                DataCell(Text(
                  plan.commandes.isNotEmpty
                      ? plan.commandes.first.client.name
                      : 'Aucun client',
                  style: cellTextStyle,
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(FutureBuilder<String?>(
                  future: getModelName(),
                  builder: (context, snapshot) {
                    final modelName = snapshot.data ?? 'Chargement...';
                    return Text(
                      modelName,
                      style: cellTextStyle,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                )),
                DataCell(Text(
                  plan.taille ?? modeleData?.taille ?? 'Non spécifié',
                  style: cellTextStyle,
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(
                  plan.machines.isNotEmpty
                      ? plan.machines.first.nom
                      : 'Aucune machine',
                  style: cellTextStyle,
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(
                  plan.machines.isNotEmpty
                      ? plan.machines.first.salle.nom
                      : 'N/A',
                  style: cellTextStyle,
                  overflow: TextOverflow.ellipsis,
                )),
                DataCell(Text(
                  _formatDateTime(plan.debutPrevue),
                  style: cellTextStyle,
                )),
                DataCell(Text(
                  _formatDateTime(plan.finPrevue),
                  style: cellTextStyle,
                )),
                DataCell(_buildStatusBadge(plan.statut)),
                DataCell(
                  FutureBuilder<bool>(
                    future: AuthService.isAdminOrManager(),
                    builder: (context, snapshot) {
                      final isAdminOrManager = snapshot.data ?? false;
                      return isAdminOrManager && plan.id != null
                          ? ElevatedButton(
                        onPressed: plan.statut == 'terminée'
                            ? null
                            : () => _terminerPlanification(plan.id!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size(80, 30),
                          textStyle: TextStyle(fontSize: 12),
                        ),
                        child: Text('Terminer'),
                      )
                          : SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'en attente':
        return Colors.orange;
      case 'en cours':
        return Colors.blue;
      case 'terminée':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date != null) {
      tz.initializeTimeZones();
      final tunis = tz.getLocation('Africa/Tunis');
      // Convert UTC DateTime to Africa/Tunis
      final tunisDate = tz.TZDateTime.from(date, tunis);
      /*
      print("Raw UTC DateTime: $date");
      print("Converted Africa/Tunis DateTime: $tunisDate");
      print("Formatted DateTime: ${DateFormat('dd/MM/yyyy HH:mm').format(tunisDate)}");
      */
      return DateFormat('dd/MM/yyyy  HH:mm').format(tunisDate);
    }
    return '--/--/---- --:--';
  }

  Widget _buildStatusBadge(String statut) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(statut).withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statut[0].toUpperCase() + statut.substring(1),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(statut),
        ),
      ),
    );
  }
}