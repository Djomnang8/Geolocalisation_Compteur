import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_colors.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';

/// Statistiques par zone (maquette "ADMIN STATS") : nombre de compteurs par
/// zone (barres), taux de panne et interventions par zone, et export des
/// statistiques (fichier CSV lisible dans Excel).
/// Diagramme de séquence : "Tableau de bord et export (PDF/Excel)".
class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  List<Map<String, dynamic>> _zones = const [];
  bool _chargement = true;
  bool _export = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final tableau = await StatsService.instance.tableauDeBord();
      final zones =
          (tableau['zoneBars'] as List? ?? const []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() { _zones = zones; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  Color _couleur(String? hexadecimal) {
    final brut = (hexadecimal ?? '#15357a').replaceFirst('#', '');
    return Color(int.parse('FF$brut', radix: 16));
  }

  /// Export des statistiques : fichier CSV (ouvert par Excel / tableur).
  Future<void> _exporter() async {
    setState(() => _export = true);
    try {
      final tampon = StringBuffer()
        ..writeln('Zone;Compteurs;Interventions;Pannes;Taux de panne (%);Couverture (%)');
      for (final z in _zones) {
        tampon.writeln('${z['nom']};${z['compteurs']};${z['interventions'] ?? 0};'
            '${z['pannes'] ?? 0};${z['tauxPanne'] ?? 0};${z['couverture'] ?? 0}');
      }
      final dossier = await getTemporaryDirectory();
      final horodatage = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fichier = File(
          '${dossier.path}${Platform.pathSeparator}statistiques_zones_$horodatage.csv');
      // BOM UTF-8 : Excel affiche correctement les accents
      await fichier.writeAsBytes([0xEF, 0xBB, 0xBF, ...tampon.toString().codeUnits],
          flush: true);
      final resultat = await OpenFilex.open(fichier.path);
      if (!mounted) return;
      if (resultat.type == ResultType.done) {
        afficherToast(context, 'Statistiques exportées (CSV)');
      } else {
        afficherToast(context, 'Export enregistré : ${fichier.path}');
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _export = false);
    }
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
          Text('Statistiques par zone',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texte)),
          const SizedBox(height: 13),
          if (_erreur != null) ...[
            EncadreVide(texte: _erreur!),
            const SizedBox(height: 10),
          ],
          // Nombre de compteurs par zone (barres horizontales)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.bordure),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre de compteurs',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 12, color: AppColors.texteLeger)),
                const SizedBox(height: 14),
                if (_zones.isEmpty)
                  Text('Aucune donnée.',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12, color: AppColors.texteLeger)),
                ..._zones.map((z) {
                  final pct = ((z['pct'] as num?)?.toDouble() ?? 0) / 100;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${z['nom']}',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.texteLabel)),
                          Text('${z['compteurs']}',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.texte)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 9,
                          backgroundColor: AppColors.grisFond,
                          valueColor: AlwaysStoppedAnimation(
                              _couleur(z['couleur'] as String?)),
                        ),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Taux de panne / interventions par zone
          ..._zones.map((z) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.bordure),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: _couleur(z['couleur'] as String?),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${z['nom']}',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texte)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${z['tauxPanne'] ?? 0}%',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rouge)),
                        Text('taux panne',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 10, color: AppColors.texteLeger)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${z['interventions'] ?? 0}',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bleuClair)),
                        Text('interv.',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 10, color: AppColors.texteLeger)),
                      ],
                    ),
                  ]),
                ),
              )),
          const SizedBox(height: 6),
          // Export (CSV lisible dans Excel)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _export || _zones.isEmpty ? null : _exporter,
              icon: _export
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2.2))
                  : const Icon(Icons.download_outlined,
                      size: 17, color: AppColors.primaire),
              label: Text('Exporter (PDF / Excel)',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaire)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.bordureInput, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
