/// Rapport d'inspection envoye par le technicien puis traite (avis)
/// par l'administrateur.
class Rapport {
  final int id;
  final int compteurId;
  final String reference;
  final String? zone;
  final String technicienNom;
  final String? technicienMatricule;
  final String date;
  final String etat; // ACTIF, MAINTENANCE, PANNE, AUTRE
  final String? etatAutre;
  final List<String> anomalies;
  final String? observations;
  final bool photo;
  final String? fichier;
  final String gps;
  final String statut; // EN_ATTENTE, VALIDE, REJETE
  final String? commentaireAdmin;

  const Rapport({
    required this.id,
    required this.compteurId,
    required this.reference,
    this.zone,
    required this.technicienNom,
    this.technicienMatricule,
    required this.date,
    required this.etat,
    this.etatAutre,
    required this.anomalies,
    this.observations,
    required this.photo,
    this.fichier,
    required this.gps,
    required this.statut,
    this.commentaireAdmin,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) => Rapport(
        id: (json['id'] as num).toInt(),
        compteurId: (json['compteurId'] as num?)?.toInt() ?? 0,
        reference: json['reference'] ?? '',
        zone: json['zone'],
        technicienNom: json['technicienNom'] ?? '—',
        technicienMatricule: json['technicienMatricule'],
        date: json['date'] ?? '',
        etat: json['etat'] ?? 'ACTIF',
        etatAutre: json['etatAutre'],
        anomalies: (json['anomalies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        observations: json['observations'],
        photo: json['photo'] == true,
        fichier: json['fichier'],
        gps: json['gps'] ?? '—',
        statut: json['statut'] ?? 'EN_ATTENTE',
        commentaireAdmin: json['commentaireAdmin'],
      );
}
