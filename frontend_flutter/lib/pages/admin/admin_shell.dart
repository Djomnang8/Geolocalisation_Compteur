import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../login_page.dart';
import '../placeholder_page.dart';
import '../tech/tech_shell.dart' show BarreSocadel;
import 'admin_dashboard_page.dart';
import 'admin_map_page.dart';
import 'admin_meters_page.dart';
import 'admin_reports_page.dart';
import 'admin_techniciens_page.dart';

/// Coquille de l'espace ADMINISTRATEUR : navigation inferieure identique
/// a la maquette (Tableau, Carte, Compteurs, Rapports, Menu) + feuille
/// "Menu administrateur" (Techniciens, Attribution, Zones, Statistiques,
/// Suivi, Journal d'audit, Mon profil, Deconnexion).
///
/// Pages realisees (moitie de l'espace administrateur) : Tableau de bord,
/// Carte de Douala, Gestion des compteurs, Fiche compteur, Rapports,
/// Detail du rapport, Techniciens, Fiche technicien.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _onglet = 0;

  static const _titres = [
    ['Tableau de bord', 'Administration SOCADEL'],
    ['Carte de Douala', 'Tous les compteurs'],
    ['Gestion des compteurs', ''],
    ["Rapports d'inspection", ''],
  ];

  void _deconnecter() {
    AuthService.instance.deconnecter();
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  void _ouvrirMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      // Feuille defilante : evite tout debordement sur les petits ecrans
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84),
      builder: (contexteFeuille) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFCCD4E0),
                        borderRadius: BorderRadius.circular(3))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                child: Text('Menu administrateur',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte)),
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.4,
                children: [
                  _itemMenu(contexteFeuille, Icons.group_outlined, 'Techniciens',
                      const AdminTechniciensPage()),
                  _itemMenu(contexteFeuille, Icons.assignment_ind_outlined,
                      'Attribution',
                      const _PageDetail(
                          titre: 'Attribution des compteurs',
                          enfant: PagePlaceholder(titre: 'Attribution des compteurs'))),
                  _itemMenu(contexteFeuille, Icons.layers_outlined, 'Zones de service',
                      const _PageDetail(
                          titre: 'Zones de service',
                          enfant: PagePlaceholder(titre: 'Zones de service'))),
                  _itemMenu(contexteFeuille, Icons.bar_chart, 'Statistiques',
                      const _PageDetail(
                          titre: 'Statistiques par zone',
                          enfant: PagePlaceholder(titre: 'Statistiques par zone'))),
                  _itemMenu(contexteFeuille, Icons.schedule, 'Suivi déplacements',
                      const _PageDetail(
                          titre: 'Suivi des déplacements',
                          enfant: PagePlaceholder(titre: 'Suivi des déplacements'))),
                  _itemMenu(contexteFeuille, Icons.fact_check_outlined,
                      "Journal d'audit",
                      const _PageDetail(
                          titre: "Journal d'audit",
                          enfant: PagePlaceholder(titre: "Journal d'audit"))),
                  _itemMenu(contexteFeuille, Icons.person_outline, 'Mon profil',
                      const _PageDetail(
                          titre: 'Mon profil',
                          enfant: PagePlaceholder(titre: 'Mon profil'))),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(contexteFeuille).pop();
                    _deconnecter();
                  },
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.rougeSombre),
                  label: Text('Déconnexion',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rougeSombre)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.rougeFond,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemMenu(BuildContext contexteFeuille, IconData icone, String label,
      Widget destination) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          Navigator.of(contexteFeuille).pop();
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => destination));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icone, size: 22, color: AppColors.primaire),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminDashboardPage(ouvrirRapports: () => setState(() => _onglet = 3)),
      const AdminMapPage(),
      const AdminMetersPage(),
      const AdminReportsPage(),
    ];
    return Scaffold(
      appBar: BarreSocadel(
        titre: _titres[_onglet][0],
        sousTitre: _titres[_onglet][1],
        onDeconnexion: _deconnecter,
      ),
      body: pages[_onglet],
      bottomNavigationBar: _BarreNavAdmin(
        onglet: _onglet,
        onChange: (i) => setState(() => _onglet = i),
        onMenu: _ouvrirMenu,
      ),
    );
  }
}

class _BarreNavAdmin extends StatelessWidget {
  final int onglet;
  final ValueChanged<int> onChange;
  final VoidCallback onMenu;
  const _BarreNavAdmin(
      {required this.onglet, required this.onChange, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    Widget item(int? index, IconData icone, String label, {VoidCallback? onTap}) {
      final actif = index != null && onglet == index;
      final couleur = actif ? AppColors.primaire : AppColors.inactifNav;
      return Expanded(
        child: InkWell(
          onTap: onTap ?? () => onChange(index!),
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
          item(0, Icons.dashboard_outlined, 'Tableau'),
          item(1, Icons.location_on_outlined, 'Carte'),
          item(2, Icons.speed, 'Compteurs'),
          item(3, Icons.description_outlined, 'Rapports'),
          item(null, Icons.menu, 'Menu', onTap: onMenu),
        ]),
      ),
    );
  }
}

/// Page de detail simple avec barre bleue + retour (pour le menu admin).
class _PageDetail extends StatelessWidget {
  final String titre;
  final Widget enfant;
  const _PageDetail({required this.titre, required this.enfant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaire,
        elevation: 2,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        title: Text(titre,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: enfant,
    );
  }
}
