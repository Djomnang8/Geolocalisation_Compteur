import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../models/compteur.dart';
import 'statut.dart';

/// Carte OpenStreetMap (gratuite, sans cle API) affichant les compteurs sous
/// forme de marqueurs colores selon leur statut. Remplace Google Maps.
class CarteCompteursOSM extends StatelessWidget {
  final List<Compteur> compteurs;
  final ll.LatLng centre;
  final double zoom;
  final ValueChanged<Compteur> onTapCompteur;

  const CarteCompteursOSM({
    super.key,
    required this.compteurs,
    required this.centre,
    required this.zoom,
    required this.onTapCompteur,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: centre, initialZoom: zoom),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.socadel.frontend_flutter',
        ),
        MarkerLayer(
          markers: [
            for (final c in compteurs)
              Marker(
                point: ll.LatLng(c.latitude, c.longitude),
                width: 34,
                height: 34,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => onTapCompteur(c),
                  child: Icon(Icons.location_on,
                      size: 34, color: StatutMeta.de(c.statut).couleur),
                ),
              ),
          ],
        ),
        // Attribution obligatoire (licence ODbL d'OpenStreetMap)
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution('© OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}
