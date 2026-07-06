package com.socadel.backend.dto;

/**
 * Envoi d'un rapport d'inspection par le technicien : etat, anomalies,
 * observations, pieces jointes et position GPS capturee lors de la visite.
 */
public record RapportRequest(Long compteurId, String matricule, String etat, String etatAutre,
                             String anomalies, String observations, Boolean photo,
                             String fichier, Double latitude, Double longitude) {
}
