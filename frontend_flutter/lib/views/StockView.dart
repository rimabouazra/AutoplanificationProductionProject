import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'matiereView.dart';
import 'ListeProduitsPage.dart';
import 'StockModeleView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockView extends StatefulWidget {
  @override
  _StockViewState createState() => _StockViewState();
}

class _StockViewState extends State<StockView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Tab> _tabs = [];
  List<Widget> _tabViews = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  Future<void> _initTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    if (role == 'responsable_modele') {
      _tabs = [
        Tab(text: "Produits"),
        Tab(text: "Modèles"),
      ];
      _tabViews = [
        ProduitsPage(),
        StockModeleView(),
      ];
    } else if (role == 'responsable_matiere') {
      _tabs = [Tab(text: "Matières")];
      _tabViews = [MatiereView()];
    } else {
      _tabs = [
        Tab(text: "Produits"),
        Tab(text: "Matières"),
        Tab(text: "Modèles"),
      ];
      _tabViews = [
        ProduitsPage(),
        MatiereView(),
        StockModeleView(),
      ];
    }

    if (mounted) {
      setState(() {
        _tabController = TabController(length: _tabs.length, vsync: this);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
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
    if (_isLoading || _tabController == null) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromARGB(255, 170, 207, 247),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
        toolbarHeight: 10,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: const Color.fromARGB(255, 173, 165, 165),
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorWeight: 3,
          tabs: _tabs,
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
          children: _tabViews,
        ),
      ),
    );
  }
}
