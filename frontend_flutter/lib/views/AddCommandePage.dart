import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/commande.dart';
import '../providers/CommandeProvider.dart';

class AddCommandePage extends StatefulWidget {
  @override
  _AddCommandePageState createState() => _AddCommandePageState();
}

class _AddCommandePageState extends State<AddCommandePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController conditionnementController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

  List<CommandeModele> modeles = [];
  String? selectedModele;
  final TextEditingController modeleController = TextEditingController();
  final TextEditingController couleurController = TextEditingController();
  final TextEditingController tailleController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF004D40)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Color(0xFFE0F2F1),
        ),
        validator: (value) {
          if (value!.isEmpty) return "Champ requis";
          if (isNumber && int.tryParse(value) == null) return "Entrer un nombre valide";
          if (isNumber && int.parse(value) <= 0) return "La quantité doit être positive";
          return null;
        },
      ),
    );
  }

  void _addModele() {
    if (modeleController.text.isEmpty || couleurController.text.isEmpty || tailleController.text.isEmpty || quantiteController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Veuillez remplir tous les champs pour le modèle.");
      return;
    }

    setState(() {
      modeles.add(CommandeModele(
        nomModele: modeleController.text,
        taille: tailleController.text,
        couleur: couleurController.text,
        quantite: int.parse(quantiteController.text),
      ));
      // Debug: Print the list of models after adding
      print("Modeles ajoutés: ${modeles.map((m) => m.toJson()).toList()}");
      // Ne vide pas les champs après avoir ajouté le modèle
    });
  }

  Future<void> _submitCommande() async {
    if (selectedModele != null && couleurController.text.isNotEmpty && tailleController.text.isNotEmpty && quantiteController.text.isNotEmpty) {
      _addModele(); // Automatically save the last model
    }

    if (!_formKey.currentState!.validate() || selectedDate == null || modeles.isEmpty) {
      Fluttertoast.showToast(msg: "Veuillez remplir tous les champs et ajouter au moins un modèle.");
      return;
    }

    setState(() => isLoading = true);

    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);

    List<CommandeModele> modelesWithId = []; // List of CommandeModele objects

    for (var modele in modeles) {
      String? modeleId = await commandeProvider.getModeleId(modele.nomModele); // Call Provider method to get the ID
      if (modeleId != null) {
        modelesWithId.add(CommandeModele(
          modele: modeleId,  // Pass the ID of the modele instead of the name
          nomModele: modele.nomModele,  // Keep the model name
          taille: modele.taille,
          couleur: modele.couleur,
          quantite: modele.quantite,
        ));
      } else {
        Fluttertoast.showToast(msg: "Erreur : Modèle '${modele.nomModele}' non trouvé.");
        setState(() => isLoading = false);
        return;
      }
    }

    Commande newCommande = Commande(
      client: clientController.text,
      modeles: modelesWithId,  // Now passing List<CommandeModele>
      conditionnement: conditionnementController.text,
      delais: selectedDate ?? DateTime.now(),
      etat: "en attente",
    );

    bool success = await commandeProvider.addCommande(newCommande);
    setState(() => isLoading = false);

    if (success) {
      Fluttertoast.showToast(msg: "Commande ajoutée avec succès !");
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: "Erreur lors de l'ajout de la commande.");
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Color(0xFFECEFFF1),
        appBar: AppBar(
          title: Text("Ajouter une Commande", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Color(0xFF4DB6AC),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(clientController, "Client"),
                      _buildTextField(conditionnementController, "Conditionnement"),
                      SizedBox(height: 10),
                      ListTile(
                        title: Text(selectedDate == null
                            ? "Sélectionner une date de livraison"
                            : "Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate!)}"),
                        trailing: Icon(Icons.calendar_today, color: Color(0xFF009688)),
                        onTap: () => _selectDate(context),
                      ),
                      SizedBox(height: 20),
                      Text("Ajouter un modèle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildModeleForm(),
                      SizedBox(height: 20),
                      ...modeles.map((modele) => ListTile(
                        title: Text("${modele.modele} - taille : ${modele.taille} - couleur : ${modele.couleur} - ${modele.quantite} unités"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              modeles.remove(modele);
                            });
                          },
                        ),
                      )).toList(),
                      SizedBox(height: 20),
                      isLoading
                          ? CircularProgressIndicator(color: Color(0xFF4DB6AC))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Annuler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: _submitCommande,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF26A69A),
                              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text("Ajouter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeleForm() {
    return Column(
      children: [
        _buildTextField(modeleController, "Nom du Modèle"),
        SizedBox(height: 10),
        _buildTextField(couleurController, "Couleur"),
        _buildTextField(tailleController, "Taille"),
        _buildTextField(quantiteController, "Quantité", isNumber: true),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addModele,
          child: Text("Ajouter Modèle"),
        ),
      ],
    );
  }
}
