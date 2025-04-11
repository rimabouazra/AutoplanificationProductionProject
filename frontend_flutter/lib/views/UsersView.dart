import 'package:flutter/material.dart';
import 'package:frontend/providers/userProvider.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';

class UsersView extends StatefulWidget {
  @override
  _UsersViewState createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<UserProvider>(context, listen: false).fetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final pendingUsers = userProvider.users.where((u) => u.status == 'pending').toList();
    final approvedUsers = userProvider.users.where((u) => u.status == 'approved').toList();

    return Scaffold(
      appBar: AppBar(title: Text("Utilisateurs")),
      body: RefreshIndicator(
        onRefresh: () async => await userProvider.fetchUsers(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("➕ Demandes d'inscription", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            if (pendingUsers.isEmpty)
              Text("Aucune demande en attente", style: TextStyle(color: Colors.grey)),
            ...pendingUsers.map((user) => _buildPendingUserCard(user)),

            Divider(height: 40),
            Text("👥 Utilisateurs existants", style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 8),
            if (approvedUsers.isEmpty)
              Text("Aucun utilisateur approuvé", style: TextStyle(color: Colors.grey)),
            ...approvedUsers.map((user) => _buildApprovedUserCard(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(User user) {
    return Card(
      child: ListTile(
        title: Text(user.nom),
        subtitle: Text(user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check_circle, color: Colors.green),
              tooltip: "Accepter",
              onPressed: () => _approveUser(user),
            ),
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              tooltip: "Refuser",
              onPressed: () => _rejectUser(user.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedUserCard(User user) {
    return Card(
      child: ListTile(
        title: Text(user.nom),
        subtitle: Text("${user.email} - ${user.role?.toUpperCase() ?? 'Non défini'}"),
        trailing: Icon(Icons.verified, color: Colors.deepPurple),
      ),
    );
  }

  void _approveUser(User user) async {
    final role = await _selectRoleDialog();
    if (role == null) return;

    final success = await Provider.of<UserProvider>(context, listen: false)
        .approveUser(user.id, role);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${user.nom} a été approuvé en tant que $role.")));
    }
  }

  void _rejectUser(String id) async {
    final success = await Provider.of<UserProvider>(context, listen: false).rejectUser(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Demande rejetée.")));
    }
  }

  Future<String?> _selectRoleDialog() async {
    String? selectedRole;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Sélectionner un rôle"),
          content: DropdownButtonFormField<String>(
            items: [
              'admin',
              'manager',
              'responsable_modele',
              'responsable_matiere',
              'ouvrier',
            ].map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: (value) => selectedRole = value,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedRole),
              child: Text("Confirmer"),
            ),
          ],
        );
      },
    );
  }
}
