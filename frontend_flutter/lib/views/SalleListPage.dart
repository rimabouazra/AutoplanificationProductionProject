import 'package:flutter/material.dart';
import 'MachinesParSalleView.dart';
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
    final response =
        await http.get(Uri.parse('http://localhost:5000/api/salles'));

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
      appBar: AppBar(
        title: const Text('Liste des Salles'),
        backgroundColor: Colors.blueGrey[900],
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: salles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: EdgeInsets.all(10),
                itemCount: salles.length,
                itemBuilder: (context, index) {
                  final salle = salles[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.meeting_room, color: Colors.blueGrey),
                      title: Text(
                        salle['nom'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Capacité: ${salle['capacité']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.blueGrey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MachinesParSalleView(salleId: salle['_id']),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
