import '../models/compteur.dart';
import 'api_client.dart';

/// Acces aux compteurs via l'API Frontend : consultation sur la carte,
/// recherche par numero, filtrage par statut, CRUD et attribution.
class CompteurService {
  CompteurService._();
  static final CompteurService instance = CompteurService._();

  /// Liste des compteurs.
  ///  - [technicien] : matricule -> uniquement les compteurs attribues (carte technicien)
  ///  - null         -> tous les compteurs de Douala (carte administrateur)
  Future<List<Compteur>> lister({String? technicien, String? statut, String? recherche}) async {
    final parametres = <String>[
      if (technicien != null && technicien.isNotEmpty) 'technicien=$technicien',
      if (statut != null && statut.isNotEmpty && statut != 'TOUS') 'statut=$statut',
      if (recherche != null && recherche.trim().isNotEmpty)
        'q=${Uri.encodeQueryComponent(recherche.trim())}',
    ];
    final chemin = '/compteurs${parametres.isEmpty ? '' : '?${parametres.join('&')}'}';
    final donnees = await ApiClient.instance.get(chemin) as List;
    return donnees.map((c) => Compteur.fromJson(c)).toList();
  }

  Future<Compteur> creer(Map<String, dynamic> fiche) async =>
      Compteur.fromJson(await ApiClient.instance.post('/compteurs', fiche));

  Future<Compteur> modifier(int id, Map<String, dynamic> fiche) async =>
      Compteur.fromJson(await ApiClient.instance.put('/compteurs/$id', fiche));

  Future<void> supprimer(int id) => ApiClient.instance.delete('/compteurs/$id');

  /// Attribution d'un compteur a un technicien (matricule vide = retrait).
  Future<Compteur> attribuer(int id, String? matricule) async =>
      Compteur.fromJson(await ApiClient.instance
          .put('/compteurs/$id/attribution', {'matricule': matricule ?? ''}));

  /// Historique des interventions / localisations d'un compteur.
  Future<List<Map<String, dynamic>>> historique(int id) async {
    final donnees = await ApiClient.instance.get('/compteurs/$id/historique') as List;
    return donnees.cast<Map<String, dynamic>>();
  }
}
