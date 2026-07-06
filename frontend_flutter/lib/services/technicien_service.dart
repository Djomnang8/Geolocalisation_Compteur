import '../models/utilisateur.dart';
import 'api_client.dart';

/// Gestion des techniciens (CRUD administrateur) : consulter, ajouter,
/// modifier, rechercher, supprimer, promouvoir / retirer administrateur.
class TechnicienService {
  TechnicienService._();
  static final TechnicienService instance = TechnicienService._();

  Future<List<Utilisateur>> lister({String? recherche}) async {
    final chemin = (recherche == null || recherche.trim().isEmpty)
        ? '/techniciens'
        : '/techniciens?q=${Uri.encodeQueryComponent(recherche.trim())}';
    final donnees = await ApiClient.instance.get(chemin) as List;
    return donnees.map((u) => Utilisateur.fromJson(u)).toList();
  }

  Future<Utilisateur> creer(Map<String, dynamic> compte) async =>
      Utilisateur.fromJson(await ApiClient.instance.post('/techniciens', compte));

  Future<Utilisateur> modifier(int id, Map<String, dynamic> compte) async =>
      Utilisateur.fromJson(await ApiClient.instance.put('/techniciens/$id', compte));

  /// Option "faire de lui un administrateur ou non" (cahier des charges).
  Future<Utilisateur> basculerRole(int id) async =>
      Utilisateur.fromJson(await ApiClient.instance.put('/techniciens/$id/role', {}));

  Future<void> supprimer(int id) => ApiClient.instance.delete('/techniciens/$id');
}
