import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/modeleProvider.dart';
import '../models/modele.dart';

class StockModeleView extends StatefulWidget {
  @override
  _StockModeleViewState createState() => _StockModeleViewState();
}

class _StockModeleViewState extends State<StockModeleView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModeleProvider>(context, listen: false).fetchModeles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final modeleProvider = Provider.of<ModeleProvider>(context);
    final modeles = modeleProvider.modeles;

    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des Modèles"),
        backgroundColor: Colors.blueAccent,
      ),
      body: modeles.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: modeles.length,
              itemBuilder: (context, index) {
                final modele = modeles[index];
                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      modele.nom,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text("Tailles disponibles: ${modele.tailles.join(', ')}"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bases associées:",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            modele.derives != null && modele.derives!.isNotEmpty
                                ? Column(
                                    children: modele.derives!.map((base) {
                                      return ListTile(
                                        leading: Icon(Icons.link, color: Colors.blueAccent),
                                        title: Text(base.nom),
                                        subtitle: Text("Tailles: ${base.tailles.join(', ')}"),
                                      );
                                    }).toList(),
                                  )
                                : Text("Aucune base associée", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
