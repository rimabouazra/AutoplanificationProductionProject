import 'package:flutter/material.dart';
import 'AddCommandePage.dart'; // Import de la page d'ajout de commande

class CommandePage extends StatefulWidget {
  const CommandePage({Key? key}) : super(key: key);

  @override
  State<CommandePage> createState() => _CommandePageState();
}

class _CommandePageState extends State<CommandePage> {
  String selectedFilter = 'Tous';
  TextEditingController searchController = TextEditingController();

  List<Map<String, String>> commandes = [
    {"num": "123", "client": "AZERTY", "adresse": "...", "date": "1/1/2025", "prix": "12345", "status": "Pending"},
    {"num": "456", "client": "AZERTY", "adresse": "...", "date": "1/2/2025", "prix": "12345", "status": "Completed"},
    {"num": "890", "client": "QWERTY", "adresse": "...", "date": "1/3/2025", "prix": "12345", "status": "Working on"},
    {"num": "369", "client": "ABCDE", "adresse": "...", "date": "1/4/2025", "prix": "12345", "status": "Pending"},
  ];

  List<Map<String, String>> get filteredCommandes {
    return commandes.where((commande) {
      final matchesFilter = selectedFilter == 'Tous' || commande['status'] == selectedFilter;
      final matchesSearch = searchController.text.isEmpty || commande['client']!.toLowerCase().contains(searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void deleteCommande(String num) {
    setState(() {
      commandes.removeWhere((commande) => commande['num'] == num);
    });
  }

  void editCommande(Map<String, String> commande) {
    TextEditingController clientController = TextEditingController(text: commande['client']);
    TextEditingController prixController = TextEditingController(text: commande['prix']);

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
                controller: prixController,
                decoration: const InputDecoration(labelText: 'Prix'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  commande['client'] = clientController.text;
                  commande['prix'] = prixController.text;
                });
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
              leading: Text(commande['num']!),
              title: Text(commande['client']!),
              subtitle: Text("${commande['date']} - ${commande['prix']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    commande['status']!,
                    style: TextStyle(
                      color: commande['status'] == "Pending"
                          ? Colors.red
                          : commande['status'] == "Completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteCommande(commande['num']!),
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