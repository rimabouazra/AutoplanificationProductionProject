import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/modeleProvider.dart';
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
  final TextEditingController conditionnementController =
      TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;
  //TO DO : make the client auto complete and the modele should be dropdown

  List<CommandeModele> modeles = [];
  final TextEditingController modeleController = TextEditingController();
  final TextEditingController couleurController = TextEditingController();
  final TextEditingController tailleController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  List<String> clients = [];
  List<String> modele = [];
  List<String> tailles = [];

  @override
void initState() {
  super.initState();
  final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);
  final modeleProvider = Provider.of<ModeleProvider>(context, listen: false);

  commandeProvider.fetchCommandes().then((_) {
    setState(() {
      clients = commandeProvider.getClients();
    });
  });

  modeleProvider.fetchModeles().then((_) {
  setState(() {
    modele = modeleProvider.modeles.map((m) => m.nom).toList(); // Stocke les noms des modèles en `String`
  });
});
}

Widget _buildClientField() {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return const Iterable<String>.empty();
      }
      return clients.where((client) => client.toLowerCase().contains(textEditingValue.text.toLowerCase()));
    },
    onSelected: (String selection) {
      setState(() {
        clientController.text = selection;
      });
    },
    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: "Client",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          prefixIcon: Icon(Icons.person, color: Colors.teal),
        ),
      );
    },
  );
}

  Widget _buildModeleField() {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty) {
        return const Iterable<String>.empty();
      }
      return modele.where((modele) => modele.toLowerCase().contains(textEditingValue.text.toLowerCase()));
    },
    onSelected: (String selection) {
      setState(() {
        modeleController.text = selection;
        tailles = Provider.of<ModeleProvider>(context, listen: false).getTaillesByModele(selection);
      });
    },
    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: "Nom du Modèle",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          prefixIcon: Icon(Icons.category, color: Colors.teal),
        ),
      );
    },
  );
}
Widget _buildTailleField() {
  return Autocomplete<String>(
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isEmpty || tailles.isEmpty) {
        return const Iterable<String>.empty();
      }
      return tailles.where((taille) => taille.toLowerCase().contains(textEditingValue.text.toLowerCase()));
    },
    onSelected: (String selection) {
      setState(() {
        tailleController.text = selection;
      });
    },
    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: "Taille",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          prefixIcon: Icon(Icons.straighten, color: Colors.teal),
        ),
      );
    },
  );
}

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

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.teal),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (!isOptional && value!.isEmpty) return "Champ requis";
          if (isNumber && int.tryParse(value!) == null) {
            return "Entrer un nombre valide";
          }
          if (isNumber && int.parse(value!) <= 0) {
            return "La quantité doit être positive";
          }
          return null;
        },
      ),
    );
  }

  void _addModele() {
    if (modeleController.text.isEmpty ||
        couleurController.text.isEmpty ||
        tailleController.text.isEmpty ||
        quantiteController.text.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez remplir tous les champs pour le modèle.");
      return;
    }

    setState(() {
      modeles.add(CommandeModele(
        nomModele: modeleController.text,
        taille: tailleController.text,
        couleur: couleurController.text,
        quantite: int.parse(quantiteController.text),
      ));
    });
  }

  Future<void> _submitCommande() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        modeles.isEmpty) {
      Fluttertoast.showToast(
          msg:
              "Veuillez remplir tous les champs et ajouter au moins un modèle.");
      return;
    }

    setState(() => isLoading = true);
    final commandeProvider =
        Provider.of<CommandeProvider>(context, listen: false);

    List<CommandeModele> modelesWithId = [];

    for (var modele in modeles) {
      String? modeleId = await commandeProvider.getModeleId(modele.nomModele);
      if (modeleId != null) {
        modelesWithId.add(CommandeModele(
          modele: modeleId,
          nomModele: modele.nomModele,
          taille: modele.taille,
          couleur: modele.couleur,
          quantite: modele.quantite,
        ));
      } else {
        Fluttertoast.showToast(
            msg: "Erreur : Modèle '${modele.nomModele}' non trouvé.");
        setState(() => isLoading = false);
        return;
      }
    }

    Commande newCommande = Commande(
      client: clientController.text,
      modeles: modelesWithId,
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
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          title: const Text("Ajouter une Commande",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.teal,
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 5,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
_buildClientField(),
                      _buildTextField(conditionnementController,
                          "Conditionnement", Icons.inventory,
                          isOptional: true),
                      const SizedBox(height: 10),
                      ListTile(
                        tileColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        title: Text(
                          selectedDate == null
                              ? "Sélectionner une date de livraison"
                              : "Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate!)}",
                        ),
                        trailing: const Icon(Icons.calendar_today,
                            color: Colors.teal),
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 20),
                      const Text("Associer un modèle",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildModeleForm(),
                      const SizedBox(height: 20),
                      ...modeles.map((modele) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: ListTile(
                              title: Text(
                                  "${modele.nomModele} - Taille : ${modele.taille} - Quantité : ${modele.quantite}"),
                              subtitle: Text("Couleur : ${modele.couleur}"),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    setState(() => modeles.remove(modele)),
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.teal)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent),
                                  child: const Text("Annuler"),
                                ),
                                ElevatedButton(
                                  onPressed: _submitCommande,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade300),
                                  child: const Text("Ajouter"),
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
        _buildModeleField(),
_buildTailleField(),
        _buildTextField(quantiteController, "Quantité", Icons.numbers,
            isNumber: true),
        _buildTextField(couleurController, "Couleur", Icons.colorize),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _addModele,
          icon: const Icon(Icons.add),
          label: const Text("Ajouter Modèle"),
        ),
      ],
    );
  }
}
