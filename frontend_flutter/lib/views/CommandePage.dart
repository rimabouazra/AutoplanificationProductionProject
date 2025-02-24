import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/modeleProvider.dart';
import 'AddCommandePage.dart'; // Import de la page d'ajout de commande
import 'package:provider/provider.dart';
import '../providers/CommandeProvider.dart';
import '../models/commande.dart';
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
    if (status == "En attente") {
      return Colors.red;
    } else if (status == "Terminé") {
      return Colors.green;
    } else if ([
      "En coupe",
      "En moulage",
      "En presse",
      "En contrôle",
      "Emballage"
    ].contains(status)) {
      return Colors.orange; // Les processus en cours
    }
    return Colors.grey; // Par défaut pour tout autre état
  }


  List<Commande> get filteredCommandes {
    final commandes = Provider.of<CommandeProvider>(context).commandes;
    return commandes.where((commande) {
      final matchesFilter = selectedFilter == 'Tous' || commande.etat == selectedFilter;
      final matchesSearch = searchController.text.isEmpty || commande.client.toLowerCase().contains(searchController.text.toLowerCase());
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
              onPressed: () {
                // Annuler la suppression
                Navigator.pop(context);
              },
              child: const Text('Non'),
            ),
            TextButton(
              onPressed: () {
                // Supprimer la commande via le provider
                Provider.of<CommandeProvider>(context, listen: false).deleteCommande(id);
                Navigator.pop(context);
              },
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );
  }


  Future<void> editCommande(Commande commande) async {
    TextEditingController clientController = TextEditingController(text: commande.client);

    List<TextEditingController> nomModeleControllers = [];
    List<TextEditingController> tailleControllers = [];
    List<TextEditingController> couleurControllers = [];
    List<TextEditingController> quantiteControllers = [];

    List<CommandeModele> updatedModeles = List.from(commande.modeles);

    // Assurer que chaque modèle a un nom valide
    for (var modele in updatedModeles) {
      if (modele.nomModele.isEmpty && modele.modele != null) {
        print("Recherche du nom pour l'ID du modèle : ${modele.modele}");
        String? fetchedNom = await Provider.of<CommandeProvider>(context, listen: false).getModeleNom(modele.modele!);
        modele.nomModele = fetchedNom ?? "Modèle inconnu";
      }
    }

    // Remplissage des contrôleurs avec les valeurs actuelles
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

    // Affichage du formulaire de modification
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier Commande'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clientController,
                      decoration: const InputDecoration(labelText: 'Client'),
                      enabled: false,
                    ),
                    ...List.generate(updatedModeles.length, (index) {
                      return Column(
                        children: [
                          TextField(
                            controller: nomModeleControllers[index],
                            decoration: const InputDecoration(labelText: 'Nom du modèle'),
                          ),
                          TextField(
                            controller: tailleControllers[index],
                            decoration: const InputDecoration(labelText: 'Taille'),
                          ),
                          TextField(
                            controller: couleurControllers[index],
                            decoration: const InputDecoration(labelText: 'Couleur'),
                          ),
                          TextField(
                            controller: quantiteControllers[index],
                            decoration: const InputDecoration(labelText: 'Quantité'),
                            keyboardType: TextInputType.number,
                          ),
                          const Divider(),
                        ],
                      );
                    }),
                    TextButton(
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
                      child: const Text('Ajouter un modèle'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    for (int i = 0; i < updatedModeles.length; i++) {
                      // Vérifier que l'ID du modèle est bien défini
                      if (updatedModeles[i].modele == null) {
                        String? modeleId = await Provider.of<CommandeProvider>(context, listen: false)
                            .getModeleId(updatedModeles[i].nomModele);
                        updatedModeles[i].modele = modeleId;
                      }

                      updatedModeles[i].taille = tailleControllers[i].text;
                      updatedModeles[i].couleur = couleurControllers[i].text;
                      updatedModeles[i].quantite = int.tryParse(quantiteControllers[i].text) ?? 1;
                    }

                    // Envoi de la mise à jour au backend
                    bool success = await Provider.of<CommandeProvider>(context, listen: false)
                        .updateCommande(commande.id!, updatedModeles);

                    if (success) {
                      Commande updatedCommande = Provider.of<CommandeProvider>(context, listen: false)
                          .commandes
                          .firstWhere((cmd) => cmd.id == commande.id!);

                      updatedCommande.modeles = updatedModeles;
                      Provider.of<CommandeProvider>(context, listen: false).notifyListeners();

                      Navigator.pop(context);
                    } else {
                      print("Erreur lors de la mise à jour de la commande.");
                    }
                  },
                  child: const Text('Enregistrer'),
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

  // Fonction de navigation vers une page vide



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
                  buildFilters(), // Ajout des filtres ici
                  const SizedBox(height: 10),
                  buildCommandesTable(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddCommande,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }



  Widget buildSearchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 150,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: "Rechercher",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget buildFilters() {
    return Row(
      children: filters.map((filter) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ChoiceChip(
            label: Text(filter),
            selected: selectedFilter == filter,
            onSelected: (bool selected) {
              setState(() {
                selectedFilter = filter;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget buildCommandesTable() {
    return Expanded(
      child: ListView(
        children: filteredCommandes.map((commande) {
          int totalQuantite = commande.modeles.fold(0, (sum, m) => sum + m.quantite);
          return Card(
            elevation: 3,
            child: ExpansionTile(
              leading: Text(commande.id ?? "N/A"), // TO DO : change to commande ref not ID
              title: Text(commande.client, style: const TextStyle(fontWeight: FontWeight.bold)),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    commande.etat,
                    style: TextStyle(
                      color: getStatusColor(commande.etat),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => editCommande(commande),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteCommande(commande.id!),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Détails de la commande:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Client: ${commande.client}"),
                      Text("Conditionnement: ${commande.conditionnement}"),
                      Text("Salle affectée: ${commande.salleAffectee ?? 'Non assignée'}"),
                      Text("Machines affectées: ${commande.machinesAffectees?.join(', ') ?? 'Aucune'}"),
                      const SizedBox(height: 10),
                      const Text("Modèles:", style: TextStyle(fontWeight: FontWeight.bold)),
                      // Liste des modèles
                      Column(
                        children: commande.modeles.map((commandeModele) {
                          // Utiliser modeleMap pour obtenir le nom du modèle
                          final modeleNom = Provider.of<ModeleProvider>(context)
                              .modeleMap[commandeModele.modele]?.nom ?? "Non défini";

                          return ListTile(
                            leading: const Icon(Icons.label, color: Colors.purple),
                            title: Text("Modèle: $modeleNom"),  // Affiche le nom du modèle
                            subtitle: Text("Taille: ${commandeModele.taille}, Couleur: ${commandeModele.couleur}, Quantité: ${commandeModele.quantite}"),
                          );
                        }).toList(),
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