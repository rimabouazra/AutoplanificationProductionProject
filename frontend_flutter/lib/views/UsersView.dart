import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/userProvider.dart';
import '../models/user.dart';

class UsersView extends StatefulWidget {
  @override
  _UsersViewState createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() {
        final userProvider = Provider.of<UserProvider?>(context, listen: false);
        userProvider?.fetchUsers();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider?>(context, listen: false);

    if (userProvider == null) {
      return const Center(
          child: Text("Erreur : Provider UserProvider introuvable"));
    }

    return Scaffold(
      body: FutureBuilder(
        future: userProvider.fetchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          return Consumer<UserProvider>(
            builder: (context, provider, child) {
              if (provider.users.isEmpty) {
                return const Center(child: Text("Aucun utilisateur trouvé"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.users.length,
                itemBuilder: (context, index) {
                  final user = provider.users[index];
                  return _buildUserCard(user);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade700,
          child: Text(user.nom[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(user.nom,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email : ${user.email}"),
            Text("Rôle : ${user.role}"),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editUser(user);
            } else if (value == 'delete') {
              _deleteUser(user.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("Modifier")),
            const PopupMenuItem(value: 'delete', child: Text("Supprimer")),
          ],
        ),
      ),
    );
  }

  void _editUser(User user) {
    // Ajouter la logique de modification ici
  }

  void _deleteUser(String userId) async {
    bool success = await Provider.of<UserProvider>(context, listen: false)
        .deleteUser(userId);
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Utilisateur supprimé")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Échec de suppression")));
    }
  }
}
