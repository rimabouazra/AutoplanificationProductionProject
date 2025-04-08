import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  void handleLogin() async {
    setState(() {
      isLoading = true;
    });

    final result = await ApiService().loginUser(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Sauvegarder token + rediriger selon rôle
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', result['token']);
      await prefs.setString('role', result['user']['role']);
      await prefs.setString('userId', result['user']['_id']);

      final role = result['user']['role'];

      // Navigation basée sur le rôle
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/adminHome');
          break;
        case 'manager':
          Navigator.pushReplacementNamed(context, '/managerHome');
          break;
        case 'responsable_modele':
          Navigator.pushReplacementNamed(context, '/modeleHome');
          break;
        case 'responsable_matiere':
          Navigator.pushReplacementNamed(context, '/matiereHome');
          break;
        case 'ouvrier':
          Navigator.pushReplacementNamed(context, '/ouvrierHome');
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Rôle inconnu : $role")),
          );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Échec de connexion")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connexion")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleLogin,
                    child: Text("Se connecter"),
                  ),
          ],
        ),
      ),
    );
  }
}
