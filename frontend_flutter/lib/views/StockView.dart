import 'package:flutter/material.dart';
import 'matiereView.dart';
import 'ListeProduitsPage.dart';
import 'StockModeleView.dart';

class StockView extends StatefulWidget {
  @override
  _StockViewState createState() => _StockViewState();
}

class _StockViewState extends State<StockView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: const Color.fromARGB(255, 6, 6, 6),
          unselectedLabelColor: const Color.fromARGB(227, 5, 5, 5),
          indicatorWeight: 3,
          tabs: [
            Tab(
              text: "Produits",
            ),
            Tab(
              text: "Matières",
            ),
            Tab(
              text: "Modèles",
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            ProduitsPage(),
            MatiereView(),
            StockModeleView(),
          ],
        ),
      ),
    );
  }
}
