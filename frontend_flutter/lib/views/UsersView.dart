import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/providers/userProvider.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Helper method for neumorphic AppBar icons
  Widget _buildAppBarIcon(IconData icon, VoidCallback onPressed, String tooltip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 2)),
              BoxShadow(color: Colors.white24, blurRadius: 8, offset: Offset(-2, -2)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: FadeInDown(
          child: const Text(
            "Gestion des Utilisateurs",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF00695C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          _buildAppBarIcon(Icons.logout, _logout, "Déconnexion"),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isAuthorized ? _buildBody(context) : _buildUnauthorizedView(),
      ),
    );
  }

  Widget _buildUnauthorizedView() {
    return Center(
      child: FadeIn(
        child: const Text(
          "Vous n'avez pas la permission d'accéder à cette page.",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 18,
            color: Color(0xFFEF5350),
          ),
          textAlign: TextAlign.center,
        ),
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
      color: const Color(0xFF26A69A),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white.withOpacity(0.9),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(child: _buildSectionHeader("➕ Demandes d'inscription")),
                if (pendingUsers.isEmpty)
                  FadeIn(child: _buildEmptyState("Aucune demande en attente")),
                ...pendingUsers.asMap().entries.map((entry) => FadeInUp(
                  delay: Duration(milliseconds: entry.key * 100),
                  child: _buildPendingUserCard(entry.value),
                )),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFF78909C)),
                const SizedBox(height: 24),
                FadeInLeft(child: _buildSectionHeader("👥 Utilisateurs existants")),
                if (approvedUsers.isEmpty)
                  FadeIn(child: _buildEmptyState("Aucun utilisateur approuvé")),
                ...approvedUsers.asMap().entries.map((entry) => FadeInUp(
                  delay: Duration(milliseconds: entry.key * 100),
                  child: _buildApprovedUserCard(entry.value),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF26A69A),
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
            fontFamily: 'Roboto',
            fontStyle: FontStyle.italic,
            fontSize: 14,
            color: const Color(0xFF78909C),
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
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF26A69A).withOpacity(0.2),
              child: Text(
                user.nom[0].toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF26A69A),
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
                      color: Color(0xFF37474F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: const Color(0xFF78909C),
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
            icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            tooltip: "Accepter",
            onPressed: () => _approveUser(user),
          ),
        ),
        ZoomIn(
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Color(0xFFEF5350)),
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
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF26A69A).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF26A69A)),
        ),
        title: Text(
          user.nom,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF37474F),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: const Color(0xFF78909C),
              ),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.role?.toUpperCase().replaceAll('_', ' ') ?? 'NON DÉFINI',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: Colors.white,
                ),
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
                icon: const Icon(Icons.edit, color: Color(0xFF26A69A)),
                tooltip: "Modifier le rôle",
                onPressed: () => _editUserRole(user),
              ),
            ),
            ZoomIn(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFEF5350)),
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
        return const Color(0xFFEF5350);
      case 'manager':
        return const Color(0xFF42A5F5);
      case 'responsable_modele':
        return const Color(0xFF4CAF50);
      case 'responsable_matiere':
        return const Color(0xFFFFA726);
      case 'ouvrier':
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF78909C);
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
          backgroundColor: const Color(0xFF4CAF50),
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
          backgroundColor: const Color(0xFFEF5350),
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
          backgroundColor: const Color(0xFF4CAF50),
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
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text(
          "Confirmer la suppression",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF26A69A),
          ),
        ),
        content: Text(
          "Voulez-vous vraiment supprimer l'utilisateur ${user.nom} ?",
          style: TextStyle(
            fontFamily: 'Roboto',
            color: const Color(0xFF78909C),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Annuler",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF78909C),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Supprimer",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
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
            backgroundColor: const Color(0xFF4CAF50),
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
          backgroundColor: Colors.white.withOpacity(0.9),
          title: const Text(
            "Attribuer un rôle",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontWeight: FontWeight.bold,
              color: Color(0xFF26A69A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Sélectionnez le rôle pour cet utilisateur:",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF78909C),
                ),
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
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF26A69A)),
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
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: Color(0xFF37474F),
                      ),
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
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Color(0xFF78909C),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F61),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, selectedRole),
              child: const Text(
                "Confirmer",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
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
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text(
          "Confirmer la déconnexion",
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontWeight: FontWeight.bold,
            color: Color(0xFF26A69A),
          ),
        ),
        content: const Text(
          "Voulez-vous vraiment vous déconnexion ?",
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF78909C),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Annuler",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF78909C),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Déconnexion",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
              ),
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