package com.socadel.backend.dto;

import com.socadel.backend.entity.Compteur;

/** Fiche compteur exposee par l'API. */
public record CompteurDto(Long id, String reference, String marque, String modele,
                          String type, String indexInitial, String statut, String statutAutre,
                          String quartier, double latitude, double longitude, String zone,
                          String technicienMatricule, String technicienNom) {

    public static CompteurDto depuis(Compteur c) {
        return new CompteurDto(
                c.getId(), c.getReference(), c.getMarque(), c.getModele(),
                c.getType(), c.getIndexInitial(), c.getStatut().name(), c.getStatutAutre(),
                c.getQuartier(),
                c.getLatitude() == null ? 0 : c.getLatitude().doubleValue(),
                c.getLongitude() == null ? 0 : c.getLongitude().doubleValue(),
                c.getZone() == null ? null : c.getZone().getNom(),
                c.getTechnicien() == null ? null : c.getTechnicien().getMatricule(),
                c.getTechnicien() == null ? null : c.getTechnicien().getNom());
    }
}
