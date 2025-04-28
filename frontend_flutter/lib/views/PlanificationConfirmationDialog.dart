import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/planification.dart';
import '../services/api_service.dart';

class PlanificationConfirmationDialog extends StatefulWidget {
  final Planification planification;
  final String commandeId;

  const PlanificationConfirmationDialog({
    Key? key,
    required this.planification,
    required this.commandeId,
  }) : super(key: key);

  @override
  _PlanificationConfirmationDialogState createState() => _PlanificationConfirmationDialogState();
}

class _PlanificationConfirmationDialogState extends State<PlanificationConfirmationDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.planification.debutPrevue ?? DateTime.now();
    _endDate = widget.planification.finPrevue ?? DateTime.now().add(Duration(hours: 1));
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);

    try {
      // Update the planification with the edited dates
      final updatedPlanif = Planification(
        id: widget.planification.id,
        commandes: widget.planification.commandes,
        machines: widget.planification.machines,
        debutPrevue: _startDate,
        finPrevue: _endDate,
        statut: "confirmée",
      );

      final success = await ApiService.confirmerPlanification(updatedPlanif);

      if (success) {
        Fluttertoast.showToast(msg: "Planification confirmée avec succès !");
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Fluttertoast.showToast(msg: "Erreur lors de la confirmation");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return AlertDialog(
      title: Text("Confirmer la Planification"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Détails de la planification:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            if (widget.planification.commandes.isNotEmpty)
              Text("Commande: ${widget.planification.commandes.first.client.name}"),
            SizedBox(height: 10),
            Text("Machines affectées: ${widget.planification.machines.length}"),
            SizedBox(height: 20),
            Text("Dates proposées:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListTile(
              title: Text("Début: ${dateFormat.format(_startDate)}"),
              trailing: Icon(Icons.edit),
              onTap: () => _selectStartDate(context),
            ),
            ListTile(
              title: Text("Fin: ${dateFormat.format(_endDate)}"),
              trailing: Icon(Icons.edit),
              onTap: () => _selectEndDate(context),
            ),
          ],
        ),
      ),
      actions: [
        // Bouton Annuler
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // L'utilisateur a annulé
          },
          child: Text("Annuler"),
        ),
        // Bouton Confirmer
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            // Appel de la fonction pour confirmer la planification
            await _confirmPlanification();
            Navigator.of(context).pop(true); // L'utilisateur a confirmé
          },
          child: _isLoading
              ? CircularProgressIndicator()
              : Text("Confirmer"),
        ),
      ],
    );
  }

}