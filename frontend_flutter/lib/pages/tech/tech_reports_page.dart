import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/rapport.dart';
import '../../services/rapport_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';

/// Mes rapports (maquette "TECH REPORTS") : liste des rapports d'inspection
/// envoyés par le technicien connecté, avec le statut du traitement par
/// l'administrateur (en attente, validé, rejeté) et l'avis reçu.
class TechReportsPage extends StatefulWidget {
  const TechReportsPage({super.key});

  @override
  State<TechReportsPage> createState() => _TechReportsPageState();
}

class _TechReportsPageState extends State<TechReportsPage> {
  List<Rapport> _rapports = const [];
  int _page = 0; // pagination (10 rapports par page)
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final rapports = await RapportService.instance
          .lister(matricule: Session.instance.utilisateur!.matricule);
      if (mounted) {
        setState(() { _rapports = rapports; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  /// Detail du rapport envoye (feuille) : etat, anomalies, observations,
  /// pieces jointes et avis de l'administrateur.
  void _ouvrir(Rapport rapport) {
    final meta = StatutMeta.de(rapport.etat);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      isScrollControlled: true,
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFCCD4E0),
                        borderRadius: BorderRadius.circular(3))),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('R${rapport.id.toString().padLeft(2, '0')}',
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 11, color: AppColors.texteLeger)),
                      Text(rapport.reference,
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte)),
                    ],
                  ),
                ),
                BadgeStatut(
                    texte: StatutRapport.libelle(rapport.statut),
                    couleur: StatutRapport.couleur(rapport.statut),
                    fond: StatutRapport.fond(rapport.statut)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: meta.couleur,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      'État : ${StatutMeta.libelleComplet(rapport.etat, rapport.etatAutre)}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(width: 9),
                Text(rapport.date,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: AppColors.texteLeger)),
              ]),
              if (rapport.anomalies.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Anomalies signalées',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texte)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.rougeFond,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3C2C2)),
                  ),
                  child: Text(rapport.anomalies.join(' · '),
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: AppColors.rougeSombre)),
                ),
              ],
              const SizedBox(height: 16),
              Text('Observations',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texte)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bordure),
                ),
                child: Text(rapport.observations ?? '—',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12.5,
                        height: 1.6,
                        color: AppColors.texteLabel)),
              ),
              if ((rapport.commentaireAdmin ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppColors.fondBleuClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avis administrateur',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaire)),
                      const SizedBox(height: 5),
                      Text(rapport.commentaireAdmin!,
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12.5,
                              height: 1.5,
                              color: AppColors.texteLabel)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        children: [
          Text("Rapports d'inspection que vous avez envoyés.",
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13, color: AppColors.texteLeger)),
          const SizedBox(height: 14),
          if (_erreur != null) ...[
            EncadreVide(texte: _erreur!),
            const SizedBox(height: 10),
          ],
          if (_rapports.isEmpty && _erreur == null)
            const EncadreVide(
                texte: 'Aucun rapport envoyé pour le moment.\n'
                    'Inspectez un compteur depuis la carte pour créer un rapport.'),
          ...PaginationSocadel.tranche(_rapports, _page)
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child:
                        _CarteMonRapport(rapport: r, onTap: () => _ouvrir(r)),
                  )),
          PaginationSocadel(
              total: _rapports.length,
              page: _page,
              onChange: (p) => setState(() => _page = p)),
        ],
      ),
    );
  }
}

/// Carte d'un rapport envoye (maquette) : reference + statut du traitement,
/// puis etat constate + date.
class _CarteMonRapport extends StatelessWidget {
  final Rapport rapport;
  final VoidCallback onTap;
  const _CarteMonRapport({required this.rapport, required this.onTap});

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rapport.reference,
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texte)),
                  BadgeStatut(
                      texte: StatutRapport.libelle(rapport.statut),
                      couleur: StatutRapport.couleur(rapport.statut),
                      fond: StatutRapport.fond(rapport.statut)),
                ],
              ),
              const SizedBox(height: 9),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: metaEtat.fond,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                      StatutMeta.libelleComplet(rapport.etat, rapport.etatAutre),
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: metaEtat.couleur)),
                ),
                const SizedBox(width: 8),
                Text(rapport.date,
                    style: GoogleFonts.ibmPlexMono(
                        fontSize: 11, color: AppColors.texteLeger)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
