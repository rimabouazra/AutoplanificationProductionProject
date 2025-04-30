import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/views/admin_home_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/planification.dart';
import '../providers/PlanificationProvider .dart';
import '../services/api_service.dart';
import '../views/CommandePage.dart';
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
    _endDate = widget.planification.finPrevue ?? DateTime.now().add(const Duration(hours: 1));
  }

  Future<void> _confirmPlanification() async {
    setState(() => _isLoading = true);

    try {
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
        Fluttertoast.showToast(
          msg: "Planification confirmée avec succès !",
          backgroundColor: Colors.blue[700],
          textColor: Colors.white,
        );

        final planifProvider = Provider.of<PlanificationProvider>(context, listen: false);
        await planifProvider.fetchPlanifications();

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AdminHomePage()),
              (route) => false,
        );


      } else {
        Fluttertoast.showToast(msg: "Erreur lors de la confirmation");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Erreur: ${e.toString()}");
      debugPrint('Confirmation error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _startDate = newDateTime);
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() => _endDate = newDateTime);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy à  HH:mm');
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Text(
                  "Confirmer la Planification",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Détails de la planification:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Client Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.planification.commandes.isNotEmpty)
                          Text(
                            "Client: ${widget.planification.commandes.first.client.name}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[900],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "Machines affectées: ${widget.planification.machines.length}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Dates Section
                  Text(
                    "Dates proposées:",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Start Date Picker
                  _DatePickerCard(
                    label: "Début",
                    date: _startDate,
                    formatter: dateFormat,
                    onTap: () => _selectStartDate(context),
                  ),
                  const SizedBox(height: 12),

                  // End Date Picker
                  _DatePickerCard(
                    label: "Fin",
                    date: _endDate,
                    formatter: dateFormat,
                    onTap: () => _selectEndDate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),


            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Annuler modifications"),
                ),
                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text("Confirmer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  formatter.format(date),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit, color: Colors.blue[700], size: 18),
          ],
        ),
      ),
    );
  }
}