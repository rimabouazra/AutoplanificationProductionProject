import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/views/LoginPage.dart';
import '../providers/modeleProvider.dart';
import '../services/api_service.dart';
import 'AddCommandePage.dart';
import 'package:provider/provider.dart';
import '../providers/CommandeProvider.dart';
import '../models/commande.dart';
import '../models/modele.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CommandePage extends StatefulWidget {
  const CommandePage({Key? key}) : super(key: key);

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  String selectedFilter = 'Tous';
  final Map<String, String> nextEtatMap = {
    "en attente": "en coupe",
    "en coupe": "en moulage",
    "en moulage": "en presse",
    "en presse": "en contrôle",
    "en contrôle": "emballage",
    "emballage": "terminé",
  };
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Provider.of<CommandeProvider>(context, listen: false).fetchCommandes();
    Provider.of<ModeleProvider>(context, listen: false).fetchModeles();
  }

  List<String> filters = [
    "Tous",
    "En attente",
    "En coupe",
    "En moulage",
    "En presse",
    "En contrôle",
    "Emballage",
    "Terminé"
  ];

  Color getStatusColor(String status) {
    switch (status) {
      case "En attente":
        return Colors.red[600]!;
      case "Terminé":
        return Colors.green[600]!;
      case "En coupe":
      case "En moulage":
      case "En presse":
      case "En contrôle":
      case "Emballage":
        return Colors.orange[600]!;
      default:
        return Colors.blueGrey[600]!;
    }
  }

  Future<void> markCommandeAsComplete(Commande commande) async {
    try {
      final currentEtat = commande.etat.toLowerCase();
      final nextEtat = nextEtatMap[currentEtat] ?? currentEtat;

      if (nextEtat == currentEtat) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("La commande est déjà dans son état final"),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      bool success = await Provider.of<CommandeProvider>(context, listen: false)
          .updateCommandeEtat(commande.id!, nextEtat);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Commande passée à l'état: $nextEtat"),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await Provider.of<CommandeProvider>(context, listen: false).fetchCommandes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Erreur lors de la mise à jour de la commande"),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  List<Commande> get filteredCommandes {
    final commandes = Provider.of<CommandeProvider>(context).commandes;

    return commandes.where((commande) {
      final etatCommande = commande.etat.trim().toLowerCase();
      final etatFiltre = selectedFilter.trim().toLowerCase();

      final matchesFilter = etatFiltre == 'tous' || etatCommande == etatFiltre;
      final matchesSearch = searchController.text.isEmpty ||
          commande.client.name.toLowerCase().contains(searchController.text.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }

  Map<String, int> calculateQuantities(List<CommandeModele> modeles) {
    int totalDemandee = 0;
    int totalCalculee = 0;
    int totalReelle = 0;

    for (var modele in modeles) {
      totalDemandee += modele.quantite;
      totalCalculee += modele.quantiteCalculee;
      totalReelle += modele.quantiteReelle;
    }

    return {
      'totalDemandee': totalDemandee,
      'totalCalculee': totalCalculee,
      'totalReelle': totalReelle,
    };
  }

  void deleteCommande(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Confirmation de suppression',
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          content: const Text('Voulez-vous vraiment supprimer cette commande ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CommandeProvider>(context, listen: false).deleteCommande(id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Commande supprimée avec succès"),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> printCommande(Commande commande) async {
    final pdf = pw.Document();
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);

    bool isCoupeState = commande.etat.toLowerCase() == "en coupe";

    for (var modele in commande.modeles) {
      if (modele.nomModele.isEmpty && modele.modele != null) {
        String? fetchedNom = await Provider.of<CommandeProvider>(context, listen: false)
            .getModeleNom(modele.modele!);
        modele.nomModele = fetchedNom ?? "Modèle inconnu";
      }
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Détails de la commande',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Client: ${commande.client.name}'),
              pw.Text('Conditionnement: ${commande.conditionnement}'),

              pw.SizedBox(height: 20),
              pw.Text('Modèles:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Modèle'),
                      pw.Text('Taille'),
                      pw.Text('Couleur'),
                      pw.Text('Quantité'),
                      if (isCoupeState) pw.Text('Quantité Calculée'),
                      if (isCoupeState) pw.Text('Quantité Réelle'),
                    ],
                  ),
                  ...commande.modeles.map((modele) {
                    double consommation = 0;

                    final modeleDetails = modeleProvider.modeleMap[modele.modele];
                    if (modeleDetails != null) {
                      final item = modeleDetails.consommation.firstWhere(
                        (c) => c.taille == modele.taille,
                        orElse: () => Consommation(taille: '', quantity: 0),
                      );
                      consommation = item.quantity;
                    }

                    double quantiteCalculee = modele.quantite * consommation;

                    return pw.TableRow(
                      children: [
                        pw.Text(modele.nomModele),
                        pw.Text(modele.taille),
                        pw.Text(modele.couleur),
                        pw.Text(modele.quantite.toString()),
                        if (isCoupeState) pw.Text(quantiteCalculee.toStringAsFixed(2)),
                        if (isCoupeState) pw.Text(modele.quantiteReelle.toString()),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> editCommande(Commande commande) async {
    TextEditingController clientController = TextEditingController(text: commande.client.name);

    List<TextEditingController> nomModeleControllers = [];
    List<TextEditingController> tailleControllers = [];
    List<TextEditingController> couleurControllers = [];
    List<TextEditingController> quantiteControllers = [];

    List<CommandeModele> updatedModeles = List.from(commande.modeles);

    for (var modele in updatedModeles) {
      if (modele.nomModele.isEmpty && modele.modele != null) {
        String? fetchedNom = await Provider.of<CommandeProvider>(context, listen: false)
            .getModeleNom(modele.modele!);
        modele.nomModele = fetchedNom ?? "Modèle inconnu";
      }
    }

    nomModeleControllers.clear();
    tailleControllers.clear();
    couleurControllers.clear();
    quantiteControllers.clear();

    for (var modele in updatedModeles) {
      nomModeleControllers.add(TextEditingController(text: modele.nomModele));
      tailleControllers.add(TextEditingController(text: modele.taille));
      couleurControllers.add(TextEditingController(text: modele.couleur));
      quantiteControllers.add(TextEditingController(text: modele.quantite.toString()));
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            bool isSavingModeles = false;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Modifier Commande',
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              content: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey))
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: clientController,
                              decoration: InputDecoration(
                                labelText: 'Client',
                                prefixIcon: const Icon(Icons.person, color: Colors.blueGrey),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              enabled: false,
                            ),
                            const SizedBox(height: 15),
                            ...List.generate(updatedModeles.length, (index) {
                              return FadeInUp(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: nomModeleControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Nom du modèle',
                                              prefixIcon: const Icon(Icons.category, color: Colors.blueGrey),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ZoomIn(
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              bool confirmDelete = await showDialog(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(20)),
                                                      title: const Text(
                                                        'Confirmer la suppression',
                                                        style: TextStyle(
                                                            fontFamily: 'PlayfairDisplay',
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.blueGrey),
                                                      ),
                                                      content: const Text(
                                                          'Êtes-vous sûr de vouloir supprimer ce modèle ?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: const Text('Annuler',
                                                              style: TextStyle(color: Colors.blueGrey)),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red[600],
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          child: const Text('Supprimer',
                                                              style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  ) ??
                                                  false;

                                              if (confirmDelete) {
                                                setState(() {
                                                  updatedModeles.removeAt(index);
                                                  nomModeleControllers.removeAt(index);
                                                  tailleControllers.removeAt(index);
                                                  couleurControllers.removeAt(index);
                                                  quantiteControllers.removeAt(index);
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: tailleControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Taille',
                                              prefixIcon: const Icon(Icons.straighten, color: Colors.blueGrey),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: couleurControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Couleur',
                                              prefixIcon: const Icon(Icons.colorize, color: Colors.blueGrey),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: TextField(
                                            controller: quantiteControllers[index],
                                            decoration: InputDecoration(
                                              labelText: 'Quantité',
                                              prefixIcon: const Icon(Icons.numbers, color: Colors.blueGrey),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.9),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(thickness: 1, height: 20, color: Colors.blueGrey),
                                  ],
                                ),
                              );
                            }),
                            FadeInUp(
                              child: Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      updatedModeles.add(CommandeModele(
                                        modele: null,
                                        nomModele: "",
                                        taille: "",
                                        couleur: "",
                                        quantite: 0,
                                      ));
                                      nomModeleControllers.add(TextEditingController());
                                      tailleControllers.add(TextEditingController());
                                      couleurControllers.add(TextEditingController());
                                      quantiteControllers.add(TextEditingController());
                                    });
                                  },
                                  icon: const Icon(Icons.add, color: Colors.green),
                                  label: const Text('Ajouter un modèle', style: TextStyle(color: Colors.blueGrey)),
                                ),
                              ),
                            ),
                            if (isSavingModeles)
                              const Center(child: CircularProgressIndicator(color: Colors.blueGrey)),
                            if (!isSavingModeles)
                              FadeInUp(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        isSavingModeles = true;
                                      });

                                      for (int i = 0; i < updatedModeles.length; i++) {
                                        updatedModeles[i].nomModele = nomModeleControllers[i].text;
                                        updatedModeles[i].taille = tailleControllers[i].text;
                                        updatedModeles[i].couleur = couleurControllers[i].text;
                                        updatedModeles[i].quantite =
                                            int.tryParse(quantiteControllers[i].text) ?? 1;
                                      }

                                      setState(() {
                                        isSavingModeles = false;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey[800],
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text(
                                      'Enregistrer Modèles',
                                      style: TextStyle(color: Colors.white),
                                    ),
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
                  child: const Text('Annuler', style: TextStyle(color: Colors.blueGrey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool hasError = false;
                    List<Future<void>> futures = [];
                    setState(() {
                      isLoading = true;
                    });

                    for (int i = 0; i < updatedModeles.length; i++) {
                      futures.add(() async {
                        if (updatedModeles[i].nomModele.isEmpty && updatedModeles[i].modele != null) {
                          String? modeleNom = await Provider.of<CommandeProvider>(context, listen: false)
                              .getModeleNom(updatedModeles[i].modele!);
                          if (modeleNom != null) {
                            updatedModeles[i].nomModele = modeleNom;
                          } else {
                            hasError = true;
                          }
                        }

                        if ((updatedModeles[i].modele == null || updatedModeles[i].modele!.isEmpty) &&
                            updatedModeles[i].nomModele.isNotEmpty) {
                          String? modeleId = await Provider.of<CommandeProvider>(context, listen: false)
                              .getModeleId(updatedModeles[i].nomModele);
                          if (modeleId != null) {
                            updatedModeles[i].modele = modeleId;
                          } else {
                            hasError = true;
                          }
                        }

                        updatedModeles[i].taille = tailleControllers[i].text;
                        updatedModeles[i].couleur = couleurControllers[i].text;
                        updatedModeles[i].quantite = int.tryParse(quantiteControllers[i].text) ?? 1;
                      }());
                    }

                    await Future.wait(futures);

                    if (hasError) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Erreur dans les modèles."),
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      return;
                    }

                    bool success = await Provider.of<CommandeProvider>(context, listen: false)
                        .updateCommande(commande.id!, updatedModeles);

                    setState(() {
                      isLoading = false;
                    });

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Commande mise à jour avec succès !"),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                      await Provider.of<CommandeProvider>(context, listen: false).fetchCommandes();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Erreur lors de la mise à jour de la commande."),
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Enregistrer Commande',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void navigateToAddCommande() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCommandePage()),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la déconnexion",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        content: const Text(
          "Voulez-vous vraiment vous déconnecter ?",
          style: TextStyle(color: Colors.blueGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await AuthService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[800],
        title: FadeInDown(
          child: const Text(
            "Gestion des Commandes",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          FadeInRight(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(child: buildSearchBar()),
              const SizedBox(height: 16),
              FadeInUp(child: buildFilters()),
              const SizedBox(height: 16),
              Expanded(child: buildCommandesTable()),
            ],
          ),
        ),
      ),
      floatingActionButton: ZoomIn(
        child: FloatingActionButton(
          onPressed: navigateToAddCommande,
          backgroundColor: Colors.blueGrey[800],
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Rechercher une commande",
          hintStyle: TextStyle(color: Colors.blueGrey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.blueGrey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              selectedColor: Colors.blueGrey[800],
              backgroundColor: Colors.blueGrey[100],
              onSelected: (bool selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              labelStyle: TextStyle(
                color: selectedFilter == filter ? Colors.white : Colors.blueGrey[800],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildCommandesTable() {
    return ListView(
      children: filteredCommandes.asMap().entries.map((entry) {
        final commande = entry.value;
        int totalQuantite = commande.modeles.fold(0, (sum, m) => sum + m.quantite);

        return FadeInUp(
          delay: Duration(milliseconds: entry.key * 50),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                commande.client.name,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              trailing: Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getStatusColor(commande.etat).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      commande.etat,
                      style: TextStyle(
                        color: getStatusColor(commande.etat),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ZoomIn(
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editCommande(commande),
                    ),
                  ),
                  ZoomIn(
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCommande(commande.id!),
                    ),
                  ),
                  ZoomIn(
                    child: IconButton(
                      icon: const Icon(Icons.print, color: Colors.green),
                      onPressed: () => printCommande(commande),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Détails de la commande:",
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Client: ${commande.client.name}",
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              "Conditionnement: ${commande.conditionnement??'aucune conditionnement'}",
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Modèles:",
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: buildModelesTable(commande),
                      ),
                      if (commande.etat.toLowerCase() != "terminé")
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: ZoomIn(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey[800],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => markCommandeAsComplete(commande),
                                child: const Text(
                                  "Terminer l'étape",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildModelesTable(Commande commande) {
    final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);
    bool isCoupeState = commande.etat.toLowerCase() == "en coupe";

    List<DataColumn> columns = [
      DataColumn(
          label: Text("Modèle",
              style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("Taille",
              style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("Couleur",
              style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text("Quantité",
              style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
    ];

    if (isCoupeState) {
      columns.addAll([
        DataColumn(
            label: Text("Quantité Calculée",
                style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
        DataColumn(
            label: Text("Quantité Réelle",
                style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold))),
      ]);
    }

    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.blueGrey[100]),
      columns: columns,
      rows: commande.modeles.map((commandeModele) {
        final modele = modeleProvider.modeleMap[commandeModele.modele];
        final modeleNom = modele?.nom ?? "Non défini";

        double consommation = 0;
        if (modele != null) {
          final consommationItem = modele.consommation.firstWhere(
            (c) => c.taille == commandeModele.taille,
            orElse: () => Consommation(taille: "", quantity: 0),
          );
          consommation = consommationItem.quantity;
        }

        double quantiteCalculee = commandeModele.quantite * consommation;

        List<DataCell> cells = [
          DataCell(Text(modeleNom, style: TextStyle(color: Colors.blueGrey[600]))),
          DataCell(Text(commandeModele.taille, style: TextStyle(color: Colors.blueGrey[600]))),
          DataCell(Text(commandeModele.couleur, style: TextStyle(color: Colors.blueGrey[600]))),
          DataCell(
              Text(commandeModele.quantite.toString(), style: TextStyle(color: Colors.blueGrey[600]))),
        ];

        if (isCoupeState) {
          cells.addAll([
            DataCell(
                Text(quantiteCalculee.toStringAsFixed(4), style: TextStyle(color: Colors.blueGrey[600]))),
            DataCell(
              TextField(
                controller: TextEditingController(text: commandeModele.quantiteReelle.toString()),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Saisir quantité',
                  hintStyle: TextStyle(color: Colors.blueGrey[400]),
                ),
                onChanged: (value) async {
                  int newValue = int.tryParse(value) ?? 0;
                  commandeModele.quantiteReelle = newValue;

                  try {
                    await ApiService().updateQuantiteReelle(
                      commande.id!,
                      commandeModele.modele!,
                      newValue,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Quantité réelle mise à jour !"),
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur lors de la mise à jour : $e"),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
            ),
          ]);
        }

        return DataRow(cells: cells);
      }).toList(),
    );
  }
}