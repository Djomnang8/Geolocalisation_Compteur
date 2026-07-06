package com.socadel.backend.dto;

/** Entree de l'historique des interventions / localisations d'un compteur. */
public record HistoriqueDto(String date, String etat, String note, String technicien, String gps) {
}
