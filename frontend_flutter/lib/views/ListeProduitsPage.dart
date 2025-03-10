import 'package:flutter/material.dart';
import '../models/produits.dart';
import '../services/api_service.dart';

class ProduitsPage extends StatefulWidget {
  @override
  _ProduitsPageState createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  List<Produit> _produits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProduits();
  }

  Future<void> _fetchProduits() async {
    try {
      final produits = await ApiService.getProduits();
      setState(() {
        _produits = produits;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  void _modifierProduit(Produit produit, int indexTaille) {
    var tailleData = produit.tailles[indexTaille];
    TextEditingController tailleController =
        TextEditingController(text: tailleData['taille']);
    TextEditingController couleurController =
        TextEditingController(text: tailleData['couleur']);
    TextEditingController quantiteController =
        TextEditingController(text: tailleData['quantite'].toString());
    String etat = tailleData['etat'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Modifier Produit",
              style: TextStyle(color: Colors.blue[900])),
          content: SizedBox(
            width: 500, // Wider dialog
            height: 350, // Longer dialog
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: etat,
                    items: ['coupé', 'moulé'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        etat = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "État",
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          16), // Space between the dropdown and next input field

                  TextField(
                    controller: tailleController,
                    decoration: InputDecoration(
                      labelText: "Taille",
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          16), // Space between the dropdown and next input field

                  TextField(
                    controller: couleurController,
                    decoration: InputDecoration(
                      labelText: "Couleur",
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                  SizedBox(
                      height:
                          16), // Space between the dropdown and next input field

                  TextField(
                    controller: quantiteController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Quantité",
                      labelStyle: TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: TextStyle(color: Colors.red[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                produit.tailles[indexTaille] = {
                  'taille': tailleController.text,
                  'couleur': couleurController.text,
                  'etat': etat,
                  'matiere': tailleData['matiere'],
                  'quantite': int.parse(quantiteController.text),
                };

                await ApiService.updateProduit(produit.id, produit.toJson());

                _fetchProduits();
                Navigator.pop(context);
              },
              child:
                  Text("Modifier", style: TextStyle(color: Colors.green[800])),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _supprimerProduit(String id) async {
    // Confirm delete action
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Supprimer Produit",
              style: TextStyle(color: Colors.red[700])),
          content: Text("Êtes-vous sûr de vouloir supprimer ce produit ?",
              style: TextStyle(color: Colors.red[600])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: TextStyle(color: Colors.blue[500])),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.deleteProduit(id);
                _fetchProduits();
                Navigator.pop(context); // Close dialog
              },
              child: Text("Supprimer", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[200],
        title:
            Text("Liste des Produits", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality if needed
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _produits.length,
              itemBuilder: (context, index) {
                final produit = _produits[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.teal[200]!),
                  ),
                  elevation: 5,
                  color: Colors.blueAccent[50],
                  child: ExpansionTile(
                    tilePadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    title: Text(produit.modele.nom,
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DataTable(
                          columns: [
                            DataColumn(
                                label: Text('Taille',
                                    style:
                                        TextStyle(color: Colors.purple[600]))),
                            DataColumn(
                                label: Text('Couleur',
                                    style:
                                        TextStyle(color: Colors.purple[600]))),
                            DataColumn(
                                label: Text('État',
                                    style:
                                        TextStyle(color: Colors.purple[600]))),
                            DataColumn(
                                label: Text('Quantité',
                                    style:
                                        TextStyle(color: Colors.purple[600]))),
                            DataColumn(
                                label: Text('Actions',
                                    style:
                                        TextStyle(color: Colors.purple[600]))),
                          ],
                          rows: produit.tailles.map((tailleData) {
                            return DataRow(
                              cells: [
                                DataCell(Text(tailleData['taille'],
                                    style: TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['couleur'],
                                    style: TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['etat'],
                                    style: TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['quantite'].toString(),
                                    style: TextStyle(color: Colors.black87))),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.lightBlue),
                                        onPressed: () {
                                          int indexTaille = produit.tailles
                                              .indexOf(tailleData);
                                          _modifierProduit(
                                              produit, indexTaille);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red[500]),
                                        onPressed: () {
                                          _supprimerProduit(produit.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
