package com.socadel.backend.dto;

/** Reponse d'authentification : jeton JWT + profil (le role est determine par le systeme, RBACL). */
public record LoginResponse(String token, UtilisateurDto utilisateur) {
}
