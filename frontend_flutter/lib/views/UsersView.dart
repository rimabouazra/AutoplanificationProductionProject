import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/providers/userProvider.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: FadeIn(
              child: Text(
                "Vous n'avez pas la permission d'accéder à cette page.",
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 18,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey[800],
        title: FadeInDown(
          child: const Text(
            "Gestion des Utilisateurs",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          FadeInRight(
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: "Déconnexion",
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(context),
      ),
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
      color: Colors.blueGrey[800],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInLeft(
              child: _buildSectionHeader("➕ Demandes d'inscription"),
            ),
            if (pendingUsers.isEmpty)
              FadeIn(
                child: _buildEmptyState("Aucune demande en attente"),
              ),
            ...pendingUsers.asMap().entries.map((entry) => FadeInUp(
                  delay: Duration(milliseconds: entry.key * 100),
                  child: _buildPendingUserCard(entry.value),
                )),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Colors.blueGrey),
            const SizedBox(height: 24),
            FadeInLeft(
              child: _buildSectionHeader("👥 Utilisateurs existants"),
            ),
            if (approvedUsers.isEmpty)
              FadeIn(
                child: _buildEmptyState("Aucun utilisateur approuvé"),
              ),
            ...approvedUsers.asMap().entries.map((entry) => FadeInUp(
                  delay: Duration(milliseconds: entry.key * 100),
                  child: _buildApprovedUserCard(entry.value),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[800],
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
            color: Colors.blueGrey[600],
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueGrey[100],
              child: Text(
                user.nom[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nom,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.blueGrey[600],
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
        ZoomIn(
          child: IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: "Accepter",
            onPressed: () => _approveUser(user),
          ),
        ),
        ZoomIn(
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: "Refuser",
            onPressed: () => _rejectUser(user.id),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedUserCard(User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueGrey[100],
          child: Icon(Icons.person, color: Colors.blueGrey[800]),
        ),
        title: Text(
          user.nom,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.role?.toUpperCase().replaceAll('_', ' ') ?? 'NON DÉFINI',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: _getRoleColor(user.role),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoomIn(
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: "Modifier le rôle",
                onPressed: () => _editUserRole(user),
              ),
            ),
            ZoomIn(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "Supprimer l'utilisateur",
                onPressed: () => _confirmDeleteUser(user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red[600]!;
      case 'manager':
        return Colors.blue[600]!;
      case 'responsable_modele':
        return Colors.green[600]!;
      case 'responsable_matiere':
        return Colors.orange[600]!;
      case 'ouvrier':
        return Colors.purple[600]!;
      default:
        return Colors.blueGrey[600]!;
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          content: const Text("Demande rejetée."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteUser(User user) async {
    final confirmed = await showDialog<bool>(
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
        content: Text(
          "Voulez-vous vraiment supprimer l'utilisateur ${user.nom} ?",
          style: const TextStyle(color: Colors.blueGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler", style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
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
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Attribuer un rôle",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sélectionnez le rôle pour cet utilisateur:",
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: initialRole,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blueGrey),
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
                      role.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 14),
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
              child: const Text(
                "Annuler",
                style: TextStyle(color: Colors.blueGrey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, selectedRole),
              child: const Text(
                "Confirmer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Confirmer la déconnexion",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        content: const Text(
          "Voulez-vous vraiment vous déconnexion ?",
          style: TextStyle(color: Colors.blueGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Annuler",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Déconnexion",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}