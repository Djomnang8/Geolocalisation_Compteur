/// Fiche compteur electrique (reference, marque, modele, type, index initial)
/// et localisation du point de livraison (latitude / longitude / quartier).
class Compteur {
  final int id;
  final String reference;
  final String? marque;
  final String? modele;
  final String type;
  final String indexInitial;
  final String statut; // NON_INSPECTE, ACTIF, MAINTENANCE, PANNE, AUTRE
  final String? statutAutre;
  final String? quartier;
  final double latitude;
  final double longitude;
  final String? zone;
  final String? technicienMatricule;
  final String? technicienNom;

  const Compteur({
    required this.id,
    required this.reference,
    this.marque,
    this.modele,
    required this.type,
    required this.indexInitial,
    required this.statut,
    this.statutAutre,
    this.quartier,
    required this.latitude,
    required this.longitude,
    this.zone,
    this.technicienMatricule,
    this.technicienNom,
  });

  factory Compteur.fromJson(Map<String, dynamic> json) => Compteur(
        id: (json['id'] as num).toInt(),
        reference: json['reference'] ?? '',
        marque: json['marque'],
        modele: json['modele'],
        type: json['type'] ?? '',
        indexInitial: json['indexInitial'] ?? '00000',
        statut: json['statut'] ?? 'NON_INSPECTE',
        statutAutre: json['statutAutre'],
        quartier: json['quartier'],
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        zone: json['zone'],
        technicienMatricule: json['technicienMatricule'],
        technicienNom: json['technicienNom'],
      );
}
