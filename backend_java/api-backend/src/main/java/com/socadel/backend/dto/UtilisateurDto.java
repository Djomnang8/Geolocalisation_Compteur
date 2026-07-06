package com.socadel.backend.dto;

import com.socadel.backend.entity.Utilisateur;

/** Profil utilisateur expose par l'API (jamais le mot de passe). */
public record UtilisateurDto(Long id, String nom, String matricule, String role,
                             String zone, String telephone, long compteurs) {

    public static UtilisateurDto depuis(Utilisateur u, long compteurs) {
        return new UtilisateurDto(u.getId(), u.getNom(), u.getMatricule(),
                u.getRole().name(), u.getZone(), u.getTelephone(), compteurs);
    }
}
