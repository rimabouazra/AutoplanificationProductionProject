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
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSalleType;
  String _selectedViewMode = 'journée';
  int _startHour = 7;
  int _endHour = 17;

  ScrollController _horizontalScrollController = ScrollController();
  // Add these to your state class
  final _headerHorizontalScrollController = ScrollController();
  final _contentHorizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();

    _headerHorizontalScrollController.dispose();
    _contentHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    Provider.of<PlanificationProvider>(context, listen: false).fetchPlanifications();
    _selectedSalleType = 'blanc';

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 4,
        actions: [


        ],
      ),
      body: Consumer<PlanificationProvider>(
        builder: (context, provider, child) {
          if (provider.planifications.isEmpty) {
            return const Center(child: Text("Aucune planification disponible"));
          }

          // Calculate date range if not set
          if (_startDate == null || _endDate == null) {
            _calculateDateRange(provider.planifications);
          }

          return Column(
            children: [
              _buildDateRangeSelector(context, provider),
              Expanded(
                child: _buildGanttChart(provider),
              ),
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

    // Add some padding to the date range
    _startDate = minDate.subtract(Duration(days: 1));
    _endDate = maxDate.add(Duration(days: 1));
  }

  Widget _buildDateRangeSelector(BuildContext context, PlanificationProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 16),
            label: Text(_startDate != null
                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                : 'Select start date'),
            onPressed: () => _selectDate(context, isStartDate: true),
          ),
          Text('à'),
          TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 16),
            label: Text(_endDate != null
                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                : 'Select end date'),
            onPressed: () => _selectDate(context, isStartDate: false),
          ),
          DropdownButton<String>(
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
          DropdownButton<String>(
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
        ],
      ),
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
        } else {
          _endDate = picked;
        }
      });
    }
  }



  Widget _buildGanttChart(PlanificationProvider provider) {
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
      headers = List.generate(7, (index) => DateFormat('EEE').format(_startDate!.add(Duration(days: index))));
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
                        child: Text('Planification', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    ...headers.map((h) => SizedBox(
                      width: timeSlotWidth,
                      child: Center(child: Text(h, style: TextStyle(fontWeight: FontWeight.bold))),
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
                      children: provider.planifications
                          .where((p) => p.machines.isNotEmpty && p.machines.first.salle.type == _selectedSalleType)
                          .map((plan) {
                        int startSlot = 0;
                        int duration = 1;

                        if (_selectedViewMode == 'journée') {
                          final startHour = plan.debutPrevue?.hour ?? _startHour;
                          final endHour = plan.finPrevue?.hour ?? startHour + 1;
                          startSlot = startHour - _startHour;
                          duration = (endHour - startHour).clamp(1, timeSlots);
                        } else if (_selectedViewMode == 'semaine' || _selectedViewMode == 'mois') {
                          startSlot = plan.debutPrevue != null ? plan.debutPrevue!.difference(_startDate!).inDays : 0;
                          duration = plan.finPrevue != null && plan.debutPrevue != null
                              ? plan.finPrevue!.difference(plan.debutPrevue!).inDays + 1
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Flexible(child: Text(plan.commandes.isNotEmpty ? plan.commandes.first.client : 'No client', overflow: TextOverflow.ellipsis)),
                                      Flexible(child: Text(plan.machines.isNotEmpty ? plan.machines.first.nom : 'No machine', style: TextStyle(fontSize: 12))),
                                      Flexible(child: Text('Salle: ${plan.machines.first.salle.nom}', style: TextStyle(fontSize: 12))),
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
                                        Row(children: List.generate(timeSlots, (index) => Container(
                                          width: timeSlotWidth,
                                          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey.shade200))),
                                        ))),
                                        Positioned(
                                          left: startSlot * timeSlotWidth,
                                          child: Container(
                                            width: duration * timeSlotWidth,
                                            height: 40,
                                            margin: EdgeInsets.symmetric(vertical: 15),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(plan.statut),
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${_formatTime(plan.debutPrevue)} - ${_formatTime(plan.finPrevue)}',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
      case "en attente": return Colors.orange;
      case "en cours": return Colors.blue;
      case "terminée": return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildStatut(String statut) {
    Color statutColor = _getStatusColor(statut);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: statutColor, size: 12),
          const SizedBox(width: 5),
          Text(
            statut.toUpperCase(),
            style: TextStyle(color: statutColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? date) {
    return date != null ? DateFormat('HH:mm').format(date) : "--:--";
  }
}