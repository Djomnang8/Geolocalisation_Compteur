import 'api_client.dart';

/// Statistiques : indicateurs (KPI) du tableau de bord administrateur,
/// repartition par zone et liste des zones de service.
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  Future<Map<String, dynamic>> tableauDeBord() async =>
      (await ApiClient.instance.get('/stats/dashboard') as Map).cast<String, dynamic>();

  Future<List<Map<String, dynamic>>> zones() async =>
      (await ApiClient.instance.get('/zones') as List).cast<Map<String, dynamic>>();
}
