import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/app_colors.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../widgets/carte_osm.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'admin_meter_form_page.dart';

/// Carte globale de Douala pour l'administrateur (maquette "ADMIN MAP") :
/// tous les compteurs de la ville, recherche, filtres par statut, carte
/// OpenStreetMap + legende, liste en dessous. Un appui sur un compteur ouvre
/// sa fiche (info + bouton "Modifier la fiche").
class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final _recherche = TextEditingController();
  List<Compteur> _tous = const [];
  String _filtre = 'TOUS';
  bool _chargement = true;
  String? _erreur;

  static const _centreDouala = ll.LatLng(4.0483, 9.7261);
  static const _zoomInitial = 12.6;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      final compteurs = await CompteurService.instance.lister();
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
          (c.quartier ?? '').toLowerCase().contains(q) ||
          (c.zone ?? '').toLowerCase().contains(q);
      return okStatut && okRecherche;
    }).toList();
  }

  /// Fiche du compteur (feuille) : informations + modifier la fiche.
  void _ouvrirFiche(Compteur c) {
    final meta = StatutMeta.de(c.statut);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.fond,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (contexteFeuille) => Padding(
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
                    Text(c.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte)),
                    const SizedBox(height: 2),
                    Text('${c.marque ?? '—'} · ${c.zone ?? '—'}',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 12, color: AppColors.texteLeger)),
                  ],
                ),
              ),
              BadgeStatut(
                  texte: StatutMeta.libelleComplet(c.statut, c.statutAutre),
                  couleur: meta.couleur,
                  fond: meta.fond),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.bordure),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adresse : ${c.quartier ?? '—'}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5, color: AppColors.texteLabel)),
                  const SizedBox(height: 6),
                  Text('GPS : ${c.latitude}, ${c.longitude}',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 12, color: AppColors.texteLabel)),
                  const SizedBox(height: 6),
                  Text('Attribué : ${c.technicienNom ?? 'Non attribué'}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5, color: AppColors.texteLabel)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            BoutonPrincipal(
              texte: 'Modifier la fiche',
              icone: Icons.edit_outlined,
              onPressed: () {
                Navigator.of(contexteFeuille).pop();
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (_) => AdminMeterFormPage(compteur: c)))
                    .then((_) => _charger());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final affiches = _filtres;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(children: [
            TextField(
              controller: _recherche,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.ibmPlexSans(fontSize: 13.5, color: AppColors.texte),
              decoration: decorationSocadel('Rechercher un compteur').copyWith(
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
        SizedBox(
          height: 320,
          child: Stack(children: [
            CarteCompteursOSM(
              compteurs: affiches,
              centre: _centreDouala,
              zoom: _zoomInitial,
              onTapCompteur: _ouvrirFiche,
            ),
            Positioned(left: 10, bottom: 10, child: _LegendeAdmin()),
          ]),
        ),
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
                      Text('${affiches.length} compteur(s) sur la ville de Douala',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texteLeger)),
                      const SizedBox(height: 10),
                      ...affiches.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: CarteCompteur(
                                compteur: c, onTap: () => _ouvrirFiche(c)),
                          )),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LegendeAdmin extends StatelessWidget {
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
          for (final meta in StatutMeta.liste)
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
