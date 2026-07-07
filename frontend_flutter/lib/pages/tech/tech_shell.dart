import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../services/auth_service.dart';
import '../../widgets/soc_widgets.dart';
import '../login_page.dart';
import '../profile_page.dart';
import 'tech_dashboard_page.dart';
import 'tech_map_page.dart';
import 'tech_reports_page.dart';
import 'tech_route_page.dart';

/// Coquille de l'espace TECHNICIEN : barre d'application bleue (titre +
/// sous-titre + logo) et barre de navigation inferieure a 5 onglets,
/// identiques a la maquette : Accueil, Carte, Itineraire, Rapports, Profil.
///
/// Pages realisees : Tableau de bord, Carte des compteurs, Detail compteur,
/// Formulaire d'inspection, Itineraire du jour, Mes rapports, Mon profil.
class TechShell extends StatefulWidget {
  const TechShell({super.key});

  @override
  State<TechShell> createState() => _TechShellState();
}

class _TechShellState extends State<TechShell> {
  int _onglet = 0;

  static const _titres = [
    ['Tableau de bord', 'Espace technicien'],
    ['Carte des compteurs', 'Compteurs attribués'],
    ['Itinéraire du jour', 'Trajet optimisé'],
    ['Mes rapports', 'Inspections envoyées'],
    ['Mon profil', 'Technicien'],
  ];

  void _deconnecter() {
    AuthService.instance.deconnecter();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TechDashboardPage(ouvrirCarte: () => setState(() => _onglet = 1)),
      const TechMapPage(),
      const TechRoutePage(),
      const TechReportsPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      appBar: BarreSocadel(
        titre: _titres[_onglet][0],
        sousTitre: _titres[_onglet][1],
        onDeconnexion: _deconnecter,
      ),
      body: pages[_onglet],
      bottomNavigationBar: _BarreNavTech(
        onglet: _onglet,
        onChange: (i) => setState(() => _onglet = i),
      ),
    );
  }
}

/// Barre d'application bleue de la maquette (logo blanc + titre + sous-titre).
class BarreSocadel extends StatelessWidget implements PreferredSizeWidget {
  final String titre;
  final String sousTitre;
  final VoidCallback? onDeconnexion;

  const BarreSocadel({
    super.key,
    required this.titre,
    this.sousTitre = '',
    this.onDeconnexion,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primaire,
      elevation: 2,
      automaticallyImplyLeading: false,
      titleSpacing: 14,
      title: Row(
        children: [
          const LogoSocadel(),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                if (sousTitre.isNotEmpty)
                  Text(sousTitre,
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onDeconnexion != null)
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: onDeconnexion,
            icon: const Icon(Icons.logout, size: 20, color: Colors.white),
          ),
      ],
    );
  }
}

class _BarreNavTech extends StatelessWidget {
  final int onglet;
  final ValueChanged<int> onChange;
  const _BarreNavTech({required this.onglet, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget item(int index, IconData icone, String label) {
      final actif = onglet == index;
      final couleur = actif ? AppColors.primaire : AppColors.inactifNav;
      return Expanded(
        child: InkWell(
          onTap: () => onChange(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 22, color: couleur),
                const SizedBox(height: 3),
                Text(label,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 10, fontWeight: FontWeight.w600, color: couleur)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.bordure)),
      ),
      child: SafeArea(
        child: Row(children: [
          item(0, Icons.home_outlined, 'Accueil'),
          item(1, Icons.location_on_outlined, 'Carte'),
          item(2, Icons.route_outlined, 'Itinéraire'),
          item(3, Icons.description_outlined, 'Rapports'),
          item(4, Icons.person_outline, 'Profil'),
        ]),
      ),
    );
  }
}

/// Session raccourcie pour les pages techniciens.
String get matriculeConnecte => Session.instance.utilisateur?.matricule ?? '';
