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
    // Implémentez la suppression via le provider
    Provider.of<CommandeProvider>(context, listen: false).deleteCommande(id);
  }

  void editCommande(Commande commande) {
    TextEditingController clientController = TextEditingController(text: commande.client);

    // Calculer la somme des quantités à partir de la liste des modèles
    int totalQuantite = commande.modeles.fold(0, (sum, modele) => sum + modele.quantite);

    TextEditingController quantiteController = TextEditingController(text: totalQuantite.toString());

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
              ),
              TextField(
                controller: quantiteController,
                decoration: const InputDecoration(labelText: 'Quantité totale'),
                keyboardType: TextInputType.number,
                enabled: false, // Empêche la modification directe
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Mettre à jour la commande via le provider
                final updatedCommande = Commande(
                  id: commande.id,
                  client: clientController.text,
                  modeles: commande.modeles, // On garde les modèles existants
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
                  buildPagination(),
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

  Widget buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(onPressed: () {}, child: const Text("< AVANT")),
        const SizedBox(width: 10),
        ...List.generate(3, (index) => TextButton(onPressed: () {}, child: Text("0${index + 1}"))),
        const SizedBox(width: 10),
        TextButton(onPressed: () {}, child: const Text("APRES >")),
      ],
    );
  }
}