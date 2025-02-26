
import 'package:flutter/material.dart';
import '../providers/modeleProvider.dart';
import 'AddCommandePage.dart';
import 'package:provider/provider.dart';
import '../providers/CommandeProvider.dart';
import '../models/commande.dart';
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
        return Colors.red;
      case "Terminé":
        return Colors.green;
      case "En coupe":
      case "En moulage":
      case "En presse":
      case "En contrôle":
      case "Emballage":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }


  List<Commande> get filteredCommandes {
    final commandes = Provider.of<CommandeProvider>(context).commandes;

    return commandes.where((commande) {
      final etatCommande = commande.etat.trim().toLowerCase(); // Normalisation
      final etatFiltre = selectedFilter.trim().toLowerCase();

      final matchesFilter = etatFiltre == 'tous' || etatCommande == etatFiltre;
      final matchesSearch = searchController.text.isEmpty ||
          commande.client.toLowerCase().contains(searchController.text.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();
  }



  void deleteCommande(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: const Text('Voulez-vous vraiment supprimer cette commande ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<CommandeProvider>(context, listen: false).deleteCommande(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> printCommande(Commande commande) async {
    final pdf = pw.Document();
    for (var modele in commande.modeles) {
      if (modele.nomModele.isEmpty && modele.modele != null) {
        // Fetch the model name using the modele ID
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
              pw.Text('Commande Details', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Client: ${commande.client}'),
              pw.Text('Conditionnement: ${commande.conditionnement}'),
              pw.Text('Salle Affectée: ${commande.salleAffectee ?? 'Non assignée'}'),
              pw.Text('Machines Affectées: ${commande.machinesAffectees?.join(', ') ?? 'Aucune'}'),
              pw.SizedBox(height: 20),
              pw.Text('Modèles:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
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
                    ],
                  ),
                  ...commande.modeles.map((modele) {
                    return pw.TableRow(
                      children: [
                        pw.Text(modele.nomModele),
                        pw.Text(modele.taille),
                        pw.Text(modele.couleur),
                        pw.Text(modele.quantite.toString()),
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
    TextEditingController clientController = TextEditingController(text: commande.client);

    List<TextEditingController> nomModeleControllers = [];
    List<TextEditingController> tailleControllers = [];
    List<TextEditingController> couleurControllers = [];
    List<TextEditingController> quantiteControllers = [];

    List<CommandeModele> updatedModeles = List.from(commande.modeles);

    for (var modele in updatedModeles) {
      if (modele.nomModele.isEmpty && modele.modele != null) {
        print("Recherche du nom pour l'ID du modèle : ${modele.modele}");
        String? fetchedNom = await Provider.of<CommandeProvider>(context, listen: false).getModeleNom(modele.modele!);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('Modifier Commande', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: clientController,
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          border: OutlineInputBorder(),
                        ),
                        enabled: false,
                      ),
                      const SizedBox(height: 15),
                      ...List.generate(updatedModeles.length, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nomModeleControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Nom du modèle',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool confirmDelete = await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirmer la suppression'),
                                        content: const Text('Êtes-vous sûr de vouloir supprimer ce modèle ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ) ?? false;

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
                                )
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
                                    decoration: const InputDecoration(
                                      labelText: 'Taille',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: couleurControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Couleur',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    controller: quantiteControllers[index],
                                    decoration: const InputDecoration(
                                      labelText: 'Quantité',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(thickness: 1, height: 20),
                          ],
                        );
                      }),
                      Align(
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
                          label: const Text('Ajouter un modèle'),
                        ),
                      ),
                      if (isSavingModeles)
                        const Center(child: CircularProgressIndicator()),
                      if (!isSavingModeles)
                        Align(
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
                                updatedModeles[i].quantite = int.tryParse(quantiteControllers[i].text) ?? 1;
                              }

                              setState(() {
                                isSavingModeles = false;
                              });
                            },
                            child: const Text('Enregistrer Modèles'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool hasError = false;
                    List<Future<void>> futures = [];
                    setState(() {
                      isLoading = true;
                    });

                    // Valider et mettre à jour les modèles
                    for (int i = 0; i < updatedModeles.length; i++) {
                      futures.add(() async {
                        if (updatedModeles[i].nomModele.isEmpty && updatedModeles[i].modele != null) {
                          String? modeleNom = await Provider.of<CommandeProvider>(context, listen: false).getModeleNom(updatedModeles[i].modele!);
                          if (modeleNom != null) {
                            updatedModeles[i].nomModele = modeleNom;
                          } else {
                            hasError = true;
                          }
                        }

                        if ((updatedModeles[i].modele == null || updatedModeles[i].modele!.isEmpty) &&
                            updatedModeles[i].nomModele.isNotEmpty) {
                          String? modeleId = await Provider.of<CommandeProvider>(context, listen: false).getModeleId(updatedModeles[i].nomModele);
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
                        const SnackBar(content: Text("Erreur dans les modèles.")),
                      );
                      return;
                    }

                    bool success = await Provider.of<CommandeProvider>(context, listen: false).updateCommande(commande.id!, updatedModeles);

                    setState(() {
                      isLoading = false;
                    });

                    if (success) {
                      print("Commande mise à jour !");
                      await Provider.of<CommandeProvider>(context, listen: false).fetchCommandes();
                      Provider.of<CommandeProvider>(context, listen: false).notifyListeners();
                      Navigator.pop(context);
                    } else {
                      print("Erreur lors de la mise à jour de la commande.");
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Erreur lors de la mise à jour de la commande.")),
                      );
                    }
                  },
                  child: const Text('Enregistrer Commande'),
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
      MaterialPageRoute(builder: (context) => AddCommandePage()),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSearchBar(),
                  buildFilters(),
                  const SizedBox(height: 10),
                  buildCommandesTable(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FloatingActionButton(
          onPressed: navigateToAddCommande,
          backgroundColor: Colors.purple[200],
          child: const Icon(Icons.add),
        ),
      ),


    );
  }



  Widget buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: "Rechercher une commande",
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
              selectedColor: Colors.purple[300],
              onSelected: (bool selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              labelStyle: TextStyle(
                color: selectedFilter == filter ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  Widget buildCommandesTable() {
    return Expanded(
      child: ListView(
        children: filteredCommandes.map((commande) {
          int totalQuantite = commande.modeles.fold(0, (sum, m) => sum + m.quantite);

          return Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ExpansionTile(

              title: Text(
                commande.client,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getStatusColor(commande.etat).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      commande.etat,
                      style: TextStyle(
                        color: getStatusColor(commande.etat),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue[300]),
                    onPressed: () => editCommande(commande),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[700]),
                    onPressed: () => deleteCommande(commande.id!),
                  ),
                  IconButton(
                    icon: Icon(Icons.print, color: Colors.green[700]),
                    onPressed: () => printCommande(commande),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text(" Client: ${commande.client}")),
                          Expanded(child: Text(" Conditionnement: ${commande.conditionnement}")),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(" Salle affectée: ${commande.salleAffectee ?? 'Non assignée'}"),
                          ),
                          Expanded(
                            child: Text(" Machines affectées: ${commande.machinesAffectees?.join(', ') ?? 'Aucune'}"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        " Modèles:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                          columns: const [
                            DataColumn(label: Text("Modèle")),
                            DataColumn(label: Text("Taille")),
                            DataColumn(label: Text("Couleur")),
                            DataColumn(label: Text("Quantité")),
                          ],
                          rows: commande.modeles.map((commandeModele) {
                            final modeleNom = Provider.of<ModeleProvider>(context, listen: false)
                                .modeleMap[commandeModele.modele]
                                ?.nom ??
                                "Non défini";

                            return DataRow(
                              cells: [
                                DataCell(Text(modeleNom)),
                                DataCell(Text(commandeModele.taille)),
                                DataCell(Text(commandeModele.couleur)),
                                DataCell(Text(commandeModele.quantite.toString())),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }






}