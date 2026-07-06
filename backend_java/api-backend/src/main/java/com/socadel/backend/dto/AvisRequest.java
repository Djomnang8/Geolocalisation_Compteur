package com.socadel.backend.dto;

/** Avis de l'administrateur sur un rapport : VALIDE ou REJETE + commentaire. */
public record AvisRequest(String statut, String commentaire, String matriculeAdmin) {
}
