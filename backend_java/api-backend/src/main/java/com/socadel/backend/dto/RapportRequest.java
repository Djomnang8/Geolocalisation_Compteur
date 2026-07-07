package com.socadel.backend.dto;

/**
 * Envoi d'un rapport d'inspection par le technicien : etat, anomalies,
 * observations, pieces jointes (octets encodes en Base64) et position GPS
 * capturee lors de la visite.
 */
public record RapportRequest(Long compteurId, String matricule, String etat, String etatAutre,
                             String anomalies, String observations, Boolean photo,
                             String fichier, String photoBase64, String fichierBase64,
                             Double latitude, Double longitude) {
}
