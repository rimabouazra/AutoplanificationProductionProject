import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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


  void editCommande(Commande commande) {
    TextEditingController clientController = TextEditingController(text: commande.client);

    // Création des contrôleurs pour les champs modifiables (taille, couleur, quantité)
    List<TextEditingController> tailleControllers = [];
    List<TextEditingController> couleurControllers = [];
    List<TextEditingController> quantiteControllers = [];
    List<CommandeModele> updatedModeles = List.from(commande.modeles); // Conserver les modèles existants

    // Initialiser les contrôleurs pour les modèles existants
    for (var modele in commande.modeles) {
      tailleControllers.add(TextEditingController(text: modele.taille));
      couleurControllers.add(TextEditingController(text: modele.couleur));
      quantiteControllers.add(TextEditingController(text: modele.quantite.toString()));
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier Commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientController,
                decoration: const InputDecoration(labelText: 'Client'),
                enabled: false, // Désactiver le champ client si non modifiable
              ),
              ...List.generate(updatedModeles.length, (index) {
                return Column(
                  children: [
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
                  ],
                );
              }),
              TextButton(
                onPressed: () {
                  // Ajouter un nouveau modèle à la commande
                  setState(() {
                    updatedModeles.add(CommandeModele(
                      modele: "Nouveau Modèle", // Ajout d'un modèle vide
                      taille: "M", // Valeur par défaut
                      couleur: "Blanc", // Valeur par défaut
                      quantite: 1, // Quantité par défaut
                    ));
                    tailleControllers.add(TextEditingController(text: "M"));
                    couleurControllers.add(TextEditingController(text: "Blanc"));
                    quantiteControllers.add(TextEditingController(text: "1"));
                  });
                },
                child: const Text('Ajouter un modèle'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Mettre à jour les modèles de la commande
                for (int i = 0; i < updatedModeles.length; i++) {
                  updatedModeles[i].taille = tailleControllers[i].text;
                  updatedModeles[i].couleur = couleurControllers[i].text;
                  updatedModeles[i].quantite = int.parse(quantiteControllers[i].text);
                }

                // Mettre à jour la commande via le provider
                final updatedCommande = Commande(
                  id: commande.id,
                  client: commande.client, // Le client reste inchangé
                  modeles: updatedModeles,
                  conditionnement: commande.conditionnement,
                  delais: commande.delais,
                  etat: commande.etat,
                );

                Provider.of<CommandeProvider>(context, listen: false).updateCommande(updatedCommande);
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
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
            child: ListTile(
              leading: Text(commande.id ?? "N/A"), // Afficher l'ID de la commande
              title: Text(commande.client),
              subtitle: Text(
                commande.delais != null
                    ? "${DateFormat('dd/MM/yyyy').format(commande.delais!)} - $totalQuantite unités"
                    : "Date non définie - $totalQuantite unités",
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    commande.etat, // Remplace status par etat
                    style: TextStyle(
                      color: getStatusColor(commande.etat),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteCommande(commande.id!),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => editCommande(commande),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }




}