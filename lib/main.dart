import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'pages/welcome_screen.dart';
import 'package:local_auth/local_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Shared widgets
class AgilLogo extends StatelessWidget {
  final double size;
  const AgilLogo({Key? key, this.size = 80}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
          size: size * 0.5,
          color: Color(0xFFFFD700),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String? text;
  const LoadingIndicator({Key? key, this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          if (text != null) ...[
            SizedBox(height: 16),
            Text(text!, style: TextStyle(color: Colors.black)),
          ]
        ],
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double angle;
  final Color color;

  CirclePainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 5;

    double startAngle = -90 * (pi / 180);
    double sweepAngle = angle * (pi / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ),
  );
  runApp(const AgilDistributionApp());
}

class AgilDistributionApp extends StatelessWidget {
  const AgilDistributionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agil Distribution Tunisia',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFFFFD700),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFFFD700),
          secondary: Colors.black,
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 360).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF9C4)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated logo
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(100, 100),
                            painter: CirclePainter(angle: _animation.value, color: const Color(0xFFFFD700)),
                          );
                        },
                      ),
                      const AgilLogo(size: 80),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'AGIL ENERGY',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TUNISIA',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Distribution des Pétroles',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: const Color(0xFFFFD700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      elevation: 8,
                    ),
                    child: const Text('CONNEXION', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: const Text('CRÉER UN COMPTE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
                // Tunisian flag placeholder
                // ...existing code...
                const SizedBox(height: 10),
                const Text('BIENVENUE', style: TextStyle(color: Colors.black54, fontSize: 16)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CirclePainterSignIn extends CustomPainter {
  final double angle;
  final Color color;

  CirclePainterSignIn({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 5;

    // Convert angle to radians
    double startAngle = -90 * (pi / 180);
    double sweepAngle = angle * (pi / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

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
                                  _buildSocialButton(icon: const Icon(Icons.face, color: Colors.black), onPressed: () {}),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication not available on this device.')),
        );
        return;
      }
      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous avec Face ID ou empreinte digitale',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated) {
        // On success, go to HomeScreen (simulate login)
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentification biométrique échouée.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur biométrique: ${e.toString()}')),
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

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
  // Add controllers for text fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
              child: Text(
                'CRÉER UN COMPTE',
                style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                ),
              ),
              ),
              const SizedBox(height: 10),
              const Center(
              child: Text(
                'Rejoignez notre réseau de distribution',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              ),
              const SizedBox(height: 40),
              Form(
              key: _formKey,
              child: Column(
                children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                  labelText: 'Nom complet',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.person, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                  labelText: 'Email professionnel',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
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
                  controller: _phoneController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                  labelText: 'Téléphone',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.phone, color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro';
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
                    icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: Colors.black),
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                  suffixIcon: IconButton(
                    icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  ),
                  validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer votre mot de passe';
                  }
                  return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                    setState(() {
                      _acceptTerms = value!;
                    });
                    },
                    fillColor: WidgetStateProperty.all(Colors.black),
                    checkColor: const Color(0xFFFFD700),
                  ),
                  Flexible(
                    child: RichText(
                    text: const TextSpan(
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
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                  if (_formKey.currentState!.validate() && _acceptTerms) {
                    _signUp();
                  }
                  },
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 0),
                  elevation: 5,
                  ),
                  child: const Text(
                  "S'INSCRIRE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const Text(
                    "Vous avez déjà un compte? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                      ),
                    );
                    },
                    child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
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
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      if (_passwordController.text != _confirmPasswordController.text) {
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
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            AgilLogo(size: 100),
            SizedBox(height: 30),
            Text('Welcome!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
