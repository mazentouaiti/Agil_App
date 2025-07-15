import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Widget _buildSocialButton({required Widget icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black54, width: 1)),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        style: IconButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.all(12)),
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication not available on this device.')),
        );
        return;
      }
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous avec Face ID ou empreinte digitale',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!mounted) return;
      if (authenticated) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentification biométrique échouée.')),
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur biométrique: ${e.toString()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inconnue: ${e.toString()}')),
      );
    }
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/api/login/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': _emailController.text.trim(),
            'password': _passwordController.text.trim(),
          }),
        );
        final responseData = json.decode(response.body);
        if (!mounted) return;
        if (response.statusCode == 200) {
          final token = responseData['access']?.toString();
          if (token == null) throw Exception('Token not received');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        } else {
          final errorMsg = responseData['message'] ?? 'Login failed';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      } on http.ClientException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réseau: ${e.toString()}')));
      } on Exception catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur inconnue: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF9C4)],
          ),
        ),
        child: Stack(
          children: [
            if (_isLoading)
              const LoadingIndicator(text: 'Connexion en cours...')
            else
              ListView(
                padding: const EdgeInsets.only(top: 100.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: AgilLogo()),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text('CONNEXION', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text('Accédez à votre espace professionnel', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        ),
                        const SizedBox(height: 40),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'Email professionnel',
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.black),
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Mot de passe',
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  if (value.length < 6) {
                                    return 'Le mot de passe doit contenir au moins 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Mot de passe oublié?', style: TextStyle(color: Colors.black)),
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _isLoading = true);
                                          await _signIn();
                                          setState(() => _isLoading = false);
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: const Color(0xFFFFD700),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 0),
                                  elevation: 5,
                                ),
                                child: const Text('SE CONNECTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 20),
                              const Center(child: Text('Ou connectez-vous avec', style: TextStyle(color: Colors.black54, fontSize: 16))),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialButton(icon: const FaIcon(FontAwesomeIcons.google, color: Colors.black), onPressed: () {}),
                                  const SizedBox(width: 20),
                                  _buildSocialButton(icon: const FaIcon(FontAwesomeIcons.github, color: Colors.black), onPressed: () {}),
                                  const SizedBox(width: 20),
                                  _buildSocialButton(
                                    icon: const Icon(Icons.face, color: Colors.black),
                                    onPressed: _authenticateWithBiometrics,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Vous n'avez pas de compte? ", style: TextStyle(color: Colors.black54)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                                    },
                                    child: const Text('Créer un compte', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            Positioned(
              top: 60.0,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
