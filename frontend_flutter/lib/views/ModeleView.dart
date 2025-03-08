import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/modele.dart';
import '../providers/modeleProvider.dart';
import '../widgets/topNavbar.dart';

class ModeleView extends StatefulWidget {
  @override
  _ModeleViewState createState() => _ModeleViewState();
}

class _ModeleViewState extends State<ModeleView> {
  String _searchQuery = "";
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    Provider.of<ModeleProvider>(context, listen: false).fetchModeles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher un modèle',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isAscending = !_isAscending;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<ModeleProvider>(
              builder: (context, modeleProvider, child) {
                List<Modele> filteredModeles = modeleProvider.modeles
                    .where((modele) => modele.nom.toLowerCase().contains(_searchQuery))
                    .toList();

                filteredModeles.sort((a, b) => _isAscending
                    ? a.nom.compareTo(b.nom)
                    : b.nom.compareTo(a.nom));

                if (filteredModeles.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun modèle trouvé',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: filteredModeles.length,
                  itemBuilder: (context, index) {
                    final modele = filteredModeles[index];
                    return Card(
                      elevation: 6,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        title: Text(
                          modele.nom,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        subtitle: Text(
                          'Tailles: ${modele.tailles.join(', ')}',
                          style: TextStyle(color: Colors.black54),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                        onTap: () {

                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
