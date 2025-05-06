import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  void handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final result = await ApiService().loginUser(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        setState(() {
          isLoading = false;
        });

        if (result['token'] != null && result['utilisateur'] != null) {
          final utilisateur = result['utilisateur'];
          final role = utilisateur['role']?.toString().toLowerCase();

          if (role == null) {
            throw Exception('Role non défini dans la réponse');
          }

          //await cinéma;        
          await AuthService.saveUserData(
            result['token'],
            utilisateur['_id'],
            utilisateur['role']?.toString().toLowerCase() ?? '',
          );
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', result['token']);
          await prefs.setString('role', role);
          await prefs.setString('userId', utilisateur['_id']);

          switch (role) {
            case 'admin':
              Navigator.pushReplacementNamed(context, '/adminHome');
              break;
            case 'manager':
              Navigator.pushReplacementNamed(context, '/adminHome');
              break;
            case 'responsable_modele':
              Navigator.pushReplacementNamed(context, '/adminHome');
              break;
            case 'responsable_matiere':
              Navigator.pushReplacementNamed(context, '/adminHome');
              break;
            case 'ouvrier':
              Navigator.pushReplacementNamed(context, '/adminHome');
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Rôle inconnu : $role")),
              );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? "Échec de connexion - structure de réponse invalide",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la connexion: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/auth_bg.jpeg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    child: Image.asset(
                      'assets/logo.jpg',
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeInUp(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  FadeInUp(
                    delay: Duration(milliseconds: 200),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Colors.blueGrey[700]),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) =>
                                    value!.isEmpty || !value.contains('@') ? 'Email invalide' : null,
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[700]),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.blueGrey[700],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) =>
                                    value!.length < 6 ? 'Au moins 6 caractères' : null,
                              ),
                              SizedBox(height: 30),
                              isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey[800]!),
                                    )
                                  : ZoomIn(
                                      child: ElevatedButton(
                                        onPressed: handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueGrey[800],
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 5,
                                        ),
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                              SizedBox(height: 20),
                              FadeInUp(
                                delay: Duration(milliseconds: 400),
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement password reset navigation
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.blueGrey[200],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              FadeInUp(
                                delay: Duration(milliseconds: 600),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: TextStyle(color: const Color.fromARGB(179, 113, 111, 111)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/register');
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.blueGrey[200],
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}