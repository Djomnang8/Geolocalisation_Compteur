import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/soc_widgets.dart';
import 'admin/admin_shell.dart';
import 'tech/tech_shell.dart';

/// Page de connexion (identique a la maquette) : saisie du nom, du matricule
/// unique et du mot de passe. Le role est determine automatiquement par le
/// systeme (RBACL) : technicien -> espace technicien, admin -> espace admin.
/// Diagramme de sequence : "Authentification du technicien et de l'administrateur".
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nom = TextEditingController();
  final _matricule = TextEditingController();
  final _motDePasse = TextEditingController();
  String? _erreur;
  bool _enCours = false;

  Future<void> _connecter() async {
    if (_nom.text.trim().isEmpty ||
        _matricule.text.trim().isEmpty ||
        _motDePasse.text.trim().isEmpty) {
      setState(() => _erreur = 'Veuillez renseigner tous les champs.');
      return;
    }
    setState(() { _erreur = null; _enCours = true; });
    try {
      final utilisateur = await AuthService.instance.connecter(
        nom: _nom.text.trim(),
        matricule: _matricule.text.trim(),
        motDePasse: _motDePasse.text.trim(),
      );
      if (!mounted) return;
      // RBACL : chaque profil n'accede qu'a sa propre interface.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => utilisateur.estAdmin ? const AdminShell() : const TechShell(),
      ));
    } catch (e) {
      setState(() => _erreur = e.toString().contains('Exception')
          ? "Connexion impossible à l'API Frontend (port 8080)."
          : e.toString());
      final message = e.toString();
      if (!message.contains('SocketException') && !message.contains('Timeout')) {
        setState(() => _erreur = message);
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  void _demo(String nom, String matricule) {
    _nom.text = nom;
    _matricule.text = matricule;
    _motDePasse.text = '1234';
    _connecter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaire, AppColors.primaireFonce, AppColors.primaireNuit],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // En-tete : logo + titre
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/logo.jpeg',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.bolt,
                                  size: 56, color: AppColors.primaire)),
                        ),
                        const SizedBox(height: 18),
                        Text('SOCADEL Géoloc',
                            style: GoogleFonts.ibmPlexSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'Géolocalisation des compteurs électriques — Douala, agence de Koumassi',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                              color: const Color(0xFFB9C6E6), fontSize: 12.5, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  // Carte de connexion
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                    decoration: BoxDecoration(
                      color: AppColors.fond,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 44,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connexion',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.texte)),
                        const SizedBox(height: 4),
                        Text(
                          'Saisissez vos identifiants. Votre rôle est déterminé automatiquement (RBACL).',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5, color: AppColors.texteSecondaire),
                        ),
                        const SizedBox(height: 20),
                        ChampSocadel(
                            label: 'Nom complet',
                            placeholder: 'Ex : Jean MBALLA',
                            controleur: _nom),
                        const SizedBox(height: 15),
                        ChampSocadel(
                            label: 'Matricule',
                            placeholder: 'Ex : TECH-2043',
                            controleur: _matricule,
                            mono: true),
                        const SizedBox(height: 15),
                        ChampSocadel(
                            label: 'Mot de passe',
                            placeholder: '••••',
                            controleur: _motDePasse,
                            motDePasse: true),
                        if (_erreur != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.rougeFond,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(children: [
                              Text('!',
                                  style: GoogleFonts.ibmPlexSans(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.rougeSombre)),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(_erreur!,
                                    style: GoogleFonts.ibmPlexSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.rougeSombre)),
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 14),
                        BoutonPrincipal(
                            texte: 'Se connecter',
                            onPressed: _connecter,
                            enCours: _enCours),
                        const SizedBox(height: 22),
                        Center(
                          child: Text('COMPTES DE DÉMONSTRATION',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11,
                                  letterSpacing: 0.9,
                                  color: const Color(0xFF94A0B4))),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                                child: _CompteDemo(
                                    titre: 'Technicien',
                                    matricule: 'TECH-2043',
                                    onTap: () => _demo('Jean MBALLA', 'TECH-2043'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _CompteDemo(
                                    titre: 'Administrateur',
                                    matricule: 'ADM-1007',
                                    onTap: () => _demo('Alice NGONO', 'ADM-1007'))),
                          ],
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

class _CompteDemo extends StatelessWidget {
  final String titre;
  final String matricule;
  final VoidCallback onTap;
  const _CompteDemo({required this.titre, required this.matricule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.bordureInput, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre,
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.texte)),
            const SizedBox(height: 2),
            Text(matricule,
                style: GoogleFonts.ibmPlexMono(
                    fontSize: 10.5, color: AppColors.texteSecondaire)),
          ],
        ),
      ),
    );
  }
}
