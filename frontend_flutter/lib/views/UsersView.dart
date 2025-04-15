import 'package:flutter/material.dart';
import 'package:frontend/providers/userProvider.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
class UsersView extends StatefulWidget {
  @override
  _UsersViewState createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  String? _userRole;
  bool _isAuthorized = false;
  @override
  void initState() {
    super.initState();
     _loadUserRole();
    Future.microtask(
        () => Provider.of<UserProvider>(context, listen: false).fetchUsers());
  }
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    setState(() {
      _userRole = role;
      _isAuthorized = role == 'admin';
    });

    if (_isAuthorized) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    }
  }
  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
    return Scaffold(
      appBar: AppBar(title: Text("Accès refusé")),
      body: Center(
        child: Text(
          "Vous n'avez pas la permission d'accéder à cette page.",
          style: TextStyle(fontSize: 16, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Gestion des Utilisateurs"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Déconnexion",
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final pendingUsers =
        userProvider.users.where((u) => u.status == 'pending').toList();
    final approvedUsers =
        userProvider.users.where((u) => u.status == 'approved').toList();

    return RefreshIndicator(
      onRefresh: () async => await userProvider.fetchUsers(),
      color: Theme.of(context).primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("➕ Demandes d'inscription"),
            if (pendingUsers.isEmpty)
              _buildEmptyState("Aucune demande en attente"),
            ...pendingUsers.map((user) => _buildPendingUserCard(user)),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            _buildSectionHeader("👥 Utilisateurs existants"),
            if (approvedUsers.isEmpty)
              _buildEmptyState("Aucun utilisateur approuvé"),
            ...approvedUsers.map((user) => _buildApprovedUserCard(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                user.nom[0].toUpperCase(),
                style: TextStyle(color: Colors.blue[800]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nom,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButtons(user),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(User user) {
    return Row(
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
    );
  }

  Widget _buildApprovedUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple[100],
          child: Icon(Icons.person, color: Colors.purple[800]),
        ),
        title: Text(
          user.nom,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.role?.toUpperCase() ?? 'NON DÉFINI',
                style: TextStyle(fontSize: 12),
              ),
              backgroundColor: _getRoleColor(user.role),
              labelStyle: TextStyle(color: Colors.white),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              tooltip: "Modifier le rôle",
              onPressed: () => _editUserRole(user),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: "Supprimer l'utilisateur",
              onPressed: () => _confirmDeleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red[400]!;
      case 'manager':
        return Colors.blue[400]!;
      case 'responsable_modele':
        return Colors.green[400]!;
      case 'responsable_matiere':
        return Colors.orange[400]!;
      case 'ouvrier':
        return Colors.purple[400]!;
      default:
        return Colors.grey;
    }
  }

  void _approveUser(User user) async {
    final role = await _selectRoleDialog();
    if (role == null) return;

    final success = await Provider.of<UserProvider>(context, listen: false)
        .approveUser(user.id, role);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${user.nom} a été approuvé en tant que $role."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _rejectUser(String id) async {
    final success =
        await Provider.of<UserProvider>(context, listen: false).rejectUser(id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Demande rejetée."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _editUserRole(User user) async {
    final role = await _selectRoleDialog(initialRole: user.role);
    if (role == null || role == user.role) return;

    final updatedUser = User(
      id: user.id,
      nom: user.nom,
      email: user.email,
      role: role,
      status: user.status,
    );

    final success = await Provider.of<UserProvider>(context, listen: false)
        .updateUser(user.id, updatedUser);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Rôle de ${user.nom} mis à jour à $role."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmer la suppression"),
        content:
            Text("Voulez-vous vraiment supprimer l'utilisateur ${user.nom} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("SUPPRIMER"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Provider.of<UserProvider>(context, listen: false)
          .deleteUser(user.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Utilisateur ${user.nom} supprimé."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<String?> _selectRoleDialog({String? initialRole}) async {
    String? selectedRole;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Attribuer un rôle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sélectionnez le rôle pour cet utilisateur:"),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: initialRole,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: [
                  'admin',
                  'manager',
                  'responsable_modele',
                  'responsable_matiere',
                  'ouvrier',
                ].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) => selectedRole = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ANNULER"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context, selectedRole),
              child: Text("CONFIRMER"),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    // Vous pouvez ajouter ici une logique de déconnexion via ApiService si nécessaire
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}
