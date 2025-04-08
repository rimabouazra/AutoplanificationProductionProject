import 'package:flutter/material.dart';
import 'package:frontend/views/LoginPage.dart';
import '../services/api_service.dart'; // Assure-toi que le chemin est correct

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String selectedRole = 'Ouvrier';

  List<String> roles = [
    'Admin',
    'Manager',
    'Responsable modèle',
    'Responsable matière',
    'Ouvrier'
  ];

  bool isLoading = false;

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final user = {
        "username": _usernameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        "role": selectedRole
      };

      final response = await ApiService().register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        selectedRole ??
            'Ouvrier', // valeur par défaut si rien n'est sélectionné
      );

      if (response != null && response['success'] == true) {
        // Inscription réussie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // Erreur d'inscription
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur: ${response?['message'] ?? 'Erreur inconnue'}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Créer un compte')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'Nom utilisateur'),
                      validator: (value) =>
                          value!.isEmpty ? 'Champ requis' : null,
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value!.isEmpty || !value.contains('@')
                              ? 'Email invalide'
                              : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Mot de passe'),
                      obscureText: true,
                      validator: (value) =>
                          value!.length < 6 ? 'Au moins 6 caractères' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: roles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Rôle'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _registerUser,
                      child: Text('S’inscrire'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
