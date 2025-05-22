import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
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
  String _selectedStatus = 'tous';
  int _startHour = 7;
  int _endHour = 17;
  double _timeScale = 1.0; // Zoom pour l'échelle temporelle
  bool _isDateRangeInitialized = false;
  List<Planification> _waitingPlanifications = [];

  @override
  void initState() {
    super.initState();
    // Charger les planifications au démarrage
    final provider = Provider.of<PlanificationProvider>(context, listen: false);
    provider.fetchPlanifications();
    _fetchWaitingPlanifications();
    // Initialiser la plage de dates après le premier rendu
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
  void _showStockAlert(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Stock Insuffisant"),
      content: Text(
          "Certaines matières premières sont en quantité insuffisante. "
          "Les commandes concernées ont été mises en attente."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("OK"),
        ),
      ],
    ),
  );
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
              // Safely access commande and modele data
              final commande = waitingPlan.commandes.isNotEmpty ? waitingPlan.commandes.first : null;
              final modeleData = commande?.modeles?.isNotEmpty == true ? commande!.modeles.first : null;

              return FadeInUp(
                key: ValueKey(waitingPlan.id),
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
                      "Client: ${commande?.client.name ?? 'Inconnu'}",
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
                          "Modele: ${waitingPlan.taille ?? modeleData?.modele ?? 'Non spécifié'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Taille: ${waitingPlan.taille ?? modeleData?.taille ?? 'Non spécifié'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Couleur: ${waitingPlan.couleur ?? modeleData?.couleur ?? 'Non spécifié'}",
                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                        ),
                        Text(
                          "Quantité: ${waitingPlan.quantite?.toString() ?? modeleData?.quantite?.toString() ?? 'Non spécifié'}",
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
              Expanded(child: _buildPlanificationTable(filteredPlans)),
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
      final statusMatch = _selectedStatus == 'tous' ||
          p.statut == _selectedStatus ||
          (_selectedStatus == 'en attente' && p.statut == 'waiting_resources');
      return date != null &&
          (_startDate == null || !date.isBefore(_startDate!)) &&
          (_endDate == null || !date.isAfter(_endDate!)) &&
          p.machines.isNotEmpty &&
          p.machines.first.salle.type == _selectedSalleType &&
          statusMatch;
    }).toList();
  }
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

  // Construire le tableau des planifications
  Widget _buildPlanificationTable(List<Planification> planifications) {
    if (_startDate == null || _endDate == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: DataTable(
          columnSpacing: 0, // Remove fixed spacing to allow columns to stretch
          dataRowHeight: 60,
          headingRowColor: MaterialStateColor.resolveWith((states) => Colors.deepPurple.withOpacity(0.1)),
          columns: [
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Modele', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Taille', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Machine', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Salle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Début', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Container(
                alignment: Alignment.center,
                child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          rows: planifications.asMap().entries.map((entry) {
            final index = entry.key;
            final plan = entry.value;
            return DataRow(
              cells: [
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      plan.commandes.isNotEmpty ? plan.commandes.first.client.name : 'Aucun client',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      plan.commandes.isNotEmpty ? plan.machines.first.modele.nom : 'modele inconnu',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      plan.commandes.isNotEmpty ? plan.machines.first.taille : 'taille inconnu',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      plan.machines.isNotEmpty ? plan.machines.first.nom : 'Aucune machine',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      plan.machines.isNotEmpty ? plan.machines.first.salle.nom : 'N/A',
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      _formatDateTime(plan.debutPrevue),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: Text(
                      _formatDateTime(plan.finPrevue),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    alignment: Alignment.center,
                    child: _buildStatusBadge(plan.statut),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
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
  String _formatTime(DateTime? date) {
    return date != null ? DateFormat('HH:mm').format(date) : '--:--';
  }
  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('dd/MM/yyyy').format(date) : '--/--/----';
  }
  String _formatDateTime(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : '--/--/---- --:--';
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