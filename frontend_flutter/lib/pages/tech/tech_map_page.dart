import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../widgets/carte_osm.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'tech_meter_page.dart';

/// Carte des compteurs attribués au technicien (maquette "TECH MAP") :
/// recherche par n° ou adresse, filtres par statut, carte OpenStreetMap avec
/// marqueurs colorés + légende, puis liste des compteurs affichés.
/// Diagrammes de séquence : "Consultation des compteurs sur la carte",
/// "Recherche d'un compteur par numéro".
class TechMapPage extends StatefulWidget {
  const TechMapPage({super.key});

  @override
  State<TechMapPage> createState() => _TechMapPageState();
}

class _TechMapPageState extends State<TechMapPage> {
  final _recherche = TextEditingController();
  List<Compteur> _tous = const [];
  String _filtre = 'TOUS';
  bool _chargement = true;
  String? _erreur;

  static const _centreDouala = ll.LatLng(4.0483, 9.7261); // Douala, agence de Koumassi
  static const _zoomInitial = 13.2;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final compteurs = await CompteurService.instance
          .lister(technicien: Session.instance.utilisateur!.matricule);
      if (mounted) {
        setState(() { _tous = compteurs; _erreur = null; _chargement = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  List<Compteur> get _filtres {
    final q = _recherche.text.trim().toLowerCase();
    return _tous.where((c) {
      final okStatut = _filtre == 'TOUS' || c.statut == _filtre;
      final okRecherche = q.isEmpty ||
          c.reference.toLowerCase().contains(q) ||
          (c.quartier ?? '').toLowerCase().contains(q);
      return okStatut && okRecherche;
    }).toList();
  }

  void _ouvrir(Compteur compteur) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TechMeterPage(compteur: compteur)))
        .then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return Column(
      children: [
        // Recherche + filtres
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(children: [
            TextField(
              controller: _recherche,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
              decoration: decorationSocadel('Rechercher par n° ou adresse').copyWith(
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: AppColors.texteLeger),
                fillColor: AppColors.fond,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  PuceFiltre(
                      label: 'Tous',
                      nombre: _tous.length,
                      active: _filtre == 'TOUS',
                      couleur: AppColors.primaire,
                      onTap: () => setState(() => _filtre = 'TOUS')),
                  for (final meta in StatutMeta.liste) ...[
                    const SizedBox(width: 7),
                    PuceFiltre(
                        label: meta.libelle,
                        nombre: _tous.where((c) => c.statut == meta.code).length,
                        active: _filtre == meta.code,
                        couleur: meta.couleur,
                        onTap: () => setState(() => _filtre = meta.code)),
                  ],
                ],
              ),
            ),
          ]),
        ),
        // Carte OpenStreetMap + legende
        SizedBox(
          height: 300,
          child: Stack(children: [
            CarteCompteursOSM(
              compteurs: affiches,
              centre: _centreDouala,
              zoom: _zoomInitial,
              onTapCompteur: _ouvrir,
            ),
            Positioned(left: 10, bottom: 10, child: _Legende()),
          ]),
        ),
        // Liste des compteurs affiches
        Expanded(
          child: _chargement
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                    children: [
                      if (_erreur != null) ...[
                        EncadreVide(texte: _erreur!),
                        const SizedBox(height: 10),
                      ],
                      Text('${affiches.length} compteur(s) affiché(s)',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texteLeger)),
                      const SizedBox(height: 10),
                      ...affiches.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: CarteCompteur(compteur: c, onTap: () => _ouvrir(c)),
                          )),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Legende des statuts affichee sur la carte (identique a la maquette).
class _Legende extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final meta in [
            StatutMeta.de('ACTIF'),
            StatutMeta.de('MAINTENANCE'),
            StatutMeta.de('PANNE'),
            StatutMeta.de('NON_INSPECTE'),
            StatutMeta.de('AUTRE'),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration:
                        BoxDecoration(color: meta.couleur, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                Text(meta.libelle,
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.texteLabel)),
              ]),
            ),
        ],
      ),
    );
  }
}
