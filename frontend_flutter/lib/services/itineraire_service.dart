import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as ll;

/// Itineraire calcule entre la position du technicien et un compteur :
/// distance par la route, duree en voiture, duree a pied et trace du chemin.
class Itineraire {
  final double distanceKm;
  final int dureeVoitureMin;
  final int dureePiedMin;
  final List<ll.LatLng> trace;

  /// true si l'itineraire est estime a vol d'oiseau (service de routage
  /// injoignable : pas de reseau, par exemple).
  final bool estime;

  const Itineraire({
    required this.distanceKm,
    required this.dureeVoitureMin,
    required this.dureePiedMin,
    required this.trace,
    this.estime = false,
  });

  String get distanceTexte => distanceKm < 1
      ? '${(distanceKm * 1000).round()} m'
      : '${distanceKm.toStringAsFixed(1)} km';

  static String formaterDuree(int minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}';
  }
}

/// Calcul d'itineraires avec le service public OSRM (OpenStreetMap,
/// gratuit et sans cle API). En cas d'echec reseau, l'itineraire est
/// estime a vol d'oiseau (distance haversine majoree de 30 %).
class ItineraireService {
  ItineraireService._();
  static final ItineraireService instance = ItineraireService._();

  static const _vitessePietonKmH = 4.5; // marche urbaine
  static const _vitesseVoitureKmH = 20.0; // circulation de Douala

  final Map<String, Itineraire> _cache = {};

  /// Itineraire routier entre deux points (service OSRM `driving`).
  Future<Itineraire> calculer(ll.LatLng depart, ll.LatLng arrivee) async {
    final cle = '${depart.latitude},${depart.longitude}'
        '->${arrivee.latitude},${arrivee.longitude}';
    final enCache = _cache[cle];
    if (enCache != null) return enCache;

    try {
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${depart.longitude},${depart.latitude};'
          '${arrivee.longitude},${arrivee.latitude}'
          '?overview=full&geometries=geojson');
      final reponse = await http.get(url).timeout(const Duration(seconds: 8));
      if (reponse.statusCode == 200) {
        final donnees = jsonDecode(reponse.body) as Map<String, dynamic>;
        final routes = donnees['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceKm = (route['distance'] as num).toDouble() / 1000.0;
          final dureeVoitureMin =
              ((route['duration'] as num).toDouble() / 60.0).ceil();
          final coordonnees =
              (route['geometry']['coordinates'] as List).cast<List>();
          final resultat = Itineraire(
            distanceKm: distanceKm,
            dureeVoitureMin: dureeVoitureMin,
            dureePiedMin: (distanceKm / _vitessePietonKmH * 60).ceil(),
            trace: coordonnees
                .map((c) => ll.LatLng(
                    (c[1] as num).toDouble(), (c[0] as num).toDouble()))
                .toList(),
          );
          _cache[cle] = resultat;
          return resultat;
        }
      }
    } catch (_) {
      // Service injoignable : estimation a vol d'oiseau ci-dessous.
    }
    final resultat = _estimation(depart, arrivee);
    _cache[cle] = resultat;
    return resultat;
  }

  /// Estimation sans reseau : distance haversine majoree de 30 %
  /// (approximation du reseau routier) et trace en ligne droite.
  Itineraire _estimation(ll.LatLng depart, ll.LatLng arrivee) {
    final distanceKm = haversineKm(depart, arrivee) * 1.3;
    return Itineraire(
      distanceKm: distanceKm,
      dureeVoitureMin: (distanceKm / _vitesseVoitureKmH * 60).ceil(),
      dureePiedMin: (distanceKm / _vitessePietonKmH * 60).ceil(),
      trace: [depart, arrivee],
      estime: true,
    );
  }

  /// Distance a vol d'oiseau entre deux points GPS (formule de haversine).
  static double haversineKm(ll.LatLng a, ll.LatLng b) {
    const rayonTerre = 6371.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * rayonTerre * math.asin(math.sqrt(h));
  }

  static double _radians(double degres) => degres * math.pi / 180.0;
}
