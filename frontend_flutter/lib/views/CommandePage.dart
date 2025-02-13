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
    // Récupérer les commandes lors de l'initialisation de la page
    Provider.of<CommandeProvider>(context, listen: false).fetchCommandes();
  }

  List<Commande> get filteredCommandes {
    final commandes = Provider.of<CommandeProvider>(context).commandes;
    return commandes.where((commande) {
      final matchesFilter = selectedFilter == 'Tous' || commande.status == selectedFilter;
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
    TextEditingController quantiteController = TextEditingController(text: commande.quantite.toString());

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
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
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
                  quantite: int.parse(quantiteController.text),
                  couleur: commande.couleur,
                  taille: commande.taille,
                  conditionnement: commande.conditionnement,
                  delais: commande.delais,
                  status: commande.status,
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
  void navigateTo(BuildContext context, String pageName) {
    Widget page;
    switch (pageName) {
      case 'tableau de board':
        page = Scaffold(
          appBar: AppBar(title: Text('Tableau de bord')),
          body: Center(child: Text('Page Tableau de bord en cours de développement')),
        );
        break;
      case 'planification':
        page = Scaffold(
          appBar: AppBar(title: Text('Planification')),
          body: Center(child: Text('Page Planification en cours de développement')),
        );
        break;
      case 'Utilisateurs':
        page = Scaffold(
          appBar: AppBar(title: Text('Utilisateurs')),
          body: Center(child: Text('Page Utilisateurs en cours de développement')),
        );
        break;
      case 'Stock':
        page = Scaffold(
          appBar: AppBar(title: Text('Stock')),
          body: Center(child: Text('Page Stock en cours de développement')),
        );
        break;
      case 'Commandes':
        page = Scaffold(
          appBar: AppBar(title: Text('Commandes')),
          body: Center(child: Text('Page Commandes en cours de développement')),
        );
        break;
      case 'Salles':
        page = Scaffold(
          appBar: AppBar(title: Text('Salles')),
          body: Center(child: Text('Page Salles en cours de développement')),
        );
        break;
      default:
        page = Scaffold(
          appBar: AppBar(title: Text('Page inconnue')),
          body: Center(child: Text('Page inconnue')),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          buildSidebar(),
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

  Widget buildSidebar() {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          buildSidebarItem("tableau de board"),
          buildSidebarItem("planification"),
          buildSidebarItem("Utilisateurs"),
          buildSidebarItem("Stock"),
          buildSidebarItem("Commandes"),
          buildSidebarItem("Salles"),
        ],
      ),
    );
  }

  Widget buildSidebarItem(String title) {
    return ListTile(
      title: Text(title),
      onTap: () => navigateTo(context, title), // Appel de la fonction de navigation
    );
  }

  Widget buildSearchBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 200,
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
    List<String> filters = ["Tous", "Pending", "Working on", "Completed"];
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
          return Card(
            child: ListTile(
              leading: Text(commande.id ?? "N/A"), // Afficher l'ID de la commande
              title: Text(commande.client),
              subtitle: Text("${DateFormat('dd/MM/yyyy').format(commande.delais)} - ${commande.quantite} unités"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    commande.status,
                    style: TextStyle(
                      color: commande.status == "Pending"
                          ? Colors.red
                          : commande.status == "Completed"
                          ? Colors.green
                          : Colors.orange,
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