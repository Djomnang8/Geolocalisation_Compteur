import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../core/session.dart';

/// Exception metier remontee par l'API (message affichable a l'utilisateur).
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Client HTTP central : toutes les requetes partent vers l'API Frontend
/// (BFF, port 8080) avec le jeton JWT dans l'en-tete Authorization.
/// L'adresse du serveur est detectee automatiquement parmi les adresses IP
/// enregistrees dans ApiConfig ; apres un echec reseau (changement de Wi-Fi),
/// la detection est relancee au prochain appel.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Map<String, String> get _entetes => {
        'Content-Type': 'application/json; charset=UTF-8',
        if (Session.instance.token != null)
          'Authorization': 'Bearer ${Session.instance.token}',
      };

  Future<dynamic> get(String chemin) =>
      _executer((base) => http.get(Uri.parse('$base$chemin'), headers: _entetes));

  Future<dynamic> post(String chemin, Map<String, dynamic> corps) =>
      _executer((base) => http.post(Uri.parse('$base$chemin'),
          headers: _entetes, body: jsonEncode(corps)));

  Future<dynamic> put(String chemin, Map<String, dynamic> corps) =>
      _executer((base) => http.put(Uri.parse('$base$chemin'),
          headers: _entetes, body: jsonEncode(corps)));

  Future<dynamic> delete(String chemin) =>
      _executer((base) => http.delete(Uri.parse('$base$chemin'), headers: _entetes));

  /// Telechargement binaire (photo d'inspection, fichier joint) : renvoie
  /// les octets bruts de la reponse.
  Future<List<int>> getOctets(String chemin) async {
    final base = await ApiConfig.baseUrl();
    try {
      final reponse = await http
          .get(Uri.parse('$base$chemin'), headers: _entetes)
          .timeout(const Duration(seconds: 25));
      if (reponse.statusCode >= 200 && reponse.statusCode < 300) {
        return reponse.bodyBytes;
      }
      _traiter(reponse); // leve l'ApiException avec le message du serveur
      return reponse.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (e) {
      ApiConfig.reinitialiser();
      rethrow;
    }
  }

  Future<dynamic> _executer(
      Future<http.Response> Function(String base) requete) async {
    final base = await ApiConfig.baseUrl();
    try {
      final reponse = await requete(base).timeout(const Duration(seconds: 15));
      return _traiter(reponse);
    } on ApiException {
      rethrow;
    } catch (e) {
      // Echec reseau : le serveur a peut-etre change d'adresse (autre Wi-Fi).
      // On oublie l'adresse memorisee pour re-detecter au prochain appel.
      ApiConfig.reinitialiser();
      rethrow;
    }
  }

  dynamic _traiter(http.Response reponse) {
    final corps = reponse.body.isEmpty ? null : jsonDecode(utf8.decode(reponse.bodyBytes));
    if (reponse.statusCode >= 200 && reponse.statusCode < 300) {
      return corps;
    }
    final message = (corps is Map && corps['message'] != null)
        ? corps['message'].toString()
        : 'Erreur ${reponse.statusCode} — réessayez.';
    throw ApiException(message, reponse.statusCode);
  }
}
