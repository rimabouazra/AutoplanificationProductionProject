import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/views/RegisterPage.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueGrey[50]!, Colors.blueGrey[200]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWideScreen = constraints.maxWidth > 800;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInUp(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    isWideScreen
                        ? Container(
                      width: 1000,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FadeInLeft(
                              child: SvgPicture.asset(
                                'images/login_illustration.svg',
                                height: 500,
                              ),
                            ),
                          ),
                          SizedBox(width: 40),
                          Expanded(
                            child: _buildForm(context),
                          ),
                        ],
                      ),
                    )
                        : Column(
                      children: [
                        FadeInDown(
                          child: SvgPicture.asset(
                            'images/login_illustration.svg',
                            height: 300,
                          ),
                        ),
                        SizedBox(height: 30),
                        _buildForm(context),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: 200),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 450),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blueGrey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 16,
                      ),
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
                      prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.blueGrey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.blueGrey[600],
                        fontSize: 16,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) =>
                    value!.length < 6 ? 'Au moins 6 caractères' : null,
                  ),
                  SizedBox(height: 30),
                  isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueGrey[700]!),
                  )
                      : ZoomIn(
                    child: ElevatedButton(
                      onPressed: handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeInUp(
                    delay: Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "pas de compte? ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                transitionDuration: Duration(milliseconds: 400),
                              ),
                            );
                          },
                          child: Text(
                            'Se connecter',
                            style: TextStyle(
                              color: Colors.blueGrey[700],
                              fontSize: 16,
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
    );
  }
}