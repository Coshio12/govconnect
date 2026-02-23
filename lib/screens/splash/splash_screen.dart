import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Splash simple sin animaciones pesadas para evitar "Skipped frames" en el arranque.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image(
                      image: const AssetImage('assets/images/gov.png'),
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.work_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
              ),
              const SizedBox(height: 28),
              Text(
                'Mi Trabajo',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarija, Bolivia',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: const Color(0xFF34A853),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(
                color: Color(0xFF1A73E8),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
