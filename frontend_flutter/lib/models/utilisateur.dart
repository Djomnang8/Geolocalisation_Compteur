/// Profil utilisateur renvoye par l'API (jamais le mot de passe).
class Utilisateur {
  final int id;
  final String nom;
  final String matricule;
  final String role; // TECHNICIEN ou ADMIN (RBACL)
  final String? zone;
  final String? telephone;
  final int compteurs;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.matricule,
    required this.role,
    this.zone,
    this.telephone,
    this.compteurs = 0,
  });

  factory Utilisateur.fromJson(Map<String, dynamic> json) => Utilisateur(
        id: (json['id'] as num).toInt(),
        nom: json['nom'] ?? '',
        matricule: json['matricule'] ?? '',
        role: json['role'] ?? 'TECHNICIEN',
        zone: json['zone'],
        telephone: json['telephone'],
        compteurs: (json['compteurs'] as num?)?.toInt() ?? 0,
      );

  bool get estAdmin => role == 'ADMIN';

  String get roleLibelle => estAdmin ? 'Administrateur' : 'Technicien';

  String get initiales {
    final parties = nom.trim().split(RegExp(r'\s+'));
    return parties.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}
