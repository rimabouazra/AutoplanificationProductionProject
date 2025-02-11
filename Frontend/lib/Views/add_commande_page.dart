import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/commande.dart';
import '../providers/commande_provider.dart';

class AddCommandePage extends StatefulWidget {
  @override
  _AddCommandePageState createState() => _AddCommandePageState();
}

class _AddCommandePageState extends State<AddCommandePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController couleurController = TextEditingController();
  final TextEditingController tailleController = TextEditingController();
  final TextEditingController conditionnementController = TextEditingController();
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitCommande() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      Fluttertoast.showToast(msg: "Veuillez remplir tous les champs.");
      return;
    }

    // Créer une commande avec les valeurs du formulaire
    Commande nouvelleCommande = Commande(
      client: clientController.text,
      quantite: int.parse(quantiteController.text),
      couleur: couleurController.text,
      taille: tailleController.text,
      conditionnement: conditionnementController.text,
      delais: selectedDate!,
    );

    // Envoyer la commande via le provider
    bool success = await CommandeProvider.addCommande(nouvelleCommande);
    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une Commande")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: clientController,
                decoration: InputDecoration(labelText: "Client"),
                validator: (value) => value!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: quantiteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantité"),
                validator: (value) => value!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: couleurController,
                decoration: InputDecoration(labelText: "Couleur"),
                validator: (value) => value!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: tailleController,
                decoration: InputDecoration(labelText: "Taille"),
                validator: (value) => value!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: conditionnementController,
                decoration: InputDecoration(labelText: "Conditionnement"),
                validator: (value) => value!.isEmpty ? "Champ requis" : null,
              ),
              ListTile(
                title: Text(selectedDate == null
                    ? "Sélectionner une date de livraison"
                    : "Date: ${selectedDate!.toLocal()}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitCommande,
                child: Text("Ajouter Commande"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
