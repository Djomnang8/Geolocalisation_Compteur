import '../models/utilisateur.dart';

/// Session de l'utilisateur connecte : jeton JWT + profil.
/// Le role (technicien / administrateur) est determine par le systeme
/// lors de l'authentification (RBACL) : chaque profil n'accede qu'a
/// sa propre interface.
class Session {
  Session._();
  static final Session instance = Session._();

  String? token;
  Utilisateur? utilisateur;

  bool get estConnecte => token != null && utilisateur != null;
  bool get estAdmin => utilisateur?.role == 'ADMIN';

  void ouvrir(String jeton, Utilisateur profil) {
    token = jeton;
    utilisateur = profil;
  }

  void fermer() {
    token = null;
    utilisateur = null;
  }
}
