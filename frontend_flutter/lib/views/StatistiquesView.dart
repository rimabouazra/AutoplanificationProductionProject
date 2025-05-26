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

class _StatistiquesViewState extends State<StatistiquesView> {
  String _selectedPeriod = 'Mois';
  DateTime _selectedDate = DateTime.now();
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Matiere> _allMatieres = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<MatiereProvider>(context, listen: false).fetchMatieres();
      setState(() {
        _allMatieres = Provider.of<MatiereProvider>(context, listen: false).matieres;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Statistiques de Consommation des Matières'),
        centerTitle: true,
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
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des données...', style: TextStyle(fontSize: 16)),
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
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune donnée disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          _buildMatiereSummaryStats(filteredMatieres),
          const SizedBox(height: 30),
          _buildMatiereQuantiteChart(filteredMatieres),
          const SizedBox(height: 30),
          _buildMatiereMovementsChart(filteredMatieres),
          const SizedBox(height: 30),
          _buildConsumptionTrendChart(filteredMatieres),
          const SizedBox(height: 30),
          _buildMatieresTable(filteredMatieres),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              value: _selectedPeriod,
              items: ['Jour', 'Semaine', 'Mois'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
            ),
            const SizedBox(width: 20),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.blue.shade50,
              ),
              onPressed: () => _selectDate(context),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
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
        (sum, m) => sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'consommation')
                .fold(0.0, (sum, h) => sum + h.quantite));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Résumé des Matières',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Matières', totalMatieres.toString(), Colors.blue),
                _buildStatItem('Stock total', totalQuantite.toStringAsFixed(2), Colors.green),
                _buildStatItem('Consommation', totalConsommation.toStringAsFixed(2), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereQuantiteChart(List<Matiere> matieres) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Quantité par Matière',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: matieres.fold(
                          0.0, (max, m) => m.quantite > max ? m.quantite : max) * 1.2,
                  barGroups: matieres
                      .asMap()
                      .entries
                      .map(
                        (entry) => BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.quantite,
                              color: Colors.indigoAccent,
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Text(
                          matieres[value.toInt()].reference.substring(0, 3),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
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
        (sum, m) => sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'ajout')
                .fold(0.0, (sum, h) => sum + h.quantite));
    final consommations = matieres.fold(
        0.0,
        (sum, m) => sum +
            m.historique
                .where((h) => h.action.toLowerCase() == 'consommation')
                .fold(0.0, (sum, h) => sum + h.quantite));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.donut_large, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Mouvements de Stock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: ajouts,
                      color: Colors.green,
                      title: 'Ajouts\n${ajouts.toStringAsFixed(2)}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: consommations,
                      color: Colors.red,
                      title: 'Consommations\n${consommations.toStringAsFixed(2)}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendDot(Colors.green, 'Ajouts'),
                _buildLegendDot(Colors.red, 'Consommations'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTrendChart(List<Matiere> matieres) {
    final consumptionByDate = <String, double>{};
    for (var matiere in matieres) {
      for (var entry in matiere.historique) {
        if (entry.action.toLowerCase() == 'consommation') {
          final dateKey = _formatDateForPeriod(entry.date);
          consumptionByDate[dateKey] =
              (consumptionByDate[dateKey] ?? 0) + entry.quantite;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tendance de Consommation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
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
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedDates.length) {
                            return Text(
                              sortedDates[index],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatieresTable(List<Matiere> matieres) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Détail des Matières',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('Référence')),
                  DataColumn(label: Text('Couleur')),
                  DataColumn(label: Text('Quantité'), numeric: true),
                  DataColumn(label: Text('Consommation Récente'), numeric: true),
                  DataColumn(label: Text('Dernier mouvement')),
                ],
                rows: matieres.take(10).map((matiere) {
                  final recentConsumption = matiere.historique
                      .where((h) =>
                          h.action.toLowerCase() == 'consommation' &&
                          _isWithinSelectedPeriod(h.date))
                      .fold(0.0, (sum, h) => sum + h.quantite);
                  final dernierMouvement = matiere.historique.isNotEmpty
                      ? DateFormat('dd/MM').format(matiere.historique.last.date)
                      : 'N/A';

                  return DataRow(cells: [
                    DataCell(Text(matiere.reference)),
                    DataCell(Text(matiere.couleur)),
                    DataCell(Text(matiere.quantite.toStringAsFixed(2))),
                    DataCell(Text(recentConsumption.toStringAsFixed(2))),
                    DataCell(Text(dernierMouvement)),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
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
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatItem('Matières', filteredMatieres.length.toString(), PdfColors.blue),
                  _buildPdfStatItem(
                      'Stock total',
                      filteredMatieres
                          .fold(0.0, (sum, m) => sum + m.quantite)
                          .toStringAsFixed(2),
                      PdfColors.green),
                  _buildPdfStatItem(
                      'Consommation',
                      filteredMatieres
                          .fold(
                              0.0,
                              (sum, m) => sum +
                                  m.historique
                                      .where((h) => h.action.toLowerCase() == 'consommation')
                                      .fold(0.0, (sum, h) => sum + h.quantite))
                          .toStringAsFixed(2),
                      PdfColors.red),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Détail des Matières (${filteredMatieres.length} résultats)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Référence', 'Couleur', 'Quantité', 'Consommation Récente', 'Dernier mouvement'],
                data: filteredMatieres.take(20).map((matiere) {
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
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
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
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
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
      });
    }
  }

  List<Matiere> _filterMatieres() {
    final searchQuery = _searchController.text.toLowerCase();
    return _allMatieres.where((matiere) {
      final matchesSearch = searchQuery.isEmpty ||
          matiere.reference.toLowerCase().contains(searchQuery) ||
          matiere.couleur.toLowerCase().contains(searchQuery);
      final matchesPeriod = matiere.historique.any(
          (h) => h.action.toLowerCase() == 'consommation' && _isWithinSelectedPeriod(h.date));
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
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return date.isAfter(startOfWeek) && date.isBefore(endOfWeek.add(const Duration(days: 1)));
      case 'Mois':
      default:
        return date.year == _selectedDate.year && date.month == _selectedDate.month;
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