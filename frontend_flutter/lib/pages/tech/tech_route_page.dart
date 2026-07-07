import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../core/app_colors.dart';
import '../../core/session.dart';
import '../../models/compteur.dart';
import '../../services/compteur_service.dart';
import '../../services/itineraire_service.dart';
import '../../widgets/soc_widgets.dart';
import '../../widgets/statut.dart';
import 'tech_meter_page.dart';

/// Itinéraire du jour (maquette "TECH ROUTE") : carte OpenStreetMap avec les
/// arrêts numérotés dans l'ordre du trajet optimisé, puis liste des compteurs
/// attribués avec, pour chacun : la distance depuis la position du technicien,
/// le temps estimé en voiture et à pied, et le chemin à suivre sur la carte.
class TechRoutePage extends StatefulWidget {
  const TechRoutePage({super.key});

  @override
  State<TechRoutePage> createState() => _TechRoutePageState();
}

/// Un arrêt du trajet : compteur + itinéraire depuis la position du technicien.
class _Arret {
  final int numero;
  final Compteur compteur;
  Itineraire? itineraire; // rempli des que le calcul OSRM aboutit
  _Arret(this.numero, this.compteur);
}

class _TechRoutePageState extends State<TechRoutePage> {
  static const _agenceKoumassi = ll.LatLng(4.0483, 9.7261);

