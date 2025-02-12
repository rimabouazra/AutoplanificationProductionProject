import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../models/commande.dart';
import '../providers/CommandeProvider.dart';


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
  bool isLoading = false;

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

  Future<void> _submitCommande() async {
    if (!_formKey.currentState!.validate() || selectedDate == null) {
      Fluttertoast.showToast(msg: "Veuillez remplir tous les champs.");
      return;
    }

    setState(() => isLoading = true);

    Commande newCommande = Commande(
      client: clientController.text,
      quantite: int.parse(quantiteController.text),
      couleur: couleurController.text,
      taille: tailleController.text,
      conditionnement: conditionnementController.text,
      delais: selectedDate!,
    );

    bool success = await Provider.of<CommandeProvider>(context, listen: false).addCommande(newCommande);
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
        body: SingleChildScrollView(  // Make the entire form scrollable
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
                      _buildTextField(quantiteController, "Quantité", isNumber: true),
                      _buildTextField(couleurController, "Couleur"),
                      _buildTextField(tailleController, "Taille"),
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
}
