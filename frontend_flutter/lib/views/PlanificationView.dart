import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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
  String? _selectedSalleType = 'blanc';
  String _selectedViewMode = 'journée';
  String _selectedStatus = 'en cours';
  int _startHour = 7;
  int _endHour = 17;
  double _timeScale = 1.0; // Zoom pour l'échelle temporelle
  bool _isDateRangeInitialized = false;
  List<WaitingPlanification> _waitingPlanifications = [];

  final _headerHorizontalScrollController = ScrollController();
  final _contentHorizontalScrollController = ScrollController();
  final _verticalScrollController = ScrollController();
  bool _isSyncingHeader = false;
  bool _isSyncingContent = false;

  @override
  void initState() {
    super.initState();
    // Charger les planifications au démarrage
    final provider = Provider.of<PlanificationProvider>(context, listen: false);
    provider.fetchPlanifications();
    _fetchWaitingPlanifications();
    // Synchronisation des contrôleurs de défilement
    _headerHorizontalScrollController.addListener(_syncHeaderScroll);
    // Initialiser la plage de dates après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDateRangeInitialized && provider.planifications.isNotEmpty) {
        _calculateDateRange(provider.planifications);
      }
    });
  }

  @override
  void dispose() {
    _headerHorizontalScrollController.removeListener(_syncHeaderScroll);
    _contentHorizontalScrollController.removeListener(_syncContentScroll);
    _headerHorizontalScrollController.dispose();
    _contentHorizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _syncHeaderScroll() {
    if (_isSyncingContent) return;
    _isSyncingHeader = true;
    try {
      if (_contentHorizontalScrollController.hasClients &&
          _headerHorizontalScrollController.offset !=
              _contentHorizontalScrollController.offset) {
        _contentHorizontalScrollController
            .jumpTo(_headerHorizontalScrollController.offset);
      }
    } finally {
      _isSyncingHeader = false;
    }
  }

  void _syncContentScroll() {
    if (_isSyncingHeader) return;
    _isSyncingContent = true;
    try {
      if (_headerHorizontalScrollController.hasClients &&
          _contentHorizontalScrollController.offset !=
              _headerHorizontalScrollController.offset) {
        _headerHorizontalScrollController
            .jumpTo(_contentHorizontalScrollController.offset);
      }
    } finally {
      _isSyncingContent = false;
    }
  }
  // Récupérer les planifications en attente
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

  // Mettre à jour l'ordre des planifications en attente
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

  // Afficher le dialogue des planifications en attente
  void _showWaitingPlanificationsDialog(BuildContext context) {
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
              return FadeInUp(
                key: ValueKey(waitingPlan.id), // Unique key for reordering
                duration: Duration(milliseconds: 300 + index * 100),
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    title: Text(
                      "Client: ${waitingPlan.commande.client.name}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.deepPurple,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          "Modèle: ${waitingPlan.modele.nom}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Taille: ${waitingPlan.taille}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Couleur: ${waitingPlan.couleur}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Quantité: ${waitingPlan.quantite}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Ajouté le: ${DateFormat('dd/MM/yyyy HH:mm').format(waitingPlan.createdAt)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                      ],
                    ),
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

  // Confirmer la déconnexion
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
              _isDateRangeInitialized = false; // Réinitialiser pour recalculer
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
                _startDate = null;
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

          // Calculer la plage de dates si nécessaire après le chargement
          if (!_isDateRangeInitialized && provider.planifications.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _calculateDateRange(provider.planifications);
            });
          }

          final filteredPlans = _filterPlanifications(provider.planifications);

          return Column(
              children: [
              _buildFilterBar(context, provider),
           Flexible(child: Expanded(child: _buildGanttChart(filteredPlans))),
          ],
          );
        },
      ),
    );
  }

  // Filtrer les planifications
  List<Planification> _filterPlanifications(List<Planification> plans) {
    return plans.where((p) {
      final date = p.debutPrevue;
      final statusMatch = _selectedStatus == 'tous' || p.statut == _selectedStatus;
      return date != null &&
          (_startDate == null || !date.isBefore(_startDate!)) &&
          (_endDate == null || !date.isAfter(_endDate!)) &&
          p.machines.isNotEmpty &&
          p.machines.first.salle.type == _selectedSalleType &&
          statusMatch;
    }).toList();
  }

  // Calculer la plage de dates
  void _calculateDateRange(List<Planification> planifications) {
    if (planifications.isEmpty || _isDateRangeInitialized) return;

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

    setState(() {
      _startDate = minDate.subtract(Duration(days: 1));
      _endDate = maxDate.add(Duration(days: 1));
      _isDateRangeInitialized = true;
    });
  }

  // Barre de filtres
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
              Text('à', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDateSelector(context, false),
              _buildDropdown(
                value: _selectedSalleType,
                items: ['noir', 'blanc'],
                hint: 'Type de salle',
                onChanged: (value) => setState(() => _selectedSalleType = value),
                width: 120,
              ),
              _buildDropdown(
                value: _selectedViewMode,
                items: ['journée', 'semaine', 'mois'],
                hint: 'Mode de vue',
                onChanged: (value) => setState(() => _selectedViewMode = value!),
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

  // Sélecteur de date
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
            ? (_startDate != null
            ? DateFormat('dd/MM/yyyy').format(_startDate!)
            : 'Date début')
            : (_endDate != null
            ? DateFormat('dd/MM/yyyy').format(_endDate!)
            : 'Date fin'),
        style: TextStyle(color: Colors.deepPurple, fontSize: 12),
      ),
      onPressed: () => _selectDate(context, isStartDate: isStartDate),
    );
  }

  // Dropdown générique
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

  // Dropdown pour les heures
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

  // Contrôles de zoom
  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.zoom_in, size: 20),
          onPressed: () => setState(() => _timeScale = (_timeScale + 0.1).clamp(0.5, 2.0)),
          tooltip: 'Zoomer',
        ),
        IconButton(
          icon: Icon(Icons.zoom_out, size: 20),
          onPressed: () => setState(() => _timeScale = (_timeScale - 0.1).clamp(0.5, 2.0)),
          tooltip: 'Dézoomer',
        ),
      ],
    );
  }

  // Sélection de date
  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
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

  // Construire le graphique de Gantt
  Widget _buildGanttChart(List<Planification> planifications) {
    if (_startDate == null || _endDate == null) {
      return Center(child: CircularProgressIndicator());
    }

    const rowHeight = 90.0;
    const headerHeight = 60.0;
    const infoColumnWidth = 200.0;
    final timeSlotWidth = 100.0 * _timeScale;

    List<String> headers = [];
    int timeSlots = 0;

    if (_selectedViewMode == 'journée') {
      timeSlots = _endHour - _startHour + 1;
      headers = List.generate(timeSlots, (index) => '${_startHour + index}h');
    } else if (_selectedViewMode == 'semaine') {
      timeSlots = 7;
      headers = List.generate(
        7,
            (index) => DateFormat('EEE dd/MM').format(_startDate!.add(Duration(days: index))),
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
        // En-tête
        SizedBox(
          height: headerHeight,
          child: Scrollbar(
            controller: _headerHorizontalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _headerHorizontalScrollController,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: totalWidth,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: infoColumnWidth,
                      child: Center(
                        child: Text(
                          'Planification',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    ...headers.map((h) => SizedBox(
                      width: timeSlotWidth,
                      child: Center(
                        child: Text(
                          h,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(height: 1, color: Colors.grey.shade300),

        // Contenu
        Expanded(
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _verticalScrollController,
              itemCount: planifications.length + _waitingPlanifications.length,
              itemBuilder: (context, index) {
                if (index < planifications.length) {
                  // Planifications actives
                  final plan = planifications[index];
                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + index * 100),
                    child: _buildGanttRow(
                      plan: plan,
                      timeSlots: timeSlots,
                      timeSlotWidth: timeSlotWidth,
                      infoColumnWidth: infoColumnWidth,
                      totalContentWidth: totalContentWidth,
                    ),
                  );
                } else {
                  // Planifications en attente
                  final waitingPlan = _waitingPlanifications[index - planifications.length];
                  return FadeInUp(
                    duration: Duration(milliseconds: 300 + index * 100),
                    child: _buildWaitingGanttRow(
                      waitingPlan: waitingPlan,
                      timeSlotWidth: timeSlotWidth,
                      infoColumnWidth: infoColumnWidth,
                      totalContentWidth: totalContentWidth,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Construire une ligne du Gantt pour une planification active
  Widget _buildGanttRow({
    required Planification plan,
    required int timeSlots,
    required double timeSlotWidth,
    required double infoColumnWidth,
    required double totalContentWidth,
  }) {
    double startSlot = 0;
    double duration = 1;

    if (_selectedViewMode == 'journée') {
      final debut = plan.debutPrevue ?? DateTime.now();
      final fin = plan.finPrevue ?? debut.add(Duration(hours: 1));
      final startMinutes = (debut.hour - _startHour) * 60 + debut.minute;
      final endMinutes = (fin.hour - _startHour) * 60 + fin.minute;
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
      height: 90,
      child: Row(
        children: [
          // Colonne d'informations
          SizedBox(
            width: infoColumnWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      plan.commandes.isNotEmpty ? plan.commandes.first.client.name : 'Aucun client',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      plan.machines.isNotEmpty ? plan.machines.first.nom : 'Aucune machine',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Salle: ${plan.machines.isNotEmpty ? plan.machines.first.salle.nom : 'N/A'}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  _buildStatusBadge(plan.statut),
                ],
              ),
            ),
          ),

          // Barre du Gantt
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              controller: _contentHorizontalScrollController,
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
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: startSlot * timeSlotWidth,
                      child: Tooltip(
                        message: '''
Client: ${plan.commandes.isNotEmpty ? plan.commandes.first.client.name : 'N/A'}
Machine: ${plan.machines.isNotEmpty ? plan.machines.first.nom : 'N/A'}
Salle: ${plan.machines.isNotEmpty ? plan.machines.first.salle.nom : 'N/A'}
Début: ${_formatDate(plan.debutPrevue)} à ${_formatTime(plan.debutPrevue)}
Fin:${_formatDate(plan.finPrevue)} à  ${_formatTime(plan.finPrevue)}
Statut: ${plan.statut}
''',
                        child: Container(
                          width: duration * timeSlotWidth,
                          height: 50,
                          margin: EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: _getStatusColor(plan.statut),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.fade,
                                  maxLines: 1,
                                ),
                                Text(
                                  '${_formatTime(plan.debutPrevue)} - ${_formatTime(plan.finPrevue)}',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
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
  }

  // Construire une ligne du Gantt pour une planification en attente
  Widget _buildWaitingGanttRow({
    required WaitingPlanification waitingPlan,
    required double timeSlotWidth,
    required double infoColumnWidth,
    required double totalContentWidth,
  }) {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          // Colonne d'informations
          SizedBox(
            width: infoColumnWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      waitingPlan.commande.client.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      'Modèle: ${waitingPlan.modele.nom}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      overflow: TextOverflow.fade,
                      maxLines: 1,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Taille: ${waitingPlan.taille}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      overflow: TextOverflow.fade
                      ,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: 2),
                  _buildStatusBadge('en attente'),
                ],
              ),
            ),
          ),

          // Barre du Gantt
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,  // Important to prevent conflicts

              controller: _contentHorizontalScrollController,
              child: SizedBox(
                width: totalContentWidth,
                child: Stack(
                  children: [
                    Row(
                      children: List.generate(
                        (totalContentWidth / timeSlotWidth).ceil(),
                            (index) => Container(
                          width: timeSlotWidth,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      child: Tooltip(
                        message: '''
Client: ${waitingPlan.commande.client.name}
Modèle: ${waitingPlan.modele.nom}
Taille: ${waitingPlan.taille}
Couleur: ${waitingPlan.couleur}
Quantité: ${waitingPlan.quantite}
Ajouté le: ${DateFormat('dd/MM/yyyy HH:mm').format(waitingPlan.createdAt)}
Statut: en attente
''',
                        child: Container(
                          width: totalContentWidth,
                          height: 50,
                          margin: EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.orange[300],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'En attente de machine',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
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
  }

  // Couleur selon le statut
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

  // Formatage de l'heure
  String _formatTime(DateTime? date) {
    return date != null ? DateFormat('HH:mm').format(date) : '--:--';
  }
  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/ yyyy').format(date) : '--/--/----';
  }
  // Badge de statut
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