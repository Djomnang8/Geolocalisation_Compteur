import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import 'login_page.dart';

/// Écran de démarrage (splash) : logo de l'entreprise et texte
/// « Géolocalisation des compteurs électriques », avec effets d'apparition
/// (fondu + zoom sur le logo, glissement du texte, halo pulsé, points de
/// chargement), puis ouverture automatique de la page de connexion.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  // Apparition du logo : fondu + zoom (effet rebond)
  late final AnimationController _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _logoOpacite =
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
  late final Animation<double> _logoZoom = Tween<double>(begin: 0.55, end: 1.0)
      .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

  // Apparition du texte : fondu + glissement vers le haut
  late final AnimationController _texteCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  late final Animation<double> _texteOpacite =
      CurvedAnimation(parent: _texteCtrl, curve: Curves.easeOut);
  late final Animation<Offset> _texteGlisse =
      Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
          CurvedAnimation(parent: _texteCtrl, curve: Curves.easeOutCubic));

  // Halo pulsé autour du logo + points de chargement
  late final AnimationController _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _logoCtrl.forward();
    // Le texte apparait apres le logo
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _texteCtrl.forward();
    });
    // Puis ouverture de la page de connexion
    _minuteur = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const LoginPage(),
        ),
      ));
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _logoCtrl.dispose();
    _texteCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaire, AppColors.primaireFonce, AppColors.primaireNuit],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo : halo pulsé + fondu + zoom
              AnimatedBuilder(
                animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                builder: (context, _) {
                  final pulse = _pulseCtrl.value; // 0 -> 1 en boucle
                  return Opacity(
                    opacity: _logoOpacite.value,
                    child: Transform.scale(
                      scale: _logoZoom.value,
                      child: Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.30),
                              blurRadius: 40,
                              offset: const Offset(0, 18),
                            ),
                            // Halo pulsé (effet de demarrage)
                            BoxShadow(
                              color: Colors.white
                                  .withValues(alpha: 0.35 * (1 - pulse)),
                              blurRadius: 6,
                              spreadRadius: 26 * pulse,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/logo.jpeg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.bolt,
                              size: 64, color: AppColors.primaire),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 34),
              // Texte : fondu + glissement vers le haut
              FadeTransition(
                opacity: _texteOpacite,
                child: SlideTransition(
                  position: _texteGlisse,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        Text(
                          'Géolocalisation des compteurs électriques',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 54,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3AD07A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'SOCADEL · Douala, agence de Koumassi',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            color: const Color(0xFFB9C6E6),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Points de chargement animes
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_pulseCtrl.value + i / 3) % 1.0;
                      final actif = phase < 0.35;
                      return Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: actif ? 0.95 : 0.30),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
