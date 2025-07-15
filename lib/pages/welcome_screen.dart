import 'package:flutter/material.dart';
import '../main.dart';

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
