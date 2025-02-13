import 'package:flutter/material.dart';
import 'MachinesParSalleView.dart'; // Import de la page des machines par salle
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalleListPage extends StatefulWidget {
  const SalleListPage({Key? key}) : super(key: key);

  @override
  _SalleListPageState createState() => _SalleListPageState();
}

class _SalleListPageState extends State<SalleListPage> {
  List salles = [];

  @override
  void initState() {
    super.initState();
    fetchSalles();
  }

  Future<void> fetchSalles() async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/salles'));
    
    print(response.body); // DEBUG : Voir si l'API retourne bien les salles
    
    if (response.statusCode == 200) {
      setState(() {
        salles = json.decode(response.body);
      });
    } else {
      throw Exception('Échec du chargement des salles');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liste des Salles')),
      body: salles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: salles.length,
              itemBuilder: (context, index) {
                final salle = salles[index];
                return ListTile(
                  title: Text(salle['nom']),
                  subtitle: Text('Capacité: ${salle['capacité']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MachinesParSalleView(salleId: salle['_id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
