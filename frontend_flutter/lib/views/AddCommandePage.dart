import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/providers/PlanificationProvider%20.dart';
import 'package:frontend/providers/modeleProvider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/WaitingPlanification.dart';
import '../models/client.dart';
import '../models/commande.dart';
import '../models/planification.dart';
import '../providers/CommandeProvider.dart';
import '../providers/client_provider.dart';
import '../services/api_service.dart';
import 'PlanificationConfirmationDialog.dart';
import 'admin_home_page.dart';

class AddCommandePage extends StatefulWidget {
  const AddCommandePage({super.key});

  @override
  _AddCommandePageState createState() => _AddCommandePageState();
}

class _AddCommandePageState extends State<AddCommandePage> {
  List<Map<String, dynamic>> modelesDisponibles = [];
  Map<String, dynamic>? selectedModele;
  String? selectedTaille;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController conditionnementController = TextEditingController();
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
        modele = modeleProvider.modeles.map((m) => m.nom).toList();
      });
    });
  }

  Widget _buildClientField(ClientProvider clientProvider) {
    return FadeInUp(
      child: Autocomplete<String>(
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
              prefixIcon: const Icon(Icons.person, color: Colors.blueGrey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeleField() {
    return FadeInUp(
      child: Autocomplete<String>(
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
              prefixIcon: const Icon(Icons.category, color: Colors.blueGrey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTailleField() {
    return FadeInUp(
      child: Autocomplete<String>(
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
              prefixIcon: const Icon(Icons.straighten, color: Colors.blueGrey),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.blueGrey,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueGrey[800],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon, {bool isNumber = false, bool isOptional = false}) {
    return FadeInUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueGrey),
            labelText: label,
            labelStyle: const TextStyle(color: Colors.blueGrey),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
      ),
    );
  }

void _addModele() {
  if (modeleController.text.isEmpty ||
      couleurController.text.isEmpty ||
      tailleController.text.isEmpty ||
      quantiteController.text.isEmpty) {
    Fluttertoast.showToast(
        msg: "Veuillez remplir tous les champs pour le modèle.",
        backgroundColor: Colors.redAccent,
        textColor: Colors.white);
    return;
  }

  setState(() {
    modeles.add(CommandeModele(
      nomModele: modeleController.text,
      taille: tailleController.text,
      couleur: couleurController.text,
      quantite: int.parse(quantiteController.text),
    ));
    modeleController.clear();
    tailleController.clear();
    //couleurController.clear();
    //quantiteController.clear();
  });
}

  Future _showPlanificationConfirmation(String commandeId) async{
    print('Showing planification confirmation for commande: $commandeId');

    final planifProvider = Provider.of<PlanificationProvider>(context, listen: false);
    try {
      final previews = await ApiService.getPlanificationPreview(commandeId);
      print('Planification previews received:');
      print('- Planifications: ${previews['planifications']?.length ?? 0}');
      print('- Waiting planifications: ${previews['waitingPlanifications']?.length ?? 0}');
      final planifications = previews['planifications'] as List<Planification>;
      final waitingPlanifications = previews['waitingPlanifications'] as List<WaitingPlanification>;

      if (planifications.isNotEmpty || waitingPlanifications.isNotEmpty) {
        bool isValid = planifications.every((p) => p.commandes.isNotEmpty && p.machines.isNotEmpty);
        print('Planification validity check: $isValid');

        if (!isValid && planifications.isNotEmpty) {
          Fluttertoast.showToast(msg: "Une ou plusieurs planifications sont incomplètes.");
          return;
        }

        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => PlanificationConfirmationDialog(
            planifications: planifications,
            commandeId: commandeId,
          ),
        );

        if (confirmed == true) {
          // Send all planifications and waiting planifications in a single request
          bool success = await ApiService.confirmerPlanification(planifications);

          if (success) {
            Fluttertoast.showToast(msg: "✅ Toutes les planifications ont été confirmées !");
            await planifProvider.fetchPlanifications();

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => AdminHomePage()),
                  (route) => false,
            );
          } else {
            Fluttertoast.showToast(msg: " Erreur lors de la confirmation.");
          }
        } else {
          Fluttertoast.showToast(msg: " Planification annulée.");
        }
      } else {
        Fluttertoast.showToast(msg: "Aucune planification disponible.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur interne : $e");
    }
  }

  Future<void> _submitCommande() async {
    if (!_formKey.currentState!.validate() ||
        selectedDate == null ||
        modeles.isEmpty) {
      Fluttertoast.showToast(
          msg: "Veuillez remplir tous les champs et ajouter au moins un modèle.",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white);
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
            msg: "Erreur : Modèle '${modele.nomModele}' non trouvé.",
            backgroundColor: Colors.redAccent,
            textColor: Colors.white);
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
      Fluttertoast.showToast(
          msg: "Commande ajoutée avec succès !",
          backgroundColor: Colors.green,
          textColor: Colors.white);

      await commandeProvider.fetchCommandes();
      final latestCommandes = commandeProvider.commandes;

      if (latestCommandes.isNotEmpty) {
        final latestCommande = latestCommandes.last;
        await _showPlanificationConfirmation(latestCommande.id!);
      }
    } else {
      Fluttertoast.showToast(
          msg: "Erreur lors de l'ajout de la commande.",
          backgroundColor: Colors.redAccent,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = Provider.of<ClientProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
        appBar: AppBar(
          backgroundColor: Colors.blueGrey[800],
          title: FadeInDown(
            child: const Text(
              "Ajouter une Commande",
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
              color: Colors.white.withOpacity(0.95),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildClientField(clientProvider),
                      const SizedBox(height: 16),
                      _buildTextField(
                          conditionnementController, "Conditionnement", Icons.inventory,
                          isOptional: true),
                      const SizedBox(height: 16),
                      FadeInUp(
                        child: ListTile(
                          tileColor: Colors.blueGrey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          title: Text(
                            selectedDate == null
                                ? "Sélectionner une date de livraison"
                                : "Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate!)}",
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          trailing: const Icon(Icons.calendar_today, color: Colors.blueGrey),
                          onTap: () => _selectDate(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInLeft(
                        child: const Text(
                          "Associer un modèle",
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModeleForm(),
                      const SizedBox(height: 20),
                      ...modeles.asMap().entries.map((entry) => FadeInUp(
                            delay: Duration(milliseconds: entry.key * 100),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: ListTile(
                                title: Text(
                                  "${entry.value.nomModele} - Taille: ${entry.value.taille} - Quantité: ${entry.value.quantite}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                ),
                                subtitle: Text(
                                  "Couleur: ${entry.value.couleur}",
                                  style: const TextStyle(color: Colors.blueGrey),
                                ),
                                trailing: ZoomIn(
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => setState(() => modeles.remove(entry.value)),
                                  ),
                                ),
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator(color: Colors.blueGrey)
                          : FadeInUp(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ZoomIn(
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Annuler",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  ZoomIn(
                                    child: ElevatedButton(
                                      onPressed: _submitCommande,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey[800],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "Ajouter",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
        const SizedBox(height: 16),
        _buildTailleField(),
        const SizedBox(height: 16),
        _buildTextField(quantiteController, "Quantité", Icons.numbers, isNumber: true),
        const SizedBox(height: 16),
        _buildTextField(couleurController, "Couleur", Icons.colorize),
        const SizedBox(height: 16),
        FadeInUp(
          child: ZoomIn(
            child: ElevatedButton.icon(
              onPressed: _addModele,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Ajouter Modèle",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}