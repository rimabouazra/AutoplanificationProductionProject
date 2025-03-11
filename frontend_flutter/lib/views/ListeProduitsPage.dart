import 'package:flutter/material.dart';
import 'package:frontend/models/modele.dart';
import '../models/matiere.dart';
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

  Future<List<Matiere>> fetchMatieres() async {
    List<dynamic> rawData = await ApiService.getMatieres();
    return rawData.map((json) => Matiere.fromJson(json)).toList();
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
                            style: const TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        etat = newValue!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "État",
                      labelStyle: const TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height:16
                  ),

                  TextField(
                    controller: tailleController,
                    decoration: InputDecoration(
                      labelText: "Taille",
                      labelStyle: const TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height:
                          16), // Space between the dropdown and next input field

                  TextField(
                    controller: couleurController,
                    decoration: InputDecoration(
                      labelText: "Couleur",
                      labelStyle: const TextStyle(color: Colors.black87),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal[50]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white60!),
                      ),
                    ),
                  ),
                  const SizedBox(
                      height:
                          16), // Space between the dropdown and next input field

                  TextField(
                    controller: quantiteController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Quantité",
                      labelStyle: const TextStyle(color: Colors.black87),
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
              child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
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

  void _ajouterProduit() {
    TextEditingController _modeleController = TextEditingController();
    TextEditingController _tailleController = TextEditingController();
    TextEditingController _couleurController = TextEditingController();
    TextEditingController _quantiteController = TextEditingController();

    String? etatSelectionne = 'coupé'; // Valeur par défaut
    Matiere? matiereSelectionnee; // Matière sélectionnée

    List<Map<String, dynamic>> taillesList = []; // Liste pour stocker les tailles

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Ajouter un Produit", style: TextStyle(color: Colors.blue[900])),
          content: SizedBox(
            width: 500,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_modeleController, "Modèle"),
                  const SizedBox(height: 16),
                  // Champ pour ajouter une taille
                  _buildTextField(_tailleController, "Taille"),
                  const SizedBox(height: 16),
                  _buildTextField(_couleurController, "Couleur"),
                  const SizedBox(height: 16),
                  _buildTextField(_quantiteController, "Quantité", isNumeric: true),
                  const SizedBox(height: 16),

                  // Dropdown pour l'état
                  DropdownButtonFormField<String>(
                    value: etatSelectionne,
                    items: ['coupé', 'moulé'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      etatSelectionne = newValue;
                    },
                    decoration: const InputDecoration(
                      labelText: "État",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FutureBuilder pour charger les matières disponibles
                  FutureBuilder<List<Matiere>>(
                    future: fetchMatieres(), // Fonction pour récupérer les matières
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      List<Matiere> matieres = snapshot.data!;
                      return DropdownButtonFormField<Matiere>(
                        value: matiereSelectionnee,
                        items: matieres.map((Matiere matiere) {
                          return DropdownMenuItem<Matiere>(value: matiere, child: Text(matiere.reference));
                        }).toList(),
                        onChanged: (newValue) {
                          matiereSelectionnee = newValue;
                        },
                        decoration: const InputDecoration(
                          labelText: "Matière (optionnel)",
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  ),

                  // Bouton pour ajouter la taille à la liste
                  ElevatedButton(
                    onPressed: () {
                      String taille = _tailleController.text.trim();
                      String couleur = _couleurController.text.trim();
                      String quantiteStr = _quantiteController.text.trim();
                      if (taille.isNotEmpty && couleur.isNotEmpty && quantiteStr.isNotEmpty) {
                        int? quantite = int.tryParse(quantiteStr);
                        if (quantite != null && quantite > 0) {
                          taillesList.add({
                            'taille': taille,
                            'couleur': couleur,
                            'etat': etatSelectionne,
                            'matiere': matiereSelectionnee?.toJson(),
                            'quantite': quantite,
                          });
                          // Clear the input fields for next size
                          _tailleController.clear();
                          _couleurController.clear();
                          _quantiteController.clear();
                        }
                      }
                    },
                    child: Text("Ajouter Taille"),
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
                await _validerEtAjouterProduit(
                  _modeleController.text.trim(),
                  taillesList, // Pass the list of sizes
                  etatSelectionne ?? '',
                  matiereSelectionnee,
                );
              },
              child: Text("Ajouter", style: TextStyle(color: Colors.green[800])),
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


  Widget _buildTextField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal[50]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue[300]!),
        ),
      ),
    );
  }

  Future<void> _validerEtAjouterProduit(
      String modeleNom,
      List<Map<String, dynamic>> taillesList,  // Correctly expecting a list of sizes
      String etat,                            // Correctly expecting a string for the state
      Matiere? matiere                        // Correctly expecting an optional Matiere object
      ) async {
    // Validation des champs
    if (modeleNom.isEmpty || taillesList.isEmpty || etat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs correctement."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ApiService apiService = ApiService();
      Modele? modele = await apiService.getModeleParNom(modeleNom);
      if (modele == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Modèle non trouvé."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Créer un objet Produit avec plusieurs tailles
      final nouveauProduit = Produit(
        id: '',  // Il peut s'agir d'un ID vide ou être généré côté serveur
        modele: modele,  // Pass the modele object
        tailles: taillesList,  // Pass the list of sizes
      );

      await ApiService.addProduit(nouveauProduit);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produit ajouté avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      _fetchProduits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'ajout du produit : ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[200],
        title:
            const Text("Liste des Produits", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality if needed
            },
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _ajouterProduit();
        },
        icon: Icon(Icons.add),
        backgroundColor: Colors.teal[300], label:Text(""),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _produits.length,
              itemBuilder: (context, index) {
                final produit = _produits[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.teal[200]!),
                  ),
                  elevation: 5,
                  color: Colors.blueAccent[50],
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    title: Text(produit.modele.nom,
                        style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold)),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
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
                                    style: const TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['couleur'],
                                    style: const TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['etat'],
                                    style: const TextStyle(color: Colors.black87))),
                                DataCell(Text(tailleData['quantite'].toString(),
                                    style: const TextStyle(color: Colors.black87))),
                                DataCell(
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
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
