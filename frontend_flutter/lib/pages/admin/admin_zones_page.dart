import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../services/stats_service.dart';
import '../../widgets/soc_widgets.dart';

/// Zones de service (maquette "ADMIN ZONES") : bandeau cartographique,
/// barre de recherche, liste des zones (compteurs, interventions, pannes,
/// couverture) avec modification et suppression, et bouton « Tracer une
/// nouvelle zone ».
class AdminZonesPage extends StatefulWidget {
  const AdminZonesPage({super.key});

  @override
  State<AdminZonesPage> createState() => _AdminZonesPageState();
}

class _AdminZonesPageState extends State<AdminZonesPage> {
  final _recherche = TextEditingController();
  List<Map<String, dynamic>> _zones = const [];
  int _page = 0; // pagination (10 zones par page)
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

  /// Zones filtrees par la barre de recherche (nom de zone).
  List<Map<String, dynamic>> get _filtres {
    final q = _recherche.text.trim().toLowerCase();
    if (q.isEmpty) return _zones;
    return _zones
        .where((z) => '${z['nom']}'.toLowerCase().contains(q))
        .toList();
  }

  Color _couleur(String? hexadecimal) {
    final brut = (hexadecimal ?? '#15357a').replaceFirst('#', '');
    return Color(int.parse('FF$brut', radix: 16));
  }

  /// Dialogue de zone, partage entre creation (existante == null) et
  /// modification (existante != null) : nom + couleur + couverture.
  Future<void> _dialogueZone({Map<String, dynamic>? existante}) async {
    final edition = existante != null;
    final nom = TextEditingController(text: edition ? '${existante['nom']}' : '');
    final couverture = TextEditingController(
        text: edition ? '${existante['couverture'] ?? 0}' : '0');
    var couleur = edition
        ? '${existante['couleur'] ?? _palette.first}'
        : _palette.first;
    // La palette inclut la couleur actuelle de la zone meme si elle en sort.
    final palette = {couleur, ..._palette}.toList();

    final valider = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => StatefulBuilder(
        builder: (context, setStateDialogue) => AlertDialog(
          backgroundColor: AppColors.fond,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(edition ? 'Modifier la zone' : 'Tracer une nouvelle zone',
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
                  label: 'Couverture (%)',
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
                  for (final teinte in palette)
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
              child: Text(edition ? 'Enregistrer' : 'Créer la zone',
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (valider != true || !mounted) return;
    try {
      final couvertureNum = int.tryParse(couverture.text.trim()) ?? 0;
      if (edition) {
        await StatsService.instance.modifierZone(
          (existante['id'] as num).toInt(),
          nom: nom.text.trim(),
          couleur: couleur,
          couverture: couvertureNum,
        );
      } else {
        await StatsService.instance.creerZone(
          nom: nom.text.trim(),
          couleur: couleur,
          couverture: couvertureNum,
        );
      }
      if (!mounted) return;
      afficherToast(context,
          edition ? 'Zone « ${nom.text.trim()} » modifiée' : 'Zone « ${nom.text.trim()} » créée');
      await _charger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  /// Confirmation puis suppression d'une zone.
  Future<void> _supprimer(Map<String, dynamic> zone) async {
    final compteurs = (zone['compteurs'] as num?)?.toInt() ?? 0;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexteDialogue) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer la zone ?',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.texte)),
        content: Text(
            compteurs == 0
                ? 'La zone « ${zone['nom']} » sera définitivement supprimée.'
                : 'La zone « ${zone['nom']} » sera supprimée. Ses $compteurs compteur(s) '
                    'ne seront pas supprimés : ils repasseront « sans zone ».',
            style: GoogleFonts.ibmPlexSans(
                fontSize: 13, color: AppColors.texteSecondaire, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(contexteDialogue).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(contexteDialogue).pop(true),
            child: Text('Supprimer',
                style: GoogleFonts.ibmPlexSans(
                    fontWeight: FontWeight.w600, color: AppColors.rougeSombre)),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    try {
      await StatsService.instance.supprimerZone((zone['id'] as num).toInt());
      if (!mounted) return;
      afficherToast(context, 'Zone « ${zone['nom']} » supprimée');
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
                const SizedBox(height: 12),
                // Barre de recherche par nom de zone
                TextField(
                  controller: _recherche,
                  onChanged: (_) => setState(() => _page = 0),
                  style: GoogleFonts.ibmPlexSans(
                      fontSize: 13.5, color: AppColors.texte),
                  decoration: decorationSocadel('Rechercher une zone…').copyWith(
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: AppColors.texteLeger),
                    suffixIcon: _recherche.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: AppColors.texteLeger),
                            onPressed: () {
                              _recherche.clear();
                              setState(() => _page = 0);
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 13),
                if (_erreur != null) ...[
                  EncadreVide(texte: _erreur!),
                  const SizedBox(height: 10),
                ],
                if (_filtres.isEmpty && _erreur == null)
                  EncadreVide(
                      texte: _recherche.text.isEmpty
                          ? 'Aucune zone enregistrée.'
                          : 'Aucune zone ne correspond à « ${_recherche.text.trim()} ».'),
                ...PaginationSocadel.tranche(_filtres, _page).map((z) {
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
                        const SizedBox(height: 11),
                        // Actions : modifier / supprimer la zone
                        Container(
                          padding: const EdgeInsets.only(top: 11),
                          decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: AppColors.separateur))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _dialogueZone(existante: z),
                                icon: const Icon(Icons.edit_outlined,
                                    size: 14, color: AppColors.primaire),
                                label: Text('Modifier',
                                    style: GoogleFonts.ibmPlexSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaire)),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  side: const BorderSide(
                                      color: AppColors.bordureInput),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _supprimer(z),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 6),
                                  side: const BorderSide(color: Color(0xFFF3C2C2)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    size: 15, color: AppColors.rougeSombre),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  );
                }),
                PaginationSocadel(
                    total: _filtres.length,
                    page: _page,
                    onChange: (p) => setState(() => _page = p)),
                const SizedBox(height: 6),
                // Bouton pointille "Tracer une nouvelle zone"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _dialogueZone(),
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
