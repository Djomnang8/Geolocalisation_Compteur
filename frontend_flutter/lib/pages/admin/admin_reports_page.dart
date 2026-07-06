import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../models/rapport.dart';
import '../../services/rapport_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'admin_report_detail_page.dart';

/// Réception des rapports d'inspection (maquette "ADMIN REPORTS") :
/// filtres Tous / En attente / Validés / Rejetés, puis liste des rapports
/// (référence, statut, technicien, zone, état, date).
/// Diagramme de séquence : "Consultation et validation d'un rapport".
class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  List<Rapport> _tous = const [];
  String _filtre = 'TOUS';
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final rapports = await RapportService.instance.lister();
      if (mounted) {
        setState(() { _tous = rapports; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  List<Rapport> get _filtres => _filtre == 'TOUS'
      ? _tous
      : _tous.where((r) => r.statut == _filtre).toList();

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return _chargement
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _charger,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
              children: [
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final (code, libelle) in [
                        ('TOUS', 'Tous'),
                        ('EN_ATTENTE', 'En attente'),
                        ('VALIDE', 'Validés'),
                        ('REJETE', 'Rejetés'),
                      ]) ...[
                        PuceFiltre(
                            label: libelle,
                            active: _filtre == code,
                            couleur: _filtre == code
                                ? AppColors.primaire
                                : const Color(0xFF5A6577),
                            onTap: () => setState(() => _filtre = code)),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (_erreur != null) ...[
                  EncadreVide(texte: _erreur!),
                  const SizedBox(height: 10),
                ],
                if (affiches.isEmpty && _erreur == null)
                  const EncadreVide(texte: 'Aucun rapport pour ce filtre.'),
                ...affiches.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CarteRapport(
                        rapport: r,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (_) =>
                                    AdminReportDetailPage(rapport: r)))
                            .then((_) => _charger()),
                      ),
                    )),
              ],
            ),
          );
  }
}

class _CarteRapport extends StatelessWidget {
  final Rapport rapport;
  final VoidCallback onTap;
  const _CarteRapport({required this.rapport, required this.onTap});

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
              const SizedBox(height: 7),
              Text('${rapport.technicienNom} · ${rapport.zone ?? '—'}',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 11.5, color: AppColors.texteLeger)),
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
