import '../models/rapport.dart';
import 'api_client.dart';

/// Rapports d'inspection : envoi par le technicien, consultation,
/// validation / rejet et commentaire par l'administrateur.
class RapportService {
  RapportService._();
  static final RapportService instance = RapportService._();

  Future<List<Rapport>> lister({String? matricule, String? statut}) async {
    final parametres = <String>[
      if (matricule != null && matricule.isNotEmpty) 'matricule=$matricule',
      if (statut != null && statut.isNotEmpty && statut != 'TOUS') 'statut=$statut',
    ];
    final chemin = '/rapports${parametres.isEmpty ? '' : '?${parametres.join('&')}'}';
    final donnees = await ApiClient.instance.get(chemin) as List;
    return donnees.map((r) => Rapport.fromJson(r)).toList();
  }

  /// Envoi du rapport d'inspection (etat, anomalies, observations, GPS...).
  Future<Rapport> envoyer(Map<String, dynamic> rapport) async =>
      Rapport.fromJson(await ApiClient.instance.post('/rapports', rapport));

  /// Avis de l'administrateur : VALIDE ou REJETE + commentaire.
  Future<Rapport> donnerAvis(int id,
      {required String statut, String? commentaire, String? matriculeAdmin}) async =>
      Rapport.fromJson(await ApiClient.instance.put('/rapports/$id/avis', {
        'statut': statut,
        'commentaire': commentaire,
        'matriculeAdmin': matriculeAdmin,
      }));
}
