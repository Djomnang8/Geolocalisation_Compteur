import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/rapport.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'admin_report_detail_page.dart';

/// Tableau de bord administrateur (maquette "ADMIN DASHBOARD") :
/// indicateurs KPI (compteurs, interventions, taux de panne, couverture),
/// graphique "Compteurs par zone" et rapports recents.
/// Diagramme de sequence : "Tableau de bord et export (PDF/Excel)".
class AdminDashboardPage extends StatefulWidget {
  final VoidCallback? ouvrirRapports;
  const AdminDashboardPage({super.key, this.ouvrirRapports});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _donnees;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final donnees = await StatsService.instance.tableauDeBord();
      if (mounted) setState(() { _donnees = donnees; _erreur = null; });
    } catch (e) {
      if (mounted) setState(() => _erreur = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = Session.instance.utilisateur!;
    final d = _donnees;
    final zones = (d?['zoneBars'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final recents = ((d?['rapportsRecents'] as List?) ?? const [])
        .map((r) => Rapport.fromJson(r))
        .toList();

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        children: [
          Text('Bonjour,',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13, color: AppColors.texteSecondaire)),
          const SizedBox(height: 2),
          Text(utilisateur.nom,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.texte)),
          const SizedBox(height: 3),
          Text('${utilisateur.matricule} · Administrateur',
              style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppColors.texteLeger)),
          const SizedBox(height: 18),

          if (_erreur != null) ...[
            EncadreVide(texte: 'Impossible de charger les indicateurs.\n$_erreur'),
            const SizedBox(height: 14),
          ] else if (d == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (d != null) ...[
            // KPI en grille 2 x 2
            Row(children: [
              Expanded(
                  child: _Kpi(
                      valeur: '${d['totalCompteurs']}',
                      label: 'Compteurs · Douala',
                      fondBleu: true)),
              const SizedBox(width: 11),
              Expanded(
                  child: _Kpi(
                      valeur: '${d['interventions']}',
                      label: 'Interventions',
                      couleur: AppColors.bleuClair)),
            ]),
            const SizedBox(height: 11),
            Row(children: [
              Expanded(
                  child: _Kpi(
                      valeur: '${d['tauxPanne']}%',
                      label: 'Taux de panne',
                      couleur: AppColors.rouge)),
              const SizedBox(width: 11),
              Expanded(
                  child: _Kpi(
                      valeur: '${d['couverture']}%',
                      label: 'Couverture moy.',
                      couleur: AppColors.vert)),
            ]),
            const SizedBox(height: 14),

            // Compteurs par zone (barres de progression)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.bordure),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Compteurs par zone',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte)),
                  const SizedBox(height: 14),
                  for (final z in zones) _BarreZone(zone: z),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Rapports recents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rapports récents',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texte)),
                TextButton(
                  onPressed: widget.ouvrirRapports,
                  child: Text('Tout voir',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaire)),
                ),
              ],
            ),
            ...recents.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _CarteRapportRecent(
                    rapport: r,
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => AdminReportDetailPage(rapport: r)))
                        .then((_) => _charger()),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String valeur;
  final String label;
  final Color? couleur;
  final bool fondBleu;
  const _Kpi({required this.valeur, required this.label, this.couleur, this.fondBleu = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: fondBleu ? AppColors.primaire : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: fondBleu ? null : Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valeur,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: fondBleu ? Colors.white : couleur)),
          const SizedBox(height: 5),
          Text(label,
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 11.5,
                  color: fondBleu
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.texteSecondaire)),
        ],
      ),
    );
  }
}

class _BarreZone extends StatelessWidget {
  final Map<String, dynamic> zone;
  const _BarreZone({required this.zone});

  Color get _couleur {
    final hex = (zone['couleur'] ?? '#15357a').toString().replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final pct = ((zone['pct'] as num?) ?? 0).toDouble() / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${zone['nom']}',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.texteLabel)),
            Text('${zone['compteurs']}',
                style: GoogleFonts.ibmPlexSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.texteLeger)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppColors.grisFond,
            valueColor: AlwaysStoppedAnimation(_couleur),
          ),
        ),
      ]),
    );
  }
}

/// Ligne "rapport recent" de la maquette : point colore + ref + technicien.
class _CarteRapportRecent extends StatelessWidget {
  final Rapport rapport;
  final VoidCallback onTap;
  const _CarteRapportRecent({required this.rapport, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final metaEtat = StatutMeta.de(rapport.etat);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: metaEtat.couleur, shape: BoxShape.circle)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rapport.reference,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texte)),
                  const SizedBox(height: 2),
                  Text('${rapport.technicienNom} · ${rapport.zone ?? '—'}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11, color: AppColors.texteLeger)),
                ],
              ),
            ),
            BadgeStatut(
                texte: StatutRapport.libelle(rapport.statut),
                couleur: StatutRapport.couleur(rapport.statut),
                fond: StatutRapport.fond(rapport.statut)),
          ]),
        ),
      ),
    );
  }
}
