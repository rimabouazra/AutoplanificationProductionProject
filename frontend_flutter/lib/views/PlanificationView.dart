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
          IconButton(
            icon: Icon(Icons.today),
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
            },
            tooltip: 'Reset date range',
          ),
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
          Text('to'),
          TextButton.icon(
            icon: Icon(Icons.calendar_today, size: 16),
            label: Text(_endDate != null
                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                : 'Select end date'),
            onPressed: () => _selectDate(context, isStartDate: false),
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              // Implement filtering if needed
            },
            tooltip: 'Filter planifications',
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

    final days = _endDate!.difference(_startDate!).inDays + 1;
    final dayWidth = 100.0;
    final rowHeight = 70.0;
    final headerHeight = 60.0;
    final infoColumnWidth = 200.0;

    // Calculate total width needed
    final totalContentWidth = days * dayWidth;
    final totalWidth = totalContentWidth + infoColumnWidth;

    // Sync horizontal scrolling between header and content
    _headerHorizontalScrollController.addListener(() {
      _contentHorizontalScrollController.jumpTo(_headerHorizontalScrollController.offset);
    });

    _contentHorizontalScrollController.addListener(() {
      _headerHorizontalScrollController.jumpTo(_contentHorizontalScrollController.offset);
    });

    return Column(
      children: [
        // Header - fixed and horizontally scrollable
        SizedBox(
          height: headerHeight,
          child: Scrollbar(
            controller: _headerHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _headerHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Container(
                  width: totalWidth,
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: infoColumnWidth,
                        child: Center(
                          child: Text('Planification',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      ...List.generate(days, (index) {
                        final date = _startDate!.add(Duration(days: index));
                        return SizedBox(
                          width: dayWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(DateFormat('EEE').format(date),
                                  style: TextStyle(fontSize: 12)),
                              Text(DateFormat('dd/MM').format(date),
                                  style: TextStyle(fontWeight: FontWeight.bold)),
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
        // Divider
        Container(height: 1, color: Colors.grey.shade300),
        // Content - vertically and horizontally scrollable
        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              scrollDirection: Axis.vertical,
              physics: ClampingScrollPhysics(),
              child: Scrollbar(
                controller: _contentHorizontalScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _contentHorizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width,
                      minHeight: provider.planifications.length * rowHeight,
                    ),
                    child: Container(
                      width: totalWidth,
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: provider.planifications.map((plan) {
                          final startOffset = plan.debutPrevue != null
                              ? plan.debutPrevue!.difference(_startDate!).inDays
                              : 0;
                          final duration = plan.debutPrevue != null && plan.finPrevue != null
                              ? plan.finPrevue!.difference(plan.debutPrevue!).inDays + 1
                              : 1;

                          return SizedBox(
                            height: rowHeight,
                            child: Row(
                              children: [
                                // Info column (fixed)
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
                                            '${plan.commandes.isNotEmpty ? plan.commandes.first.client : 'No client'}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            '${plan.machines.isNotEmpty ? plan.machines.first.nom : 'No machine'}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            'Salle: ${plan.machines.isNotEmpty ? plan.machines.first.salle.nom : 'N/A'}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        _buildStatut(plan.statut),
                                      ],
                                    ),
                                  ),
                                ),
                                // Gantt chart area (scrollable)
                                Expanded(
                                  child: SizedBox(
                                    width: totalContentWidth,
                                    child: Stack(
                                      children: [
                                        // Background grid
                                        Row(
                                          children: List.generate(days, (index) => Container(
                                            width: dayWidth,
                                            decoration: BoxDecoration(
                                              border: Border(right: BorderSide(color: Colors.grey.shade100)),
                                            ),
                                          )),
                                        ),
                                        // Gantt bar
                                        if (plan.debutPrevue != null && plan.finPrevue != null)
                                          Positioned(
                                            left: startOffset * dayWidth,
                                            child: Container(
                                              width: duration * dayWidth,
                                              height: 40,
                                              margin: EdgeInsets.symmetric(vertical: 15),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(plan.statut),
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 2,
                                                    offset: Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${_formatTime(plan.debutPrevue)} - ${_formatTime(plan.finPrevue)}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
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