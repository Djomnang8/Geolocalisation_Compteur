import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_colors.dart';

/// Metadonnees d'affichage d'un statut de compteur (libelle, couleur, fond),
/// strictement identiques a la maquette UX/UI.
class StatutMeta {
  final String code;
  final String libelle;
  final Color couleur;
  final Color fond;
  final double teinteMarqueur; // teinte du marqueur Google Maps

  const StatutMeta(this.code, this.libelle, this.couleur, this.fond, this.teinteMarqueur);

  static const Map<String, StatutMeta> _tous = {
    'NON_INSPECTE': StatutMeta('NON_INSPECTE', 'Non inspecté', AppColors.gris,
        AppColors.grisFond, BitmapDescriptor.hueViolet),
    'ACTIF': StatutMeta('ACTIF', 'Actif', AppColors.vert, AppColors.vertFond,
        BitmapDescriptor.hueGreen),
    'MAINTENANCE': StatutMeta('MAINTENANCE', 'En maintenance', AppColors.orange,
        AppColors.orangeFond, BitmapDescriptor.hueOrange),
    'PANNE': StatutMeta('PANNE', 'En panne', AppColors.rouge, AppColors.rougeFond,
        BitmapDescriptor.hueRed),
    'AUTRE': StatutMeta('AUTRE', 'Autre', AppColors.bleuClair, AppColors.bleuFond,
        BitmapDescriptor.hueAzure),
  };

  static StatutMeta de(String? code) => _tous[code] ?? _tous['NON_INSPECTE']!;

  static List<StatutMeta> get liste => _tous.values.toList();

  /// Libelle complet, avec la precision saisie quand l'etat est "Autre".
  static String libelleComplet(String code, String? autre) {
    final meta = de(code);
    if (code == 'AUTRE' && autre != null && autre.isNotEmpty) {
      return 'Autre — $autre';
    }
    return meta.libelle;
  }
}

/// Metadonnees d'affichage du statut d'un rapport d'inspection.
class StatutRapport {
  static String libelle(String statut) => switch (statut) {
        'VALIDE' => 'Validé',
        'REJETE' => 'Rejeté',
        _ => 'En attente',
      };

  static Color couleur(String statut) => switch (statut) {
        'VALIDE' => AppColors.vert,
        'REJETE' => AppColors.rouge,
        _ => AppColors.orange,
      };

  static Color fond(String statut) => switch (statut) {
        'VALIDE' => AppColors.vertFond,
        'REJETE' => AppColors.rougeFond,
        _ => AppColors.orangeFond,
      };
}
