import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/modeleProvider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../providers/CommandeProvider.dart';
import '../providers/PlanificationProvider .dart';
import '../providers/client_provider.dart';
import '../services/api_service.dart';
import 'PlanificationConfirmationDialog.dart';

class AddCommandePage extends StatefulWidget {
  @override
  _AddCommandePageState createState() => _AddCommandePageState();

}

class _AddCommandePageState extends State<AddCommandePage> {
  List<Map<String, dynamic>> modelesDisponibles = [];
  Map<String, dynamic>? selectedModele;
  String? selectedTaille;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController conditionnementController =
      TextEditingController();
  DateTime? selectedDate;
  bool isLoading = false;

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

  Widget _buildClientField(ClientProvider clientProvider) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return clientProvider.clients
            .map((c) => c.name)
            .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        setState(() {
          clientController.text = selection;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextFormField(
          controller: clientController,
          focusNode: focusNode,
          onFieldSubmitted: (value) async {
            if (!clientProvider.clients.any((c) => c.name.toLowerCase() == value.toLowerCase())) {
              final newClient = await clientProvider.addClient(value);
              setState(() {
                clientController.text = newClient.name;
              });
            }
          },
          decoration: InputDecoration(
            labelText: "Client",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            prefixIcon: Icon(Icons.person, color: Colors.lightBlue),
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
          prefixIcon: Icon(Icons.category, color: Colors.lightBlue),
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
          prefixIcon: Icon(Icons.straighten, color: Colors.lightBlue),
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
      TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.lightBlue),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.lightBlue),
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

  // Add this method to _AddCommandePageState
  Future<void> _showPlanificationConfirmation(String commandeId) async {
    final planifProvider = Provider.of<PlanificationProvider>(context, listen: false);

    // Get the preview of the planification
    final preview = await ApiService.getPlanificationPreview(commandeId);

    if (preview != null) {
      showDialog(
        context: context,
        builder: (context) => PlanificationConfirmationDialog(
          planification: preview,
          commandeId: commandeId,
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Erreur lors de la génération de la planification");
    }
  }

// Modify the _submitCommande method
  Future<void> _submitCommande() async {
    print("debut SubmitCommande in AddCommandePage");

    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        modeles.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez remplir tous les champs et ajouter au moins un modèle.");
      return;
    }

    setState(() => isLoading = true);
    final commandeProvider = Provider.of<CommandeProvider>(context, listen: false);

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

    final newClient = Client(id: '', name: clientController.text);
    Commande newCommande = Commande(
      client: newClient,
      modeles: modelesWithId,
      conditionnement: conditionnementController.text,
      delais: selectedDate ?? DateTime.now(),
      etat: "en attente",
    );

    if (newCommande.client.id.isEmpty) {
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      newCommande.client = await clientProvider.addClient(newCommande.client.name);
    }

    bool success = await commandeProvider.addCommande(newCommande);
    setState(() => isLoading = false);

    if (success) {
      Fluttertoast.showToast(msg: "Commande ajoutée avec succès !");

      // Get the latest commande ID (this might need adjustment based on your API)
      await commandeProvider.fetchCommandes();
      final latestCommandes = commandeProvider.commandes;

      if (latestCommandes.isNotEmpty) {
        final latestCommande = latestCommandes.last;
        await _showPlanificationConfirmation(latestCommande.id!);
      }
    } else {
      Fluttertoast.showToast(msg: "Erreur lors de l'ajout de la commande.");
    }
  }
  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.lightBlue.shade50,
        appBar: AppBar(
          title: const Text("Ajouter une Commande",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.lightBlue[400],
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
                      _buildClientField(clientProvider),
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
                            color: Colors.lightBlue),
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
                          ? const CircularProgressIndicator(color: Colors.lightBlue)
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
                                      backgroundColor: Colors.lightBlue.shade300),
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
        _buildTextField(quantiteController, "Quantité", Icons.numbers, isNumber: true),
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
