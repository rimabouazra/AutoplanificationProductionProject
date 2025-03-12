import 'package:flutter/material.dart';
import 'package:frontend/models/modele.dart';
import 'package:provider/provider.dart';
import '../models/matiere.dart';
import '../models/produits.dart';
import '../providers/ProduitProvider.dart';
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

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            hint: Text(label),
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Icon(icon, color: Colors.blue.shade600, size: 18),
                    SizedBox(width: 10),
                    Text(item),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
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
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Modifier Produit",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 15),

                _buildDropdown(
                  value: etat,
                  label: "État",
                  icon: Icons.timeline,
                  items: ['coupé', 'moulé'],
                  onChanged: (String? newValue) {
                    setState(() {
                      etat = newValue!;
                    });
                  },
                ),

                _buildStyledTextField(
                    controller: tailleController, label: "Taille", icon: Icons.format_size),
                _buildStyledTextField(
                    controller: couleurController, label: "Couleur", icon: Icons.color_lens),
                _buildStyledTextField(
                    controller: quantiteController,
                    label: "Quantité",
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.number),

                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton("Annuler", Icons.cancel, Colors.red.shade300, () {
                      Navigator.of(context).pop();
                    }),
                    _buildActionButton("Modifier", Icons.check_circle, Colors.green.shade400,
                            () async {
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
                        }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _supprimerProduit(String id) async {
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

  void _supprimerTaille(String produitId, int tailleIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("Supprimer Taille", style: TextStyle(color: Colors.red[700])),
          content: Text("Êtes-vous sûr de vouloir supprimer cette taille ?", style: TextStyle(color: Colors.red[600])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: TextStyle(color: Colors.blue[500])),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<ProduitProvider>(context, listen: false)
                    .supprimerTaille(produitId, tailleIndex);
                Navigator.pop(context);
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

    String? etatSelectionne = 'coupé';
    Matiere? matiereSelectionnee;

    List<Map<String, dynamic>> taillesList = [];

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
      List<Map<String, dynamic>> taillesList,
      String etat,
      Matiere? matiere
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

      final nouveauProduit = Produit(
        id: '',
        modele: modele,
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

  void _showAddTailleDialog(String produitId) {
    TextEditingController tailleController = TextEditingController();
    TextEditingController couleurController = TextEditingController();
    TextEditingController etatController = TextEditingController();
    TextEditingController quantiteController = TextEditingController();
    String? selectedMatiere;
    List<String> matieres = []; // List to hold matières from API


    fetchMatieres();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ajouter une taille",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: 15),
                _buildStyledTextField(
                    controller: tailleController, label: "Taille", icon: Icons.format_size),
                _buildStyledTextField(
                    controller: couleurController, label: "Couleur", icon: Icons.color_lens),
                _buildStyledTextField(
                    controller: etatController, label: "État", icon: Icons.timeline),
                _buildStyledTextField(
                    controller: quantiteController,
                    label: "Quantité",
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.number),
                SizedBox(height: 10),
                // Matière Dropdown
                matieres.isNotEmpty
                    ? _buildDropdown(
                  value: selectedMatiere,
                  label: "Matière",
                  icon: Icons.category,
                  items: matieres,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedMatiere = newValue;
                    });
                  },
                )
                    : CircularProgressIndicator(), // Loading state while fetching

                SizedBox(height: 20),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton("Annuler", Icons.cancel, Colors.red.shade300, () {
                      Navigator.of(context).pop();
                    }),
                    _buildActionButton("Ajouter", Icons.check_circle, Colors.green.shade400,
                            () async {
                          Map<String, dynamic> tailleData = {
                            'taille': tailleController.text,
                            'couleur': couleurController.text,
                            'etat': etatController.text,
                            'quantite': int.parse(quantiteController.text),
                            'matiere': selectedMatiere,
                          };

                          try {
                            await Provider.of<ProduitProvider>(context, listen: false)
                                .ajouterTailleAuProduit(produitId, tailleData);

                            // Update the UI immediately
                            setState(() {
                              final produit = _produits.firstWhere((p) => p.id == produitId);
                              produit.tailles.add(tailleData);
                            });
                          } catch (e) {
                            print("Erreur lors de l'ajout de la taille : $e");
                          }

                          Navigator.of(context).pop();
                        }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }


  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      onPressed: onPressed,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
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
        backgroundColor: Colors.teal[300],
        label: Text(""),
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
            child: Column(
              children: [
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  title: Text(
                    produit.modele.nom,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[500]),
                    onPressed: () {
                      _supprimerProduit(produit.id);
                    },
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: DataTable(
                        columnSpacing: 20,  // Adjust column spacing to make the table wider
                        horizontalMargin: 10, // Increase horizontal margin for wider appearance
                        dataTextStyle: TextStyle(fontSize: 16, color: Colors.black87), // Make text a little bigger
                        headingTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple[600]), // Larger headers
                        columns: [
                          DataColumn(
                            label: Text('Taille', style: TextStyle(color: Colors.purple[600])),
                          ),
                          DataColumn(
                            label: Text('Couleur', style: TextStyle(color: Colors.purple[600])),
                          ),
                          DataColumn(
                            label: Text('État', style: TextStyle(color: Colors.purple[600])),
                          ),
                          DataColumn(
                            label: Text('Quantité', style: TextStyle(color: Colors.purple[600])),
                          ),
                          DataColumn(
                            label: Text('Actions', style: TextStyle(color: Colors.purple[600])),
                          ),
                        ],
                        rows: produit.tailles.map((tailleData) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(tailleData['taille'], style: TextStyle(color: Colors.black87, fontSize: 16)),
                              ),
                              DataCell(
                                Text(tailleData['couleur'], style: TextStyle(color: Colors.black87, fontSize: 16)),
                              ),
                              DataCell(
                                Text(tailleData['etat'], style: TextStyle(color: Colors.black87, fontSize: 16)),
                              ),
                              DataCell(
                                Text(tailleData['quantite'].toString(), style: TextStyle(color: Colors.black87, fontSize: 16)),
                              ),
                              DataCell(
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add, color: Colors.green),
                                      onPressed: () {
                                        _showAddTailleDialog(produit.id);
                                      },
                                    ),


                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.lightBlue),
                                      onPressed: () {
                                        int indexTaille = produit.tailles.indexOf(tailleData);
                                        _modifierProduit(produit, indexTaille);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red[500]),
                                      onPressed: () {
                                        int indexTaille = produit.tailles.indexOf(tailleData);
                                        _supprimerTaille(produit.id, indexTaille);
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
                )

              ],
            ),
          );
        },
      ),
    );
  }
}
