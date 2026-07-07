import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';

/// Suivi des déplacements (maquette "ADMIN TRACKING") : pour chaque
/// technicien, dernière position connue, temps de trajet, distance parcourue
/// et compteurs inspectés sur sa dernière journée d'activité.
/// Diagramme de séquence : "Enregistrement de la position GPS de visite".
class AdminTrackingPage extends StatefulWidget {
  const AdminTrackingPage({super.key});

  @override
  State<AdminTrackingPage> createState() => _AdminTrackingPageState();
}

class _AdminTrackingPageState extends State<AdminTrackingPage> {
  List<Map<String, dynamic>> _suivi = const [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final suivi = await StatsService.instance.suivi();
      if (mounted) {
        setState(() { _suivi = suivi; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  String _initiales(String nom) {
    final parties = nom.trim().split(RegExp(r'\s+'));
    return parties.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
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
          Text('Temps de déplacement et activité des techniciens.',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 12.5, color: AppColors.texteSecondaire)),
          const SizedBox(height: 14),
          if (_erreur != null) ...[
            EncadreVide(texte: _erreur!),
            const SizedBox(height: 10),
          ],
          if (_suivi.isEmpty && _erreur == null)
            const EncadreVide(texte: 'Aucun technicien enregistré.'),
          ..._suivi.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.bordure),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: AppColors.fondBleuClair,
                            shape: BoxShape.circle),
                        child: Center(
                          child: Text(_initiales('${t['nom']}'),
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaire)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t['nom']}',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.texte)),
                            const SizedBox(height: 2),
                            Text('Dernière position : ${t['dernierePosition']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 11, color: AppColors.texteLeger)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(color: AppColors.separateur)),
                      ),
                      child: Row(children: [
                        _statistique('Temps trajet', '${t['tempsTrajet']}'),
                        const SizedBox(width: 16),
                        _statistique('Distance', '${t['distanceKm']} km'),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inspectés',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 10.5,
                                    color: AppColors.texteLeger)),
                            const SizedBox(height: 2),
                            Text('${t['inspectes']}/${t['total']}',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.vert)),
                          ],
                        ),
                        const Spacer(),
                      ]),
                    ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }

  Widget _statistique(String label, String valeur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 10.5, color: AppColors.texteLeger)),
        const SizedBox(height: 2),
        Text(valeur,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.texte)),
      ],
    );
  }
}
