import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/planification.dart';
import '../providers/PlanificationProvider .dart';

class PlanificationView extends StatefulWidget {
  @override
  _PlanificationViewState createState() => _PlanificationViewState();
}

class _PlanificationViewState extends State<PlanificationView> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSalleType;
  String _selectedViewMode = 'journée';
  String _selectedStatus = 'tous';
  int _startHour = 7;
  int _endHour = 17;

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
          if (provider.planifications.isEmpty) {
            return const Center(child: Text("Aucune planification disponible"));
          }

          if (_startDate == null || _endDate == null) {
            _calculateDateRange(provider.planifications);
          }

          // Filtrage des planifications
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
              Expanded(child: _buildGanttChart(filteredPlans)),
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

    final rowHeight = 70.0;
    final headerHeight = 60.0;
    final infoColumnWidth = 200.0;
    final timeSlotWidth = 100.0;

    List<String> headers = [];
    int timeSlots = 0;

    if (_selectedViewMode == 'journée') {
      timeSlots = _endHour - _startHour;
      headers = List.generate(timeSlots, (index) => '${_startHour + index}h');
    } else if (_selectedViewMode == 'semaine') {
      timeSlots = 7;
      headers = List.generate(
          7,
          (index) =>
              DateFormat('EEE').format(_startDate!.add(Duration(days: index))));
    } else if (_selectedViewMode == 'mois') {
      timeSlots = DateTime(_endDate!.year, _endDate!.month + 1, 0).day;
      headers = List.generate(timeSlots, (index) => '${index + 1}');
    }

    final totalContentWidth = timeSlots * timeSlotWidth;
    final totalWidth = totalContentWidth + infoColumnWidth;

    return Column(
      children: [
        // HEADER
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
                    ...headers.map((h) => Flexible(
                          child: SizedBox(
                            width: timeSlotWidth,
                            child: Center(
                                child: Text(h,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),

        // CONTENT
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
                      children: planifications.map((plan) {
                        int startSlot = 0;
                        int duration = 1;

                        if (_selectedViewMode == 'journée') {
                          final startHour =
                              plan.debutPrevue?.hour ?? _startHour;
                          final endHour = plan.finPrevue?.hour ?? startHour + 1;
                          startSlot = startHour - _startHour;
                          duration = (endHour - startHour).clamp(1, timeSlots);
                        } else if (_selectedViewMode == 'semaine' ||
                            _selectedViewMode == 'mois') {
                          startSlot = plan.debutPrevue != null
                              ? plan.debutPrevue!.difference(_startDate!).inDays
                              : 0;
                          duration =
                              plan.finPrevue != null && plan.debutPrevue != null
                                  ? plan.finPrevue!
                                          .difference(plan.debutPrevue!)
                                          .inDays +
                                      1
                                  : 1;
                        }

                        return SizedBox(
                          height: rowHeight,
                          child: Row(
                            children: [
                              // INFO
                              SizedBox(
                                width: infoColumnWidth,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                          child: Text(plan.commandes.isNotEmpty
                                              ? plan.commandes.first.client.name
                                              : 'No client')),
                                      Flexible(
                                          child: Text(
                                              plan.machines.isNotEmpty
                                                  ? plan.machines.first.nom
                                                  : 'No machine',
                                              style: TextStyle(fontSize: 12))),
                                      Flexible(
                                          child: Text(
                                              'Salle: ${plan.machines.first.salle.nom}',
                                              style: TextStyle(fontSize: 12))),
                                      _buildStatut(plan.statut),
                                    ],
                                  ),
                                ),
                              ),

                              // BAR
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
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200))),
                                                    ))),
                                        Positioned(
                                          left: startSlot * timeSlotWidth,
                                          child: Container(
                                            width: duration * timeSlotWidth,
                                            height: 40,
                                            margin: EdgeInsets.symmetric(
                                                vertical: 15),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getStatusColor(plan.statut),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 4,
                                                    offset: Offset(2, 2))
                                              ],
                                            ),
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    plan.commandes.isNotEmpty ? plan.commandes.first.client.name : '',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white),
                                                  ),
                                                  Text(
                                                      '${_formatTime(plan.debutPrevue)} - ${_formatTime(plan.finPrevue)}',
                                                      style: TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 12)),
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
                      }).toList(),
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