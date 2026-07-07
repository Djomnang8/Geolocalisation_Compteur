import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';

/// Zones de service (maquette "ADMIN ZONES") : bandeau cartographique,
/// liste des zones (compteurs, interventions, pannes, couverture) et
/// bouton « Tracer une nouvelle zone ».
class AdminZonesPage extends StatefulWidget {
  const AdminZonesPage({super.key});

  @override
  State<AdminZonesPage> createState() => _AdminZonesPageState();
}

class _AdminZonesPageState extends State<AdminZonesPage> {
  List<Map<String, dynamic>> _zones = const [];
  bool _chargement = true;
  String? _erreur;

  static const _palette = [
    '#15357a', '#1763c7', '#1f9d55', '#d98a00', '#7a4fb5',
    '#0f8a8a', '#c2452e', '#5a6b7a',
  ];

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

  /// Dialogue « Tracer une nouvelle zone » : nom + couleur + couverture.
  Future<void> _nouvelleZone() async {
    final nom = TextEditingController();
    final couverture = TextEditingController(text: '0');
    var couleur = _palette.first;
    final creer = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => StatefulBuilder(
        builder: (context, setStateDialogue) => AlertDialog(
          backgroundColor: AppColors.fond,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Tracer une nouvelle zone',
              style: GoogleFonts.ibmPlexSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texte)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChampSocadel(
                  label: 'Nom de la zone',
                  controleur: nom,
                  placeholder: 'Ex. : Bonabéri'),
              const SizedBox(height: 13),
              ChampSocadel(
                  label: 'Couverture initiale (%)',
                  controleur: couverture,
                  clavier: TextInputType.number),
              const SizedBox(height: 13),
              Text('Couleur de la zone',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texteLabel)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final teinte in _palette)
                    GestureDetector(
                      onTap: () => setStateDialogue(() => couleur = teinte),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _couleur(teinte),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: couleur == teinte
                                  ? AppColors.texte
                                  : Colors.transparent,
                              width: 2.5),
                        ),
                        child: couleur == teinte
                            ? const Icon(Icons.check,
                                size: 15, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexteDialogue).pop(false),
              child: Text('Annuler',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5, color: AppColors.texteLeger)),
            ),
            TextButton(
              onPressed: () => Navigator.of(contexteDialogue).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaire,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Créer la zone',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (creer != true || !mounted) return;
    try {
      await StatsService.instance.creerZone(
        nom: nom.text.trim(),
        couleur: couleur,
        couverture: int.tryParse(couverture.text.trim()) ?? 0,
      );
      if (!mounted) return;
      afficherToast(context, 'Zone « ${nom.text.trim()} » créée');
      await _charger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
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
        padding: EdgeInsets.zero,
        children: [
          // Bandeau cartographique decoratif (identique a la maquette)
          SizedBox(
            height: 200,
            child: Stack(children: [
              Container(color: const Color(0xFFE6EDF0)),
              Positioned(
                left: -50,
                top: -60,
                child: Transform.rotate(
                  angle: 0.35,
                  child: Container(
                    width: 220,
                    height: 400,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB6D6E2), Color(0xFFA2CDDE)],
                      ),
                    ),
                  ),
                ),
              ),
              for (final (gauche, haut, largeur, hauteur, teinte)
                  in <(double, double, double, double, Color)>[
                (0.18, 0.42, 120, 90, AppColors.primaire),
                (0.48, 0.14, 100, 80, AppColors.vert),
                (0.62, 0.48, 110, 78, AppColors.orange),
              ])
                Positioned(
                  left: MediaQuery.of(context).size.width * gauche,
                  top: 200 * haut,
                  child: Container(
                    width: largeur,
                    height: hauteur,
                    decoration: BoxDecoration(
                      color: teinte.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: teinte, width: 2),
                    ),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Zones de service',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte)),
                    Text('Agence Koumassi',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5, color: AppColors.texteLeger)),
                  ],
                ),
                const SizedBox(height: 13),
                if (_erreur != null) ...[
                  EncadreVide(texte: _erreur!),
                  const SizedBox(height: 10),
                ],
                if (_zones.isEmpty && _erreur == null)
                  const EncadreVide(texte: 'Aucune zone enregistrée.'),
                ..._zones.map((z) {
                  final couleur = _couleur(z['couleur'] as String?);
                  final couverture = (z['couverture'] as num?)?.toInt() ?? 0;
                  return Padding(
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
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: couleur,
                                  borderRadius: BorderRadius.circular(4))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('${z['nom']}',
                                style: GoogleFonts.ibmPlexSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.texte)),
                          ),
                          Text('${z['compteurs']} compteurs',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 11.5, color: AppColors.texteLeger)),
                        ]),
                        const SizedBox(height: 11),
                        Row(children: [
                          _statistique('Interventions', '${z['interventions'] ?? 0}',
                              AppColors.texte),
                          const SizedBox(width: 18),
                          _statistique(
                              'Pannes', '${z['pannes'] ?? 0}', AppColors.rouge),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Couverture',
                                    style: GoogleFonts.ibmPlexSans(
                                        fontSize: 10.5,
                                        color: AppColors.texteLeger)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: couverture / 100,
                                        minHeight: 7,
                                        backgroundColor: AppColors.grisFond,
                                        valueColor:
                                            AlwaysStoppedAnimation(couleur),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$couverture%',
                                      style: GoogleFonts.ibmPlexSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.texte)),
                                ]),
                              ],
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 6),
                // Bouton pointille "Tracer une nouvelle zone"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _nouvelleZone,
                    icon: const Icon(Icons.layers_outlined,
                        size: 18, color: AppColors.primaire),
                    label: Text('Tracer une nouvelle zone',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaire)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFB9C3D2), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statistique(String label, String valeur, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 10.5, color: AppColors.texteLeger)),
        const SizedBox(height: 2),
        Text(valeur,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 15, fontWeight: FontWeight.w700, color: couleur)),
      ],
    );
  }
}
