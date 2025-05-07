import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/models/modele.dart';
import 'package:frontend/views/AjouterModeleAdmin.dart';
import '../models/machine.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MachinesParSalleView extends StatefulWidget {
  final String salleId;
  const MachinesParSalleView({Key? key, required this.salleId})
      : super(key: key);

  @override
  _MachinesParSalleViewState createState() => _MachinesParSalleViewState();
}

class _MachinesParSalleViewState extends State<MachinesParSalleView> {
  List<dynamic> machines = [];

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  @override
  void initState() {
    super.initState();
    fetchMachinesParSalle();
  }

  Future<void> fetchMachinesParSalle() async {
    try {
      var data = await ApiService.fetchMachinesParSalle(widget.salleId);
      setState(() {
        machines = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement des machines : $e"),
          backgroundColor: Colors.redAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showAddMachineDialog() async {
    TextEditingController nomController = TextEditingController();
    String? selectedModele;
    String? selectedTaille;
    List<Modele> modeles = [];

    try {
      modeles = await ApiService.getModeles();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement des modèles : $e"),
          backgroundColor: Colors.redAccent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: FadeInDown(
                child: const Text(
                  "Ajouter une Machine",
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInUp(
                      child: TextField(
                        controller: nomController,
                        decoration: InputDecoration(
                          labelText: "Nom de la machine",
                          prefixIcon: const Icon(Icons.computer,
                              color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      child: DropdownButtonFormField<String>(
                        value: selectedModele,
                        hint: const Text("Sélectionner un modèle"),
                        items: modeles.map<DropdownMenuItem<String>>((modele) {
                          return DropdownMenuItem<String>(
                            value: modele.id,
                            child: Text(modele.nom),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedModele = value;
                            selectedTaille = null;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.category,
                              color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (selectedModele != null)
                      FadeInUp(
                        child: DropdownButtonFormField<String>(
                          value: selectedTaille,
                          hint: const Text("Sélectionner une taille"),
                          items: modeles
                              .firstWhere(
                                (m) => m.id == selectedModele,
                                orElse: () => Modele(
                                    id: '',
                                    nom: '',
                                    tailles: [],
                                    consommation: []),
                              )
                              .tailles
                              .map<DropdownMenuItem<String>>((taille) {
                            return DropdownMenuItem<String>(
                              value: taille,
                              child: Text(taille),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTaille = value;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.straighten,
                                color: Colors.blueGrey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler",
                      style: TextStyle(color: Colors.blueGrey)),
                ),
                ZoomIn(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      String nom = nomController.text.trim();
                      if (nom.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text("Veuillez remplir le champ du nom."),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }

                      try {
                        await ApiService.addMachine(
                          nom: nom,
                          salleId: widget.salleId,
                          modele: selectedModele,
                          taille: selectedTaille,
                        );
                        Navigator.pop(context);
                        fetchMachinesParSalle();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text("Machine ajoutée avec succès !"),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Erreur lors de l'ajout de la machine : $e"),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: const Text("Ajouter",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteMachine(dynamic machine) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la suppression",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        content: const Text("Voulez-vous vraiment supprimer cette machine ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text("Annuler", style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteMachine(machine["_id"]);
        setState(() {
          machines.removeWhere((m) => m["_id"] == machine["_id"]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Machine supprimée avec succès !"),
            backgroundColor: Colors.green,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression : $e"),
            backgroundColor: Colors.redAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showEditMachineDialog(dynamic machine) async {
    TextEditingController nomController =
        TextEditingController(text: machine["nom"]);
    String etat = machine["etat"] ?? "disponible";
    String modele = machine["modele"]?["nom"] ?? "Aucun modèle";
    String taille = machine["taille"] ?? "Aucune taille";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: FadeInDown(
                child: const Text(
                  "Modifier la Machine",
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInUp(
                      child: TextField(
                        controller: nomController,
                        decoration: InputDecoration(
                          labelText: "Nom de la machine",
                          prefixIcon: const Icon(Icons.computer,
                              color: Colors.blueGrey),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      child: DropdownButtonFormField<String>(
                        value: etat,
                        onChanged: (String? newValue) async {
                          setState(() {
                            etat = newValue!;
                          });
                          try {
                            await ApiService.updateMachine(
                                machine["_id"], nomController.text, etat);
                            setState(() {
                              machine["etat"] = etat;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text("État mis à jour avec succès !"),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Erreur lors de la mise à jour de l'état : $e"),
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        items: ["disponible", "occupee", "arretee"]
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.settings,
                              color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    if (etat == "occupee")
                      FadeInUp(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Text("Modèle associé: $modele",
                                style: TextStyle(color: Colors.blueGrey[600])),
                            Text("Taille: $taille",
                                style: TextStyle(color: Colors.blueGrey[600])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler",
                      style: TextStyle(color: Colors.blueGrey)),
                ),
                ZoomIn(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      try {
                        await ApiService.updateMachine(
                            machine["_id"], nomController.text, etat);
                        setState(() {
                          machine["nom"] = nomController.text;
                          machine["etat"] = etat;
                        });
                        Navigator.pop(context);
                        fetchMachinesParSalle();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text("Machine mise à jour avec succès !"),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erreur lors de la mise à jour : $e"),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    child: const Text("Enregistrer",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (etat == "disponible")
                  ZoomIn(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AjouterModeleAdmin(machineId: machine["_id"]),
                          ),
                        );
                      },
                      child: const Text("Ajouter un modèle",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey));
        }

        final role = snapshot.data!;
        final isAdminOrManager = role == 'admin' || role == 'manager';
        final canEditMachine = isAdminOrManager || role == 'responsable_modele';

        return Scaffold(
          backgroundColor: Colors.blueGrey[50],
          appBar: AppBar(
            backgroundColor: Colors.blueGrey[800],
            title: FadeInDown(
              child: const Text(
                "Machines par Salle",
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[50]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: machines.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blueGrey))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: machines.length,
                      itemBuilder: (context, index) {
                        var machine = machines[index];
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: _buildMachineCard(
                              machine, canEditMachine, isAdminOrManager),
                        );
                      },
                    ),
                  ),
          ),
          floatingActionButton: isAdminOrManager
              ? ZoomIn(
                  child: FloatingActionButton(
                    onPressed: _showAddMachineDialog,
                    backgroundColor: Colors.blueGrey[800],
                    tooltip: "Ajouter une machine",
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMachineCard(dynamic machine, bool canEdit, bool canDelete) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.all(4), // Réduire la marge
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canEdit ? () => _showEditMachineDialog(machine) : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.computer,
                size: 36,
                color: Color(int.parse(Machine.getEtatColor(machine["etat"]))),
              ),
              const SizedBox(height: 4),
              Text(
                machine["nom"],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "État: ${machine["etat"]}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey[600],
                ),
              ),
              if (canEdit || canDelete) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (canEdit)
                      IconButton(
                        iconSize: 20,
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditMachineDialog(machine),
                      ),
                    if (canDelete)
                      IconButton(
                        iconSize: 20,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteMachine(machine),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
