package com.socadel.backend.dto;

/** Creation / modification d'une fiche compteur (CRUD administrateur). */
public record CompteurRequest(String reference, String marque, String modele, String type,
                              String indexInitial, String quartier, Double latitude,
                              Double longitude, String zone, String technicienMatricule) {
}
