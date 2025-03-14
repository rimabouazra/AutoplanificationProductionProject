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
        backgroundColor: Color.fromARGB(255, 170, 207, 247),
        toolbarHeight: 10,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: const Color.fromARGB(255, 173, 165, 165),
          unselectedLabelColor: Colors.white.withOpacity(0.6),
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
            colors: [
              Color(0xFFF4F6F7),
              Colors.white,
            ],
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
