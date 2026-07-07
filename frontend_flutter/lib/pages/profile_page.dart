import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/session.dart';
import '../services/auth_service.dart';
import '../widgets/soc_widgets.dart';
import 'login_page.dart';

/// Mon profil (maquettes "TECH PROFILE" et "ADMIN PROFILE") : avatar avec
/// initiales, nom, matricule et role, puis modification du nom complet et
/// du mot de passe. Le technicien dispose en plus du bouton Déconnexion.
class ProfilePage extends StatefulWidget {
  /// Couleur de l'avatar : bleu pour le technicien, violet pour l'admin.
  final Color couleurAvatar;
  final bool avecDeconnexion;

  const ProfilePage({
    super.key,
    this.couleurAvatar = AppColors.primaire,
    this.avecDeconnexion = true,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _nom =
      TextEditingController(text: Session.instance.utilisateur?.nom ?? '');
  final _motDePasse = TextEditingController();
  bool _enregistrement = false;

  Future<void> _enregistrer() async {
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      afficherToast(context, 'Renseignez votre nom complet');
      return;
    }
    setState(() => _enregistrement = true);
    try {
      await AuthService.instance.modifierProfil(
        nom: nom,
        motDePasse:
            _motDePasse.text.trim().isEmpty ? null : _motDePasse.text.trim(),
      );
      if (!mounted) return;
      _motDePasse.clear();
      setState(() {});
      afficherToast(context, 'Profil enregistré');
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  void _deconnecter() {
    AuthService.instance.deconnecter();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = Session.instance.utilisateur;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 30),
      children: [
        // Avatar + identite (identiques a la maquette)
        Column(children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
                color: widget.couleurAvatar, shape: BoxShape.circle),
            child: Center(
              child: Text(utilisateur?.initiales ?? '?',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Text(utilisateur?.nom ?? '—',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texte)),
          const SizedBox(height: 3),
          Text('${utilisateur?.matricule ?? '—'} · ${utilisateur?.roleLibelle ?? ''}',
              style: GoogleFonts.ibmPlexMono(
                  fontSize: 12, color: AppColors.texteLeger)),
        ]),
        const SizedBox(height: 24),
        Text('Modifier mon profil',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texte)),
        const SizedBox(height: 11),
        ChampSocadel(label: 'Nom complet', controleur: _nom),
        const SizedBox(height: 14),
        ChampSocadel(
          label: 'Nouveau mot de passe',
          controleur: _motDePasse,
          placeholder: 'Laisser vide pour ne pas changer',
          motDePasse: true,
        ),
        const SizedBox(height: 20),
        BoutonPrincipal(
          texte: 'Enregistrer',
          enCours: _enregistrement,
          onPressed: _enregistrer,
        ),
        if (widget.avecDeconnexion) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deconnecter,
              icon: const Icon(Icons.logout, size: 18, color: AppColors.rougeSombre),
              label: Text('Déconnexion',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rougeSombre)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF3C2C2), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
