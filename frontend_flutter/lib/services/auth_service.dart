import '../core/session.dart';
import '../models/utilisateur.dart';
import 'api_client.dart';

/// Authentification unifiee (nom + matricule + mot de passe) : le role est
/// determine par le systeme (RBACL) et un jeton JWT est delivre.
/// Diagramme de sequence : "Authentification du technicien et de l'administrateur".
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<Utilisateur> connecter({
    required String nom,
    required String matricule,
    required String motDePasse,
  }) async {
    final donnees = await ApiClient.instance.post('/auth/login', {
      'nom': nom,
      'matricule': matricule,
      'motDePasse': motDePasse,
    });
    final utilisateur = Utilisateur.fromJson(donnees['utilisateur']);
    Session.instance.ouvrir(donnees['token'], utilisateur);
    return utilisateur;
  }

  /// Page profil : modification du nom et/ou du mot de passe.
  Future<Utilisateur> modifierProfil({String? nom, String? motDePasse}) async {
    final donnees = await ApiClient.instance.put('/profil', {
      'matricule': Session.instance.utilisateur!.matricule,
      'nom': nom,
      'motDePasse': motDePasse,
    });
    final utilisateur = Utilisateur.fromJson(donnees);
    Session.instance.utilisateur = utilisateur;
    return utilisateur;
  }

  void deconnecter() => Session.instance.fermer();
}
