import 'package:flutter/material.dart';
import 'package:frontend/views/LoginPage.dart';
import '../services/api_service.dart';

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
  bool isLoading = false;
  bool _obscurePassword = true;

  List<String> roles = [
    'Admin',
    'Manager',
    'Responsable modèle',
    'Responsable matière',
    'Ouvrier'
  ];

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      final response = await ApiService().register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        selectedRole ?? 'Ouvrier',
      );

      setState(() => isLoading = false);

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur: ${response?['message'] ?? 'Erreur inconnue'}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/auth_bg.jpeg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.darken,
            ),
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.jpg',
                    height: 120,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Nom utilisateur',
                                prefixIcon: Icon(Icons.person,
                                    color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) =>
                                  value!.isEmpty ? 'Champ requis' : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon:
                                    Icon(Icons.email, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  value!.isEmpty || !value.contains('@')
                                      ? 'Email invalide'
                                      : null,
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon:
                                    Icon(Icons.lock, color: Colors.deepPurple),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) => value!.length < 6
                                  ? 'Au moins 6 caractères'
                                  : null,
                            ),
                            SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              items: roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(
                                    role,
                                    style: TextStyle(color: Colors.deepPurple),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Rôle',
                                prefixIcon:
                                    Icon(Icons.work, color: Colors.deepPurple),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              dropdownColor: Colors.white,
                            ),
                            SizedBox(height: 30),
                            if (isLoading)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.deepPurple),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _registerUser,
                                  child: Text(
                                    'S\'inscrire',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 5,
                                  ),
                                ),
                              ),
                            SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LoginPage()),
                                );
                              },
                              child: Text(
                                "Déjà un compte ? Connectez-vous",
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
