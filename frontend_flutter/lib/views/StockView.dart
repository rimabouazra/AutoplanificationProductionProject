import 'package:flutter/material.dart';
import 'matiereView.dart';
import 'ListeProduitsPage.dart';

class StockView extends StatefulWidget {
  @override
  _StockViewState createState() => _StockViewState();
}

class _StockViewState extends State<StockView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          tabs: [
            Tab(icon: Icon(Icons.widgets), text: "Produits"),
            Tab(icon: Icon(Icons.category), text: "Matières"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProduitsPage(),
          MatiereView(),
        ],
      ),
    );
  }
}
