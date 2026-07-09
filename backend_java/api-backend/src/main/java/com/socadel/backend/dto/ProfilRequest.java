package com.socadel.backend.dto;

/**
 * Mise a jour du profil : l'utilisateur peut modifier son nom, son numero
 * de telephone et son mot de passe.
 */
public record ProfilRequest(String matricule, String nom, String telephone, String motDePasse) {
}
