import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../main.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      if (_passwordController.text != _confirmPasswordController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
        return;
      }
      try {
        final requestBody = {
          'username': _emailController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim(),
          'full_name': _nameController.text.trim(),
        };
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8000/api/signup/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );
        final responseData = json.decode(response.body);
        if (!mounted) return;
        if (response.statusCode == 201) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account created successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Signup failed')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF9C4)],
          ),
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(top: 100.0),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_gas_station,
                              size: 40,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Text(
                          'CRÉER UN COMPTE',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Rejoignez notre réseau de distribution',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                      SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Nom complet',
                                labelStyle: TextStyle(color: Colors.black54),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Email professionnel',
                                labelStyle: TextStyle(color: Colors.black54),
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
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
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneController,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'Téléphone',
                                labelStyle: TextStyle(color: Colors.black54),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre numéro';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              style: TextStyle(color: Colors.black),
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                labelStyle: TextStyle(color: Colors.black54),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.black54,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 8) {
                                  return 'Le mot de passe doit contenir au moins 8 caractères';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            TextFormField(
                              controller: _confirmPasswordController,
                              style: TextStyle(color: Colors.black),
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                labelStyle: TextStyle(color: Colors.black54),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.black54,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez confirmer votre mot de passe';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value!;
                                    });
                                  },
                                  fillColor: WidgetStateProperty.all(
                                    Colors.black,
                                  ),
                                  checkColor: Color(0xFFFFD700),
                                ),
                                Flexible(
                                  child: RichText(
                                    text: TextSpan(
                                      text: "J'accepte les ",
                                      style: TextStyle(color: Colors.black54),
                                      children: [
                                        TextSpan(
                                          text: 'conditions générales',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(text: " et la "),
                                        TextSpan(
                                          text: 'politique de confidentialité',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate() && _acceptTerms) {
                                  _signUp();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Color(0xFFFFD700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                minimumSize: Size(double.infinity, 0),
                                elevation: 5,
                              ),
                              child: Text(
                                "S'INSCRIRE",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Vous avez déjà un compte? ",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SignInScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 40),
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
              left: 20.0,
              child: Material(
                type: MaterialType.transparency,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
