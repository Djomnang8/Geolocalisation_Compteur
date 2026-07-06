import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

/// Configuration de l'acces reseau.
///
/// L'application mobile communique UNIQUEMENT avec l'API Frontend
/// (passerelle BFF, port 8080). C'est l'API Frontend qui transmet ensuite
/// les demandes a l'API Backend (port 8081), laquelle s'appuie sur la
/// couche de services metier puis sur la base MySQL (architecture imposee
/// par le cahier des charges).
///
/// DETECTION AUTOMATIQUE DE L'ADRESSE IP :
/// plusieurs adresses IP sont enregistrees dans [serveursEnregistres].
/// Au premier appel reseau (et apres chaque echec), l'application teste
/// chaque adresse via GET /api/auth/ping et retient la premiere qui repond.
/// Ainsi, quand on change de Wi-Fi, l'application retrouve seule le serveur.
class ApiConfig {
  ApiConfig._();

  static const int _port = 8080;

  /// Adresses IP du PC serveur, une par reseau Wi-Fi utilise.
  /// AJOUTEZ ICI l'adresse IPv4 du PC sur chaque nouveau reseau
  /// (commande Windows : ipconfig -> "Carte réseau sans fil Wi-Fi").
  static const List<String> serveursEnregistres = [
    '10.20.0.195',   // Wi-Fi actuel (ipconfig du 04/07/2026)
    '192.168.1.100', // exemple : Wi-Fi maison
    '192.168.43.1',  // exemple : partage de connexion telephone
  ];

  /// Adresse retenue apres detection (memorisee jusqu'au prochain echec).
  static String? _baseUrlDetectee;

  /// Candidats a tester, dans l'ordre, selon la plateforme :
  ///  - navigateur / bureau : localhost d'abord (serveur sur la meme machine)
  ///  - emulateur Android   : 10.0.2.2 d'abord (adresse speciale du PC hote)
  ///  - telephone physique  : les adresses IP enregistrees ci-dessus
  static List<String> get _candidats {
    final estAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return [
      if (!estAndroid) 'http://localhost:$_port/api',
      if (estAndroid) 'http://10.0.2.2:$_port/api',
      for (final ip in serveursEnregistres) 'http://$ip:$_port/api',
      if (estAndroid) 'http://localhost:$_port/api',
    ];
  }

  /// Retourne l'adresse de l'API Frontend, en la detectant si necessaire.
  static Future<String> baseUrl() async {
    if (_baseUrlDetectee != null) return _baseUrlDetectee!;
    for (final candidat in _candidats) {
      try {
        final reponse = await http
            .get(Uri.parse('$candidat/auth/ping'))
            .timeout(const Duration(seconds: 2));
        if (reponse.statusCode == 200) {
          _baseUrlDetectee = candidat;
          return candidat;
        }
      } catch (_) {
        // Adresse injoignable sur ce reseau : on essaie la suivante.
      }
    }
    // Aucun serveur trouve : on garde le premier candidat pour que l'appel
    // echoue avec un message clair, et on retentera au prochain appel.
    return _candidats.first;
  }

  /// A appeler apres un echec reseau : oublie l'adresse memorisee pour
  /// forcer une nouvelle detection (utile apres un changement de Wi-Fi).
  static void reinitialiser() => _baseUrlDetectee = null;
}
