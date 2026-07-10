import 'api_client.dart';

/// Statistiques : indicateurs (KPI) du tableau de bord administrateur,
/// repartition par zone, zones de service, suivi des deplacements des
/// techniciens et journal d'audit.
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  Future<Map<String, dynamic>> tableauDeBord() async =>
      (await ApiClient.instance.get('/stats/dashboard') as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> zones() async =>
      (await ApiClient.instance.get('/zones') as List).cast<Map<String, dynamic>>();

  /// Creation d'une zone de service (bouton "Tracer une nouvelle zone").
  Future<Map<String, dynamic>> creerZone(
          {required String nom, required String couleur, int couverture = 0}) async =>
      (await ApiClient.instance.post('/zones', {
        'nom': nom,
        'couleur': couleur,
        'couverture': couverture,
      }) as Map)
          .cast<String, dynamic>();

  /// Modification d'une zone de service (nom, couleur, couverture).
  Future<Map<String, dynamic>> modifierZone(int id,
          {required String nom, required String couleur, int couverture = 0}) async =>
      (await ApiClient.instance.put('/zones/$id', {
        'nom': nom,
        'couleur': couleur,
        'couverture': couverture,
      }) as Map)
          .cast<String, dynamic>();

  /// Suppression d'une zone de service (les compteurs repassent « sans zone »).
  Future<void> supprimerZone(int id) => ApiClient.instance.delete('/zones/$id');

  /// Suivi des deplacements des techniciens (page administrateur).
  Future<List<Map<String, dynamic>>> suivi() async =>
      (await ApiClient.instance.get('/suivi') as List).cast<Map<String, dynamic>>();

  /// Journal d'audit complet (tracabilite des actions sensibles).
  Future<List<Map<String, dynamic>>> journalAudit() async =>
      (await ApiClient.instance.get('/audit') as List).cast<Map<String, dynamic>>();
}
