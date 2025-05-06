import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/models/modele.dart';
import 'package:provider/provider.dart';
import '../models/matiere.dart';
import '../models/produits.dart';
import '../providers/ProduitProvider.dart';
import '../services/api_service.dart';

class ProduitsPage extends StatefulWidget {
  const ProduitsPage({super.key});

  @override
  _ProduitsPageState createState() => _ProduitsPageState();
}

class _ProduitsPageState extends State<ProduitsPage> {
  List<Produit> _produits = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchProduits();
  }

  List<Produit> get filteredProduits {
    final produits = Provider.of<ProduitProvider>(context).produits;
    return produits.where((produit) {
      final produitNom = produit.modele.nom.trim().toLowerCase();
      final searchQuery = _searchController.text.trim().toLowerCase();
      return searchQuery.isEmpty || produitNom.contains(searchQuery);
    }).toList();
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
    final List<dynamic> rawData = await ApiService.getMatieres();
    return rawData.map((json) => Matiere.fromJson(json)).toList();
  }

  Future<List<Modele>> fetchModeles() async {
    final response = await ApiService.getModeles();
    if (response is List<Modele>) {
      return response;
    } else {
      throw Exception('Erreur lors de la récupération des modèles');
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                    Icon(icon, color: Colors.blueGrey[700], size: 18),
                    const SizedBox(width: 10),
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
    final tailleData = produit.tailles[indexTaille];
    final TextEditingController tailleController = TextEditingController(text: tailleData['taille']);
    final TextEditingController couleurController = TextEditingController(text: tailleData['couleur']);
    final TextEditingController quantiteController = TextEditingController(text: tailleData['quantite'].toString());
    String etat = tailleData['etat'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blueGrey[50]!, Colors.white],
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
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 15),
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
                  controller: tailleController,
                  label: "Taille",
                  icon: Icons.format_size,
                ),
                _buildStyledTextField(
                  controller: couleurController,
                  label: "Couleur",
                  icon: Icons.color_lens,
                ),
                _buildStyledTextField(
                  controller: quantiteController,
                  label: "Quantité",
                  icon: Icons.production_quantity_limits,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton("Annuler", Icons.cancel, Colors.red[300]!, () {
                      Navigator.of(context).pop();
                    }),
                    _buildActionButton("Modifier", Icons.check_circle, Colors.green[400]!, () async {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Supprimer Produit",
            style: TextStyle(fontFamily: 'PlayfairDisplay', color: Colors.red[700]),
          ),
          content: Text("Êtes-vous sûr de vouloir supprimer ce produit ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: TextStyle(color: Colors.blue[500])),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.deleteProduit(id);
                _fetchProduits();
                Navigator.pop(context);
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Supprimer Taille",
            style: TextStyle(fontFamily: 'PlayfairDisplay', color: Colors.red[700]),
          ),
          content: Text("Êtes-vous sûr de vouloir supprimer cette taille ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Annuler", style: TextStyle(color: Colors.blue[500])),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<ProduitProvider>(context, listen: false).supprimerTaille(produitId, tailleIndex);
                Navigator.pop(context);
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _ajouterProduit() {
    final TextEditingController _modeleController = TextEditingController();
    final TextEditingController _tailleController = TextEditingController();
    final TextEditingController _couleurController = TextEditingController();
    final TextEditingController _quantiteController = TextEditingController();
    String? etatSelectionne = 'coupé';
    Matiere? matiereSelectionnee;
    final List<Map<String, dynamic>> taillesList = [];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Ajouter un Produit",
            style: TextStyle(fontFamily: 'PlayfairDisplay', color: Colors.blueGrey[800]),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStyledTextField(
                    controller: _modeleController,
                    label: "Modèle",
                    icon: Icons.view_in_ar,
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _tailleController,
                    label: "Taille",
                    icon: Icons.format_size,
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _couleurController,
                    label: "Couleur",
                    icon: Icons.color_lens,
                  ),
                  const SizedBox(height: 16),
                  _buildStyledTextField(
                    controller: _quantiteController,
                    label: "Quantité",
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: etatSelectionne,
                    items: ['coupé', 'moulé'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      etatSelectionne = newValue;
                    },
                    decoration: InputDecoration(
                      labelText: "État",
                      prefixIcon: const Icon(Icons.timeline, color: Colors.blueGrey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Matiere>>(
                    future: fetchMatieres(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final matieres = snapshot.data!;
                      return DropdownButtonFormField<Matiere>(
                        value: matiereSelectionnee,
                        items: matieres.map((Matiere matiere) {
                          return DropdownMenuItem<Matiere>(
                            value: matiere,
                            child: Text(matiere.reference),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          matiereSelectionnee = newValue;
                        },
                        decoration: InputDecoration(
                          labelText: "Matière (optionnel)",
                          prefixIcon: const Icon(Icons.category, color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final taille = _tailleController.text.trim();
                      final couleur = _couleurController.text.trim();
                      final quantiteStr = _quantiteController.text.trim();
                      if (taille.isNotEmpty &&
                          couleur.isNotEmpty &&
                          quantiteStr.isNotEmpty) {
                        int? quantite = int.tryParse(quantiteStr);
                        if (quantite != null && quantite > 0) {
                          taillesList.add({
                            'taille': taille,
                            'couleur': couleur,
                            'etat': etatSelectionne,
                            'matiere': matiereSelectionnee?.toJson(),
                            'quantite': quantite,
                          });
                          _tailleController.clear();
                          _couleurController.clear();
                          _quantiteController.clear();
                        }
                      }
                    },
                    child: const Text("Ajouter Taille"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                await _validerEtAjouterProduit(
                  _modeleController.text.trim(),
                  taillesList,
                  etatSelectionne ?? '',
                  matiereSelectionnee,
                );
              },
              child: Text("Ajouter", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
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
          prefixIcon: Icon(icon, color: Colors.blueGrey[700]),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: onPressed,
    );
  }

  Future<void> _validerEtAjouterProduit(
      String modeleNom, List<Map<String, dynamic>> taillesList, String etat, Matiere? matiere) async {
    if (modeleNom.isEmpty || taillesList.isEmpty || etat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs correctement."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final apiService = ApiService();
      final modele = await apiService.getModeleParNom(modeleNom);
      if (modele == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Modèle non trouvé."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final nouveauProduit = Produit(
        id: '',
        modele: modele,
        tailles: taillesList,
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
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showAddTailleDialog(String produitId) {
    final TextEditingController quantiteController = TextEditingController();
    final TextEditingController couleurController = TextEditingController();
    String? selectedModeleNom;
    String? selectedModeleId;
    String? selectedTaille;
    String? selectedEtat;
    String? selectedMatiereId;
    String? selectedCouleur;
    List<Modele> modeles = [];
    List<String> tailles = [];
    final List<String> etats = ['moulé', 'coupé'];
    List<Matiere> matieres = [];

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: Future.wait([fetchModeles(), fetchMatieres()]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              print("Erreur lors du chargement : ${snapshot.error}");
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text("Erreur de chargement des données")),
                ),
              );
            }

            modeles = snapshot.data![0] as List<Modele>;
            matieres = snapshot.data![1] as List<Matiere>;

            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [Colors.blueGrey[50]!, Colors.white],
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
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: selectedModeleNom,
                          decoration: _inputDecoration("Modèle", Icons.view_in_ar),
                          items: modeles.map((modele) {
                            return DropdownMenuItem(value: modele.nom, child: Text(modele.nom));
                          }).toList(),
                          onChanged: (value) async {
                            setState(() {
                              selectedModeleNom = value;
                            });
                            final modele = modeles.firstWhere(
                              (m) => m.nom == value,
                              orElse: () => Modele(id: '', nom: '', tailles: [], consommation: []),
                            );
                            if (modele.id.isNotEmpty) {
                              setState(() {
                                selectedModeleId = modele.id;
                                tailles = modele.tailles;
                                selectedTaille = null;
                              });
                            } else {
                              selectedModeleId = null;
                              tailles = [];
                              selectedTaille = null;
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedTaille,
                          decoration: _inputDecoration("Taille", Icons.format_size),
                          items: tailles.map((taille) {
                            return DropdownMenuItem(value: taille, child: Text(taille));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTaille = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedEtat,
                          decoration: _inputDecoration("État", Icons.timeline),
                          items: etats.map((etat) {
                            return DropdownMenuItem(value: etat, child: Text(etat));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedEtat = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedMatiereId,
                          decoration: _inputDecoration("Matière", Icons.category),
                          items: matieres.map((matiere) {
                            return DropdownMenuItem(value: matiere.id, child: Text(matiere.reference));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMatiereId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: couleurController,
                          decoration: _inputDecoration("Couleur", Icons.color_lens),
                          onChanged: (value) {
                            setState(() {
                              selectedCouleur = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: quantiteController,
                          decoration: _inputDecoration("Quantité", Icons.production_quantity_limits),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton("", Icons.cancel, Colors.red[300]!, () {
                              Navigator.of(context).pop();
                            }),
                            _buildActionButton("", Icons.check_circle, Colors.green[400]!, () async {
                              if (selectedModeleId == null ||
                                  selectedTaille == null ||
                                  selectedEtat == null ||
                                  selectedMatiereId == null ||
                                  selectedCouleur == null ||
                                  quantiteController.text.isEmpty) {
                                print("Veuillez remplir tous les champs !");
                                return;
                              }

                              final Map<String, dynamic> tailleData = {
                                'modeleId': selectedModeleId,
                                'taille': selectedTaille,
                                'etat': selectedEtat,
                                'matiere': selectedMatiereId,
                                'couleur': selectedCouleur,
                                'quantite': int.parse(quantiteController.text),
                              };

                              try {
                                await Provider.of<ProduitProvider>(context, listen: false)
                                    .ajouterTailleAuProduit(produitId, tailleData);
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
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueGrey[700]),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[800],
        title: FadeInDown(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSearching ? 200 : 0,
                  curve: Curves.easeInOut,
                  child: _isSearching
                      ? TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Rechercher...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white70),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (query) {
                            setState(() {});
                          },
                        )
                      : const SizedBox(),
                ),
              ),
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ZoomIn(
        child: FloatingActionButton.extended(
          onPressed: () {
            _ajouterProduit();
          },
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blueGrey[800],
          label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _produits.length,
                itemBuilder: (context, index) {
                  final produit = _produits[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 5,
                      color: Colors.white,
                      child: Column(
                        children: [
                          ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            title: Text(
                              produit.modele.nom,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold,
                              ),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DataTable(
                                  columnSpacing: 20,
                                  horizontalMargin: 10,
                                  dataTextStyle: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                                  headingTextStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[800],
                                  ),
                                  columns: [
                                    DataColumn(label: Text('Taille', style: TextStyle(color: Colors.blueGrey[800]))),
                                    DataColumn(label: Text('Couleur', style: TextStyle(color: Colors.blueGrey[800]))),
                                    DataColumn(label: Text('État', style: TextStyle(color: Colors.blueGrey[800]))),
                                    DataColumn(label: Text('Quantité', style: TextStyle(color: Colors.blueGrey[800]))),
                                    DataColumn(label: Text('Actions', style: TextStyle(color: Colors.blueGrey[800]))),
                                  ],
                                  rows: produit.tailles.map((tailleData) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(tailleData['taille'], style: const TextStyle(color: Colors.blueGrey))),
                                        DataCell(Text(tailleData['couleur'], style: const TextStyle(color: Colors.blueGrey))),
                                        DataCell(Text(tailleData['etat'], style: const TextStyle(color: Colors.blueGrey))),
                                        DataCell(Text(tailleData['quantite'].toString(), style: const TextStyle(color: Colors.blueGrey))),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.add, color: Colors.green),
                                                onPressed: () {
                                                  _showAddTailleDialog(produit.id);
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                onPressed: () {
                                                  final indexTaille = produit.tailles.indexOf(tailleData);
                                                  _modifierProduit(produit, indexTaille);
                                                },
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete, color: Colors.red[500]),
                                                onPressed: () {
                                                  final indexTaille = produit.tailles.indexOf(tailleData);
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
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}