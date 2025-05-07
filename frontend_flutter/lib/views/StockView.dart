import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import 'matiereView.dart';
import 'ListeProduitsPage.dart';
import 'StockModeleView.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockView extends StatefulWidget {
  const StockView({super.key});

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
        const Tab(text: "Produits"),
        const Tab(text: "Modèles"),
      ];
      _tabViews = [
        ProduitsPage(),
        StockModeleView(),
      ];
    } else if (role == 'responsable_matiere') {
      _tabs = [const Tab(text: "Matières")];
      _tabViews = [MatiereView()];
    } else {
      _tabs = [
        const Tab(text: "Produits"),
        const Tab(text: "Matières"),
        const Tab(text: "Modèles"),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la déconnexion",
          style: TextStyle(
              fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.bold),
        ),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            child:
                const Text("Déconnexion", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[800],
        actions: [
          FadeInRight(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorWeight: 3,
          tabs: _tabs,
          labelStyle:
              const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeIn(
          child: TabBarView(
            controller: _tabController,
            children: _tabViews,
          ),
        ),
      ),
    );
  }
}
