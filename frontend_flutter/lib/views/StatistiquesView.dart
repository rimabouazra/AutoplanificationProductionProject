import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/matiere.dart';
import '../providers/matiereProvider.dart';

class StatistiquesView extends StatefulWidget {
  const StatistiquesView({super.key});

  @override
  _StatistiquesViewState createState() => _StatistiquesViewState();
}

class _StatistiquesViewState extends State<StatistiquesView>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'Mois';
  DateTime _selectedDate = DateTime.now();
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Matiere> _allMatieres = [];
  int _touchedBarIndex = -1; // For bar chart interaction
  int _touchedPieIndex = -1; // For pie chart interaction
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<MatiereProvider>(context, listen: false)
          .fetchMatieres();
      setState(() {
        _allMatieres =
            Provider.of<MatiereProvider>(context, listen: false).matieres;
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données : $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {});
    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistiques des Matières',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPDF,
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
            tooltip: 'Sélectionner une date',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.blue)),
                  SizedBox(height: 16),
                  Text('Chargement des données...',
                      style: TextStyle(fontSize: 16, color: Colors.blue)),
                ],
              ),
            )
          : _buildMatieresContent(),
    );
  }

  Widget _buildMatieresContent() {
    final filteredMatieres = _filterMatieres();

    if (filteredMatieres.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            _buildMatiereSummaryStats(filteredMatieres),
            const SizedBox(height: 32),
            _buildMatiereQuantiteChart(filteredMatieres),
            const SizedBox(height: 32),
            _buildMatiereMovementsChart(filteredMatieres),
            const SizedBox(height: 32),
            _buildConsumptionTrendChart(filteredMatieres),
            const SizedBox(height: 32),
            _buildMatieresTable(filteredMatieres),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher par référence ou couleur...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.blue.shade700),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ToggleButtons(
              borderRadius: BorderRadius.circular(8),
              selectedColor: Colors.white,
              fillColor: Colors.blue.shade700,
              color: Colors.blue.shade700,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
              isSelected: ['Jour', 'Semaine', 'Mois']
                  .map((p) => p == _selectedPeriod)
                  .toList(),
              onPressed: (index) {
                setState(() {
                  _selectedPeriod = ['Jour', 'Semaine', 'Mois'][index];
                  _animationController.forward(from: 0);
                });
              },
              children: const [
                Text('Jour'),
                Text('Semaine'),
                Text('Mois'),
              ],
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereSummaryStats(List<Matiere> matieres) {
    final totalMatieres = matieres.length;
    final totalQuantite = matieres.fold(0.0, (sum, m) => sum + m.quantite);
    final totalConsommation = matieres.fold(
        0.0,
        (sum, m) =>
            sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'consommation')
                .fold(0.0, (sum, h) => sum + h.quantite));

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Résumé des Matières',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.category, 'Matières',
                    totalMatieres.toString(), Colors.blue),
                _buildStatItem(Icons.storage, 'Stock Total',
                    totalQuantite.toStringAsFixed(2), Colors.green),
                _buildStatItem(Icons.trending_down, 'Consommation',
                    totalConsommation.toStringAsFixed(2), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereQuantiteChart(List<Matiere> matieres) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: Colors.indigo, size: 24),
              SizedBox(width: 8),
              Text(
                'Quantité par Matière',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: matieres.fold(0.0, (max, m) => m.quantite > max ? m.quantite : max) * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.indigo.withOpacity(0.8), // Fixed here
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${matieres[groupIndex].reference}\n${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedBarIndex = -1;
                        return;
                      }
                      _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                barGroups: matieres.asMap().entries.map((entry) {
                  final isTouched = _touchedBarIndex == entry.key;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.quantite,
                        color: isTouched ? Colors.indigo : Colors.indigoAccent,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: matieres.fold(0.0, (max, m) => m.quantite > max ? m.quantite : max) * 1.2,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < matieres.length) {
                          return Transform.rotate(
                            angle: -45 * 3.14159 / 180,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                matieres[index].reference,
                                style: const TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMatiereMovementsChart(List<Matiere> matieres) {
    final ajouts = matieres.fold(
        0.0,
        (sum, m) =>
            sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'ajout')
                .fold(0.0, (sum, h) => sum + h.quantite));
    final consommations = matieres.fold(
        0.0,
        (sum, m) =>
            sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'consommation')
                .fold(0.0, (sum, h) => sum + h.quantite));

    final total = ajouts + consommations;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Aucun mouvement de stock pour la période sélectionnée',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.donut_large, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text(
                  'Mouvements de Stock',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: [
                    PieChartSectionData(
                      value: ajouts,
                      color: Colors.green,
                      radius: _touchedPieIndex == 0 ? 80 : 70,
                      title: '',
                      badgeWidget: _buildPieBadge(
                          'Ajouts', ajouts.toStringAsFixed(2), Colors.green),
                      badgePositionPercentageOffset: 1.2,
                    ),
                    PieChartSectionData(
                      value: consommations,
                      color: Colors.red,
                      radius: _touchedPieIndex == 1 ? 80 : 70,
                      title: '',
                      badgeWidget: _buildPieBadge('Consommations',
                          consommations.toStringAsFixed(2), Colors.red),
                      badgePositionPercentageOffset: 1.2,
                    ),
                  ],
                  centerSpaceRadius: 50,
                  sectionsSpace: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendDot(
                    Colors.green, 'Ajouts (${ajouts.toStringAsFixed(2)})'),
                _buildLegendDot(Colors.red,
                    'Consommations (${consommations.toStringAsFixed(2)})'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$title: $value',
        style: const TextStyle(
            fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

Widget _buildConsumptionTrendChart(List<Matiere> matieres) {
  final consumptionByDate = <String, double>{};
  for (var matiere in matieres) {
    for (var entry in matiere.historique) {
      if (entry.action.toLowerCase() == 'consommation') {
        final dateKey = _formatDateForPeriod(entry.date);
        consumptionByDate[dateKey] = (consumptionByDate[dateKey] ?? 0) + entry.quantite;
      }
    }
  }

  final sortedDates = consumptionByDate.keys.toList()..sort();
  final dataPoints = sortedDates.asMap().entries.map((entry) {
    return FlSpot(entry.key.toDouble(), consumptionByDate[entry.value]!);
  }).toList();

  if (dataPoints.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aucune donnée de consommation pour la période sélectionnée',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: 24),
              SizedBox(width: 8),
              Text(
                'Tendance de Consommation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (LineBarSpot spot) => Colors.blue.withOpacity(0.8), // Fixed here
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${sortedDates[spot.x.toInt()]}: ${spot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    dotData: FlDotData(show: true),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: sortedDates.length > 10 ? sortedDates.length / 5 : 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedDates.length) {
                          return Transform.rotate(
                            angle: -45 * 3.14159 / 180,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                sortedDates[index],
                                style: const TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMatieresTable(List<Matiere> matieres) {
    const itemsPerPage = 10;
    int currentPage = 0;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, color: Colors.deepOrange, size: 24),
                SizedBox(width: 8),
                Text(
                  'Détail des Matières',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                dataRowColor: MaterialStateProperty.resolveWith((states) {
                  return states.contains(MaterialState.selected)
                      ? Colors.blue.shade100
                      : null;
                }),
                columns: [
                  const DataColumn(
                      label: Text('Référence',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text('Couleur',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text('Quantité',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  const DataColumn(
                      label: Text('Consommation Récente',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      numeric: true),
                  const DataColumn(
                      label: Text('Dernier Mouvement',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: matieres
                    .skip(currentPage * itemsPerPage)
                    .take(itemsPerPage)
                    .map((matiere) {
                  final recentConsumption = matiere.historique
                      .where((h) =>
                          h.action.toLowerCase() == 'consommation' &&
                          _isWithinSelectedPeriod(h.date))
                      .fold(0.0, (sum, h) => sum + h.quantite);
                  final dernierMouvement = matiere.historique.isNotEmpty
                      ? DateFormat('dd/MM').format(matiere.historique.last.date)
                      : 'N/A';

                  return DataRow(
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () => _showMatiereDetails(context, matiere),
                          child: Text(matiere.reference,
                              style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline)),
                        ),
                      ),
                      DataCell(Text(matiere.couleur)),
                      DataCell(Text(matiere.quantite.toStringAsFixed(2))),
                      DataCell(Text(recentConsumption.toStringAsFixed(2))),
                      DataCell(Text(dernierMouvement)),
                    ],
                  );
                }).toList(),
              ),
            ),
            if (matieres.length > itemsPerPage)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: currentPage > 0
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    Text(
                        'Page ${currentPage + 1} / ${(matieres.length / itemsPerPage).ceil()}'),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed:
                          (currentPage + 1) * itemsPerPage < matieres.length
                              ? () => setState(() => currentPage++)
                              : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMatiereDetails(BuildContext context, Matiere matiere) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de ${matiere.reference}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Couleur: ${matiere.couleur}'),
              Text('Quantité: ${matiere.quantite.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Historique des Mouvements:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...matiere.historique.take(5).map((h) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${DateFormat('dd/MM HH:mm').format(h.date)} - ${h.action}: ${h.quantite.toStringAsFixed(2)}',
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final filteredMatieres = _filterMatieres();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Statistiques de Consommation des Matières',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Période: $_selectedPeriod - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Résumé des Statistiques',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatItem('Matières',
                      filteredMatieres.length.toString(), PdfColors.blue),
                  _buildPdfStatItem(
                      'Stock Total',
                      filteredMatieres
                          .fold(0.0, (sum, m) => sum + m.quantite)
                          .toStringAsFixed(2),
                      PdfColors.green),
                  _buildPdfStatItem(
                      'Consommation',
                      filteredMatieres
                          .fold(
                              0.0,
                              (sum, m) =>
                                  sum +
                                  m.historique
                                      .where((h) =>
                                          h.action.toLowerCase() ==
                                          'consommation')
                                      .fold(0.0, (sum, h) => sum + h.quantite))
                          .toStringAsFixed(2),
                      PdfColors.red),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Détail des Matières (${filteredMatieres.length} résultats)',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: [
                  'Référence',
                  'Couleur',
                  'Quantité',
                  'Consommation Récente',
                  'Dernier Mouvement'
                ],
                data: filteredMatieres.map((matiere) {
                  final recentConsumption = matiere.historique
                      .where((h) =>
                          h.action.toLowerCase() == 'consommation' &&
                          _isWithinSelectedPeriod(h.date))
                      .fold(0.0, (sum, h) => sum + h.quantite);
                  final dernierMouvement = matiere.historique.isNotEmpty
                      ? DateFormat('dd/MM').format(matiere.historique.last.date)
                      : 'N/A';
                  return [
                    matiere.reference,
                    matiere.couleur,
                    matiere.quantite.toStringAsFixed(2),
                    recentConsumption.toStringAsFixed(2),
                    dernierMouvement,
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _buildPdfStatItem(String label, String value, PdfColor color) {
    final lightColor = color == PdfColors.blue
        ? PdfColors.lightBlue
        : color == PdfColors.green
            ? PdfColors.lightGreen
            : PdfColors.red;
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: lightColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _animationController.forward(from: 0);
      });
    }
  }

  List<Matiere> _filterMatieres() {
    final searchQuery = _searchController.text.toLowerCase();
    return _allMatieres.where((matiere) {
      final matchesSearch = searchQuery.isEmpty ||
          matiere.reference.toLowerCase().contains(searchQuery) ||
          matiere.couleur.toLowerCase().contains(searchQuery);
      final matchesPeriod = matiere.historique.any((h) =>
          h.action.toLowerCase() == 'consommation' &&
          _isWithinSelectedPeriod(h.date));
      return matchesSearch && (matchesPeriod || _selectedPeriod == 'Mois');
    }).toList();
  }

  bool _isWithinSelectedPeriod(DateTime date) {
    switch (_selectedPeriod) {
      case 'Jour':
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;
      case 'Semaine':
        final startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case 'Mois':
      default:
        return date.year == _selectedDate.year &&
            date.month == _selectedDate.month;
    }
  }

  String _formatDateForPeriod(DateTime date) {
    switch (_selectedPeriod) {
      case 'Jour':
        return DateFormat('HH:mm').format(date);
      case 'Semaine':
        return DateFormat('EEE').format(date);
      case 'Mois':
      default:
        return DateFormat('dd/MM').format(date);
    }
  }
}
