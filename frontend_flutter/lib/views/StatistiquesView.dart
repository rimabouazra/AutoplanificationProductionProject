import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/commande.dart';
import '../models/matiere.dart';
import '../providers/matiereProvider.dart';
import '../providers/CommandeProvider.dart';

class StatistiquesView extends StatefulWidget {
  @override
  _StatistiquesViewState createState() => _StatistiquesViewState();
}

class _StatistiquesViewState extends State<StatistiquesView> {
  String _selectedPeriod = 'Mois';
  DateTime _selectedDate = DateTime.now();
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Commande> _allCommandes = [];
  List<Matiere> _allMatieres = [];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Provider.of<CommandeProvider>(context, listen: false)
        .fetchCommandes();
    await Provider.of<MatiereProvider>(context, listen: false).fetchMatieres();
    _allCommandes =
        Provider.of<CommandeProvider>(context, listen: false).commandes;
    _allMatieres =
        Provider.of<MatiereProvider>(context, listen: false).matieres;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Nombre d'onglets
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tableau de Bord'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.picture_as_pdf),
              onPressed: _exportToPDF,
              tooltip: 'Exporter en PDF',
            ),
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Actualiser',
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag)),
              Tab(icon: Icon(Icons.inventory)),
            ],
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement des données...',
                        style: TextStyle(fontSize: 16)),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  _buildCommandesContent(),
                  _buildMatieresContent(),
                ],
              ),
      ),
    );
  }

  Widget _buildCommandesContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Rechercher par client',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        _buildPeriodSelector(),
        Expanded(
          child: _buildCommandesStatistics(),
        ),
      ],
    );
  }

  Widget _buildMatieresContent() {
    final filteredMatieres = _filterMatieres();

    if (filteredMatieres.isEmpty) {
      return Center(
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMatiereSummaryStats(),
          SizedBox(height: 30),
          _buildMatiereQuantiteChart(),
          SizedBox(height: 30),
          _buildMatiereMovementsChart(),
          SizedBox(height: 30),
          _buildMatieresTable(),
        ],
      ),
    );
  }

  Widget _buildMatiereSummaryStats() {
    final totalMatieres = _allMatieres.length;
    final totalQuantite = _allMatieres.fold(0.0, (sum, m) => sum + m.quantite);
    final recentAdditions = _allMatieres
        .where((m) =>
            m.dateAjout.isAfter(DateTime.now().subtract(Duration(days: 7))))
        .length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Résumé des Matières',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'Matières', totalMatieres.toString(), Colors.blue),
                _buildStatItem('Stock total', totalQuantite.toStringAsFixed(2),
                    Colors.green),
                _buildStatItem('Ajouts récents', recentAdditions.toString(),
                    Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatiereQuantiteChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
            SizedBox(height: 10),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _allMatieres.fold(0.0,
                          (max, m) => m.quantite > max ? m.quantite : max) *
                      1.2,
                  barGroups: _allMatieres
                      .map(
                        (matiere) => BarChartGroupData(
                          x: _allMatieres.indexOf(matiere),
                          barRods: [
                            BarChartRodData(
                              toY: matiere.quantite,
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
                          _allMatieres[value.toInt()].reference.substring(0, 3),
                          style: TextStyle(fontSize: 10),
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

  Widget _buildMatiereMovementsChart() {
    final ajouts = _allMatieres.fold(
        0,
        (sum, m) =>
            sum + m.historique.where((h) => h.action == 'Ajout').length);
    final consommations = _allMatieres.fold(
        0,
        (sum, m) =>
            sum + m.historique.where((h) => h.action == 'Consommation').length);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
            SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: ajouts.toDouble(),
                      color: Colors.green,
                      title: 'Ajouts\n$ajouts',
                      radius: 60,
                      titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: consommations.toDouble(),
                      color: Colors.deepOrange,
                      title: 'Consommations\n$consommations',
                      radius: 60,
                      titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendDot(Colors.green, 'Ajouts'),
                _buildLegendDot(Colors.deepOrange, 'Consommations'),
              ],
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildMatieresTable() {
    final filteredMatieres = _filterMatieres();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                columns: [
                  DataColumn(label: Text('Référence')),
                  DataColumn(label: Text('Couleur')),
                  DataColumn(label: Text('Quantité'), numeric: true),
                  DataColumn(label: Text('Dernier mouvement')),
                ],
                rows: filteredMatieres.take(10).map((matiere) {
                  final dernierMouvement = matiere.historique.isNotEmpty
                      ? DateFormat('dd/MM').format(matiere.historique.last.date)
                      : 'N/A';

                  return DataRow(cells: [
                    DataCell(Text(matiere.reference)),
                    DataCell(Text(matiere.couleur)),
                    DataCell(Text(matiere.quantite.toStringAsFixed(2))),
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

  List<Matiere> _filterMatieres() {
    String searchQuery = _searchController.text.toLowerCase();
    return _allMatieres.where((matiere) {
      bool matchesSearch = searchQuery.isEmpty ||
          matiere.reference.toLowerCase().contains(searchQuery) ||
          matiere.couleur.toLowerCase().contains(searchQuery);
      return matchesSearch;
    }).toList();
  }

  Widget _buildCommandesStatistics() {
    final filteredCommandes = _filterCommandes();

    if (filteredCommandes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucune donnée disponible',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                child: Text('Réinitialiser la recherche'),
              ),
          ],
        ),
      );
    }

    final stats = _calculateStatistics(filteredCommandes);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: _buildStatsSummary(stats),
          ),
          SizedBox(height: 30),
          _buildStatusChart(filteredCommandes),
          SizedBox(height: 30),
          _buildCommandesTable(filteredCommandes),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
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
              SizedBox(width: 20),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  backgroundColor: Colors.blue.shade50,
                ),
                onPressed: () => _selectDate(context),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  'Résumé des Statistiques',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Commandes', stats['totalCommandes'].toString(),
                    Colors.blue),
                _buildStatItem('Terminées',
                    stats['commandesTerminees'].toString(), Colors.green),
                _buildStatItem(
                    'Taux', '${stats['tauxCompletion']}%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
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
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatusChart(List<Commande> commandes) {
    final statusCounts = <String, int>{};
    for (var commande in commandes) {
      statusCounts[commande.etat] = (statusCounts[commande.etat] ?? 0) + 1;
    }

    final total = statusCounts.values.fold(0, (sum, val) => sum + val);
    final sections = statusCounts.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: _getStatusColor(entry.key),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Répartition par Statut',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: statusCounts.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getStatusColor(entry.key),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandesTable(List<Commande> commandes) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_chart, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Détail des Commandes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    MaterialStateProperty.all(Colors.grey.shade100),
                columns: [
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Modèles'), numeric: true),
                  DataColumn(label: Text('Quantité'), numeric: true),
                  DataColumn(label: Text('Date')),
                ],
                rows: commandes.take(10).map((commande) {
                  return DataRow(cells: [
                    DataCell(Text(
                      commande.client.name,
                      overflow: TextOverflow.ellipsis,
                    )),
                    DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(commande.etat).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          commande.etat,
                          style: TextStyle(
                            color: _getStatusColor(commande.etat),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(commande.modeles.length.toString())),
                    DataCell(Text(
                      commande.modeles
                          .fold(0, (sum, m) => sum + m.quantite)
                          .toString(),
                    )),
                    DataCell(Text(
                      commande.createdAt != null
                          ? DateFormat('dd/MM').format(commande.createdAt!)
                          : 'N/A',
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();
    final filteredCommandes = _filterCommandes();
    final stats = _calculateStatistics(filteredCommandes);
    final statusCounts = _getStatusCounts(filteredCommandes);

    // Page Commandes
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Tableau de Bord - Commandes',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              pw.SizedBox(height: 20),
              pw.Text(
                  'Période: $_selectedPeriod - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                  style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text('Résumé des Statistiques',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatItem('Commandes',
                      stats['totalCommandes'].toString(), PdfColors.blue),
                  _buildPdfStatItem('Terminées',
                      stats['commandesTerminees'].toString(), PdfColors.green),
                  _buildPdfStatItem(
                      'Taux', '${stats['tauxCompletion']}%', PdfColors.orange),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Text('Répartition par Statut',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.SizedBox(
                height: 200,
                child: pw.Column(
                  children: [
                    pw.Text('Répartition par Statut',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: statusCounts.entries.map((entry) {
                        return pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Container(
                              width: 12,
                              height: 12,
                              decoration: pw.BoxDecoration(
                                color: _getPdfStatusColor(entry.key),
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.SizedBox(width: 6),
                            pw.Text('${entry.key}: ${entry.value}'),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                  'Détail des Commandes (${filteredCommandes.length} résultats)',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Client', 'Statut', 'Modèles', 'Quantité', 'Date'],
                data: filteredCommandes.take(20).map((commande) {
                  return [
                    commande.client.name,
                    commande.etat,
                    commande.modeles.length.toString(),
                    commande.modeles
                        .fold(0, (sum, m) => sum + m.quantite)
                        .toString(),
                    commande.createdAt != null
                        ? DateFormat('dd/MM').format(commande.createdAt!)
                        : 'N/A',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    // Page Matières
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Tableau de Bord - Matières',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              // Statistiques résumées
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatItem('Matières', _allMatieres.length.toString(),
                      PdfColors.blue),
                  _buildPdfStatItem(
                      'Stock total',
                      _allMatieres
                          .fold(0.0, (sum, m) => sum + m.quantite)
                          .toStringAsFixed(2),
                      PdfColors.green),
                  _buildPdfStatItem(
                      'Ajouts récents',
                      _allMatieres
                          .where((m) => m.dateAjout.isAfter(
                              DateTime.now().subtract(Duration(days: 7))))
                          .length
                          .toString(),
                      PdfColors.purple),
                ],
              ),
              pw.SizedBox(height: 20),
              // Tableau des matières
              pw.Text('Détail des Matières',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                headers: [
                  'Référence',
                  'Couleur',
                  'Quantité',
                  'Dernier mouvement'
                ],
                data: _allMatieres.take(20).map((matiere) {
                  final dernierMouvement = matiere.historique.isNotEmpty
                      ? DateFormat('dd/MM').format(matiere.historique.last.date)
                      : 'N/A';
                  return [
                    matiere.reference,
                    matiere.couleur,
                    matiere.quantite.toStringAsFixed(2),
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
            : color == PdfColors.orange
                ? PdfColors.orangeAccent
                : PdfColors.grey200;
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: lightColor,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              )),
        ),
        pw.SizedBox(height: 5),
        pw.Text(label, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  Map<String, int> _getStatusCounts(List<Commande> commandes) {
    final statusCounts = <String, int>{};
    for (var commande in commandes) {
      statusCounts[commande.etat] = (statusCounts[commande.etat] ?? 0) + 1;
    }
    return statusCounts;
  }

  PdfColor _getPdfStatusColor(String status) {
    switch (status) {
      case "terminé":
        return PdfColors.green;
      case "En attente":
        return PdfColors.red;
      case "En cours":
        return PdfColors.orange;
      default:
        return PdfColors.grey;
    }
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
            colorScheme: ColorScheme.light(
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

  List<Commande> _filterCommandes() {
    String searchQuery = _searchController.text.toLowerCase();
    List<Commande> filtered = _allCommandes.where((commande) {
      bool matchesSearch = searchQuery.isEmpty ||
          commande.client.name.toLowerCase().contains(searchQuery);
      return matchesSearch;
    }).toList();

    return _filterCommandesByPeriod(filtered);
  }

  List<Commande> _filterCommandesByPeriod(List<Commande> commandes) {
    switch (_selectedPeriod) {
      case 'Jour':
        return commandes
            .where((c) =>
                c.createdAt != null &&
                c.createdAt!.year == _selectedDate.year &&
                c.createdAt!.month == _selectedDate.month &&
                c.createdAt!.day == _selectedDate.day)
            .toList();
      case 'Semaine':
        final startOfWeek =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return commandes
            .where((c) =>
                c.createdAt != null &&
                c.createdAt!.isAfter(startOfWeek) &&
                c.createdAt!.isBefore(endOfWeek.add(Duration(days: 1))))
            .toList();
      case 'Mois':
      default:
        return commandes
            .where((c) =>
                c.createdAt != null &&
                c.createdAt!.year == _selectedDate.year &&
                c.createdAt!.month == _selectedDate.month)
            .toList();
    }
  }

  Map<String, dynamic> _calculateStatistics(List<Commande> commandes) {
    final total = commandes.length;
    final terminees = commandes.where((c) => c.etat == 'Terminé').length;
    final taux = total > 0 ? ((terminees / total) * 100).round() : 0;

    return {
      'totalCommandes': total,
      'commandesTerminees': terminees,
      'tauxCompletion': taux,
    };
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "terminé":
        return Colors.green.shade600;
      case "en attente":
        return Colors.red.shade400;
      case "en coupe":
        return Colors.orange.shade600;
      case "en moulage":
        return Colors.blue.shade400;
      case "en presse":
        return Colors.purple.shade400;
      case "en contrôle":
        return Colors.teal.shade400;
      case "emballage":
        return Colors.pink.shade400;
      default:
        return Colors.grey;
    }
  }
}
