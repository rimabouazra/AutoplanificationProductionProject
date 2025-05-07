import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/WaitingPlanification.dart';
import '../models/planification.dart';
import '../providers/PlanificationProvider .dart';
import '../services/api_service.dart';

class PlanificationView extends StatefulWidget {
  @override
  _PlanificationViewState createState() => _PlanificationViewState();
}

class _PlanificationViewState extends State<PlanificationView> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSalleType;
  String _selectedViewMode = 'journée';
  String _selectedStatus = 'en cours';
  int _startHour = 7;
  int _endHour = 17;
  List<WaitingPlanification> _waitingPlanifications = [];

  final _headerHorizontalScrollController = ScrollController();
  final _contentHorizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _headerHorizontalScrollController.dispose();
    _contentHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Provider.of<PlanificationProvider>(context, listen: false)
        .fetchPlanifications();
    _fetchWaitingPlanifications();
    _selectedSalleType = 'blanc';
    _headerHorizontalScrollController.addListener(() {
      if (_contentHorizontalScrollController.offset !=
          _headerHorizontalScrollController.offset) {
        _contentHorizontalScrollController
            .jumpTo(_headerHorizontalScrollController.offset);
      }
    });
    _contentHorizontalScrollController.addListener(() {
      if (_headerHorizontalScrollController.offset !=
          _contentHorizontalScrollController.offset) {
        _headerHorizontalScrollController
            .jumpTo(_contentHorizontalScrollController.offset);
      }
    });
  }
  void _showWaitingPlanificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Planifications en Attente",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 400),
          child: _waitingPlanifications.isEmpty
              ? Center(child: Text("Aucune planification en attente"))
              : ListView.builder(
            itemCount: _waitingPlanifications.length,
            itemBuilder: (context, index) {
              final waitingPlan = _waitingPlanifications[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    "Client: ${waitingPlan.commande.client.name}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Modèle: ${waitingPlan.modele.nom}"),
                      Text("Taille: ${waitingPlan.taille}"),
                      Text("Couleur: ${waitingPlan.couleur}"),
                      Text("Quantité: ${waitingPlan.quantite}"),
                      Text(
                        "Ajouté le: ${DateFormat('dd/MM/yyyy HH:mm').format(waitingPlan.createdAt)}",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWaitingPlanifications() async {
    try {
      final waitingPlans = await ApiService.getWaitingPlanifications();
      setState(() {
        _waitingPlanifications = waitingPlans;
      });
    } catch (e) {
      print("Erreur lors de la récupération des planifications en attente: $e");
    }
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
        title: const Text("Planifications",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[50],
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () => _showWaitingPlanificationsDialog(context),
            tooltip: 'Voir les planifications en attente',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
            },
            tooltip: 'Réinitialiser la plage de dates',
          ),
        ],
      ),
      body: Consumer<PlanificationProvider>(
        builder: (context, provider, child) {
          if (provider.planifications.isEmpty && _waitingPlanifications.isEmpty) {
            return const Center(child: Text("Aucune planification disponible"));
          }

          if (_startDate == null || _endDate == null) {
            _calculateDateRange(provider.planifications);
          }

          final filteredPlans = provider.planifications.where((p) {
            final date = p.debutPrevue;
            final statusMatch = _selectedStatus == 'tous' || p.statut == _selectedStatus;
            return date != null &&
                (_startDate == null || !date.isBefore(_startDate!)) &&
                (_endDate == null || !date.isAfter(_endDate!)) &&
                p.machines.isNotEmpty &&
                p.machines.first.salle.type == _selectedSalleType &&
                statusMatch;
          }).toList();

          return Column(
            children: [
              _buildDateRangeSelector(context, provider),
              Flexible(child: Expanded(child: _buildGanttChart(filteredPlans))),
            ],
          );
        },
      ),
    );
  }

  void _calculateDateRange(List<Planification> planifications) {
    if (planifications.isEmpty) return;

    DateTime minDate = planifications.first.debutPrevue ?? DateTime.now();
    DateTime maxDate = planifications.first.finPrevue ?? DateTime.now();

    for (var plan in planifications) {
      if (plan.debutPrevue != null && plan.debutPrevue!.isBefore(minDate)) {
        minDate = plan.debutPrevue!;
      }
      if (plan.finPrevue != null && plan.finPrevue!.isAfter(maxDate)) {
        maxDate = plan.finPrevue!;
      }
    }

    _startDate = minDate.subtract(Duration(days: 1));
    _endDate = maxDate.add(Duration(days: 1));
  }

  Widget _buildDateRangeSelector(
      BuildContext context, PlanificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            TextButton.icon(
              icon: Icon(Icons.calendar_today, size: 16),
              label: Text(_startDate != null
                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                  : 'Date début'),
              onPressed: () => _selectDate(context, isStartDate: true),
            ),
            const SizedBox(width: 8),
            Text('à'),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: Icon(Icons.calendar_today, size: 16),
              label: Text(_endDate != null
                  ? DateFormat('dd/MM/yyyy').format(_endDate!)
                  : 'Date fin'),
              onPressed: () => _selectDate(context, isStartDate: false),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 130),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedSalleType,
                hint: Text("Type de salle"),
                items: ['noir', 'blanc'].map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type[0].toUpperCase() + type.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSalleType = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 130),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedViewMode,
                items: ['journée', 'semaine', 'mois'].map((mode) {
                  return DropdownMenuItem<String>(
                    value: mode,
                    child: Text(mode[0].toUpperCase() + mode.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedViewMode = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedViewMode == 'journée') ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 80),
                child: DropdownButton<int>(
                  value: _startHour,
                  onChanged: (value) {
                    setState(() => _startHour = value!);
                  },
                  items: List.generate(24, (index) => index).map((hour) =>
                      DropdownMenuItem(value: hour, child: Text('$hour h'))
                  ).toList(),
                  hint: Text("Début"),
                ),
              ),
              SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 80),
                child: DropdownButton<int>(
                  value: _endHour,
                  onChanged: (value) {
                    setState(() => _endHour = value!);
                  },
                  items: List.generate(24, (index) => index).map((hour) =>
                      DropdownMenuItem(value: hour, child: Text('$hour h'))
                  ).toList(),
                  hint: Text("Fin"),
                ),
              ),
              SizedBox(width: 8),
            ],
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 130),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedStatus,
                hint: Text("Filtrer par état"),
                items: ["tous", "en attente", "en cours", "terminée"].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status[0].toUpperCase() + status.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Widget _buildGanttChart(List<Planification> planifications) {
    if (_startDate == null || _endDate == null) {
      return Center(child: CircularProgressIndicator());
    }

    const rowHeight = 70.0;
    const headerHeight = 60.0;
    const infoColumnWidth = 200.0;
    const timeSlotWidth = 100.0;

    List<String> headers = [];
    int timeSlots = 0;

    if (_selectedViewMode == 'journée') {
      timeSlots = _endHour - _startHour + 1;
      headers = List.generate(timeSlots, (index) => '${_startHour + index}h');
    } else if (_selectedViewMode == 'semaine') {
      timeSlots = 7;
      headers = List.generate(
        7,
            (index) {
          final date = _startDate!.add(Duration(days: index));
          return '${DateFormat('EEE dd/MM').format(date)}';
        },
      );
    } else if (_selectedViewMode == 'mois') {
      timeSlots = DateTime(_endDate!.year, _endDate!.month + 1, 0).day;
      final monthName = DateFormat('MMMM yyyy').format(_startDate!);
      headers = ['Mois : $monthName'] + List.generate(timeSlots, (index) => '${index + 1}');
      timeSlots += 1;
    }

    final totalContentWidth = timeSlots * timeSlotWidth;
    final totalWidth = totalContentWidth + infoColumnWidth;

    return Column(
      children: [
        SizedBox(
          height: headerHeight,
          child: Scrollbar(
            controller: _headerHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _headerHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: totalWidth,
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: infoColumnWidth,
                      child: Center(
                        child: Text('Planification',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    ...headers.map((h) => SizedBox(
                      width: timeSlotWidth,
                      child: Text(h, style: TextStyle(fontWeight: FontWeight.bold)),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),

        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              child: Scrollbar(
                controller: _contentHorizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _contentHorizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: totalWidth,
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Active Planifications
                        ...planifications.map((plan) {
                          double startSlot = 0;
                          double duration = 1;

                          if (_selectedViewMode == 'journée') {
                            final debut = plan.debutPrevue ?? DateTime.now();
                            final fin = plan.finPrevue ?? debut.add(Duration(hours: 1));

                            final totalMinutesInDay = (_endHour - _startHour) * 60;
                            final startMinutes =
                                (debut.hour - _startHour) * 60 + debut.minute;
                            final endMinutes =
                                (fin.hour - _startHour) * 60 + fin.minute;

                            startSlot = (startMinutes / 60);
                            duration = ((endMinutes - startMinutes) / 60).clamp(0.2, timeSlots.toDouble());
                          } else if (_selectedViewMode == 'semaine' || _selectedViewMode == 'mois') {
                            startSlot = plan.debutPrevue != null
                                ? plan.debutPrevue!.difference(_startDate!).inDays.toDouble()
                                : 0;
                            duration = plan.finPrevue != null && plan.debutPrevue != null
                                ? plan.finPrevue!.difference(plan.debutPrevue!).inDays + 1
                                : 1;
                          }

                          return SizedBox(
                            height: rowHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: infoColumnWidth,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            plan.commandes.isNotEmpty
                                                ? plan.commandes.first.client.name
                                                : 'No client',
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            plan.machines.isNotEmpty
                                                ? plan.machines.first.nom
                                                : 'No machine',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Salle: ${plan.machines.first.salle.nom}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        _buildStatut(plan.statut),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: SizedBox(
                                      width: totalContentWidth,
                                      child: Stack(
                                        children: [
                                          Row(
                                            children: List.generate(
                                              timeSlots,
                                                  (index) => Container(
                                                width: timeSlotWidth,
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    right: BorderSide(
                                                      color: Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: startSlot * timeSlotWidth,
                                            child: Container(
                                              width: duration * timeSlotWidth,
                                              height: 40,
                                              margin: EdgeInsets.symmetric(vertical: 15),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(plan.statut),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 4,
                                                    offset: Offset(2, 2),
                                                  )
                                                ],
                                              ),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      plan.commandes.isNotEmpty
                                                          ? plan.commandes.first.client.name
                                                          : '',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${_formatTime(plan.debutPrevue)} - ${_formatTime(plan.finPrevue)}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Waiting Planifications
                        ..._waitingPlanifications.map((waitingPlan) {
                          return SizedBox(
                            height: rowHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: infoColumnWidth,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            waitingPlan.commande.client.name,
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Modèle: ${waitingPlan.modele.nom}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Taille: ${waitingPlan.taille}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        _buildStatut('en attente'),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    margin: EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[300],
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(2, 2),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        'En attente de machine',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case "en attente":
        return Colors.orange;
      case "en cours":
        return Colors.blue;
      case "terminée":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime? date) {
    return date != null ? DateFormat('HH:mm').format(date) : "--:--";
  }
}

Widget _buildStatut(String statut) {
  return Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.teal.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      statut,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}