  final _carte = MapController();
  ll.LatLng _position = _agenceKoumassi;
  bool _positionReelle = false;
  List<_Arret> _arrets = const [];
  _Arret? _selection; // arret dont le chemin est trace sur la carte
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  /// Position GPS du technicien ; a defaut, l'agence de Koumassi.
  Future<void> _capturerPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.high))
          .timeout(const Duration(seconds: 8));
      _position = ll.LatLng(position.latitude, position.longitude);
      _positionReelle = true;
    } catch (_) {
      // Position indisponible : l'agence de Koumassi sert de point de depart.
    }
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    try {
      await _capturerPosition();
      final compteurs = await CompteurService.instance
          .lister(technicien: Session.instance.utilisateur!.matricule);

      // Trajet optimise : ordre du plus proche voisin depuis la position.
      final restants = [...compteurs];
      final ordonnes = <Compteur>[];
      var point = _position;
      while (restants.isNotEmpty) {
        restants.sort((a, b) => ItineraireService.haversineKm(
                point, ll.LatLng(a.latitude, a.longitude))
            .compareTo(ItineraireService.haversineKm(
                point, ll.LatLng(b.latitude, b.longitude))));
        final suivant = restants.removeAt(0);
        ordonnes.add(suivant);
        point = ll.LatLng(suivant.latitude, suivant.longitude);
      }
      final arrets = [
        for (var i = 0; i < ordonnes.length; i++) _Arret(i + 1, ordonnes[i]),
      ];
      if (mounted) {
        setState(() {
          _arrets = arrets;
          _selection = null;
          _erreur = null;
          _chargement = false;
        });
      }
      // Distances et durees reelles par la route (OSRM), en parallele.
      await Future.wait(arrets.map((a) async {
        final itineraire = await ItineraireService.instance.calculer(
            _position, ll.LatLng(a.compteur.latitude, a.compteur.longitude));
        if (mounted) setState(() => a.itineraire = itineraire);
      }));
    } catch (e) {
      if (mounted) setState(() { _erreur = e.toString(); _chargement = false; });
    }
  }

  /// Trace le chemin vers cet arret sur la carte et cadre la vue dessus.
  void _voirChemin(_Arret arret) {
    setState(() => _selection = arret);
    final trace = arret.itineraire?.trace ??
        [_position, ll.LatLng(arret.compteur.latitude, arret.compteur.longitude)];
    _carte.fitCamera(CameraFit.coordinates(
        coordinates: trace, padding: const EdgeInsets.all(36)));
  }

  void _ouvrirFiche(Compteur compteur) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TechMeterPage(compteur: compteur)))
        .then((_) => _charger());
  }

  /// Feuille de detail d'un arret : distance, temps voiture / a pied, actions.
  void _ouvrirArret(_Arret arret) {
    final itineraire = arret.itineraire;
    final meta = StatutMeta.de(arret.compteur.statut);
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
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: AppColors.primaire, shape: BoxShape.circle),
                child: Center(
                  child: Text('${arret.numero}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(arret.compteur.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texte)),
                    Text(arret.compteur.quartier ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5, color: AppColors.texteLeger)),
                  ],
                ),
              ),
              BadgeStatut(
                  texte: StatutMeta.libelleComplet(
                      arret.compteur.statut, arret.compteur.statutAutre),
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
              child: itineraire == null
                  ? Text('Calcul du chemin en cours…',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 12.5, color: AppColors.texteLeger))
                  : Column(children: [
                      _ligneTrajet(Icons.straighten, 'Distance par la route',
                          itineraire.distanceTexte),
                      const SizedBox(height: 9),
                      _ligneTrajet(Icons.directions_car_outlined, 'En voiture',
                          Itineraire.formaterDuree(itineraire.dureeVoitureMin)),
                      const SizedBox(height: 9),
                      _ligneTrajet(Icons.directions_walk, 'À pied',
                          Itineraire.formaterDuree(itineraire.dureePiedMin)),
                      if (itineraire.estime) ...[
                        const SizedBox(height: 9),
                        Text(
                            'Estimation à vol d\'oiseau (service d\'itinéraire injoignable).',
                            style: GoogleFonts.ibmPlexSans(
                                fontSize: 10.5, color: AppColors.texteLeger)),
                      ],
                    ]),
            ),
            const SizedBox(height: 14),
            BoutonPrincipal(
              texte: 'Voir le chemin sur la carte',
              icone: Icons.route_outlined,
              onPressed: () {
                Navigator.of(contexteFeuille).pop();
                _voirChemin(arret);
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(contexteFeuille).pop();
                  _ouvrirFiche(arret.compteur);
                },
                icon: const Icon(Icons.speed, size: 18, color: AppColors.primaire),
                label: Text('Ouvrir la fiche compteur',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaire)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.bordureInput, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneTrajet(IconData icone, String label, String valeur) {
    return Row(children: [
      Icon(icone, size: 17, color: AppColors.primaire),
      const SizedBox(width: 9),
      Expanded(
        child: Text(label,
            style: GoogleFonts.ibmPlexSans(
                fontSize: 12.5, color: AppColors.texteLeger)),
      ),
      Text(valeur,
          style: GoogleFonts.ibmPlexMono(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.texte)),
    ]);
  }

  /// Distance totale du trajet optimise (somme des segments).
  double get _distanceTotaleKm {
    double total = 0;
    var point = _position;
    for (final arret in _arrets) {
      final cible = ll.LatLng(arret.compteur.latitude, arret.compteur.longitude);
      total += ItineraireService.haversineKm(point, cible) * 1.3;
      point = cible;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    final selection = _selection;
    final traceSelection = selection == null
        ? null
        : (selection.itineraire?.trace ??
            [
              _position,
              ll.LatLng(selection.compteur.latitude,
                  selection.compteur.longitude),
            ]);
    return Column(
      children: [
        // Carte du trajet : arrets numerotes + chemin trace
        SizedBox(
          height: 230,
          child: FlutterMap(
            mapController: _carte,
            options: MapOptions(initialCenter: _position, initialZoom: 12.4),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.socadel.frontend_flutter',
              ),
              // Trajet optimise complet, en pointilles (comme la maquette)
              PolylineLayer(polylines: [
                Polyline(
                  points: [
                    _position,
                    ..._arrets.map((a) =>
                        ll.LatLng(a.compteur.latitude, a.compteur.longitude)),
                  ],
                  color: AppColors.primaire.withValues(alpha: 0.85),
                  strokeWidth: 3,
                  pattern: const StrokePattern.dotted(),
                ),
                // Chemin reel (OSRM) vers l'arret selectionne
                if (traceSelection != null)
                  Polyline(
                    points: traceSelection,
                    color: AppColors.vert,
                    strokeWidth: 4.5,
                  ),
              ]),
              MarkerLayer(markers: [
                // Position du technicien
                Marker(
                  point: _position,
                  width: 22,
                  height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bleuClair,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
                for (final arret in _arrets)
                  Marker(
                    point: ll.LatLng(
                        arret.compteur.latitude, arret.compteur.longitude),
                    width: 27,
                    height: 27,
                    child: GestureDetector(
                      onTap: () => _ouvrirArret(arret),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _selection == arret
                              ? AppColors.vert
                              : AppColors.primaire,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                        child: Center(
                          child: Text('${arret.numero}',
                              style: GoogleFonts.ibmPlexSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
              ]),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomRight,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _charger,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
              children: [
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.vertFond,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Trajet optimisé',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.vert)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${_arrets.length} arrêt(s) · ~${_distanceTotaleKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 12.5, color: AppColors.texteLeger)),
                  ),
                ]),
                if (!_positionReelle) ...[
                  const SizedBox(height: 8),
                  Text(
                      'Position GPS indisponible : départ depuis l\'agence de Koumassi.',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 11, color: AppColors.texteLeger)),
                ],
                const SizedBox(height: 12),
                if (_erreur != null) ...[
                  EncadreVide(texte: _erreur!),
                  const SizedBox(height: 10),
                ],
                if (_arrets.isEmpty && _erreur == null)
                  const EncadreVide(
                      texte: 'Aucun compteur attribué pour le moment.\n'
                          "L'itinéraire se construira après les attributions."),
                ..._arrets.map((arret) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _CarteArret(
                        arret: arret,
                        selectionne: _selection == arret,
                        onTap: () => _ouvrirArret(arret),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Carte d'un arret du trajet : numero, reference, adresse, statut, puis
/// distance et temps estimes en voiture et a pied.
class _CarteArret extends StatelessWidget {
  final _Arret arret;
  final bool selectionne;
  final VoidCallback onTap;

  const _CarteArret({
    required this.arret,
    required this.selectionne,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = StatutMeta.de(arret.compteur.statut);
    final itineraire = arret.itineraire;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(
                color: selectionne ? AppColors.vert : AppColors.bordure,
                width: selectionne ? 1.8 : 1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: AppColors.primaire, shape: BoxShape.circle),
                child: Center(
                  child: Text('${arret.numero}',
                      style: GoogleFonts.ibmPlexSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(arret.compteur.reference,
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.texte)),
                    const SizedBox(height: 2),
                    Text(arret.compteur.quartier ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ibmPlexSans(
                            fontSize: 11.5, color: AppColors.texteLeger)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BadgeStatut(
                  texte: StatutMeta.libelleComplet(
                      arret.compteur.statut, arret.compteur.statutAutre),
                  couleur: meta.couleur,
                  fond: meta.fond),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.fond,
                borderRadius: BorderRadius.circular(9),
              ),
              child: itineraire == null
                  ? Row(children: [
                      const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 9),
                      Text('Calcul de la distance et du temps de trajet…',
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 11, color: AppColors.texteLeger)),
                    ])
                  : Row(children: [
                      const Icon(Icons.near_me_outlined,
                          size: 14, color: AppColors.primaire),
                      const SizedBox(width: 5),
                      Text(itineraire.distanceTexte,
                          style: GoogleFonts.ibmPlexMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texte)),
                      const Spacer(),
                      const Icon(Icons.directions_car_outlined,
                          size: 14, color: AppColors.texteLeger),
                      const SizedBox(width: 4),
                      Text(Itineraire.formaterDuree(itineraire.dureeVoitureMin),
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texteLabel)),
                      const SizedBox(width: 12),
                      const Icon(Icons.directions_walk,
                          size: 14, color: AppColors.texteLeger),
                      const SizedBox(width: 4),
                      Text(Itineraire.formaterDuree(itineraire.dureePiedMin),
                          style: GoogleFonts.ibmPlexSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.texteLabel)),
                    ]),
            ),
          ]),
        ),
      ),
    );
  }
}
