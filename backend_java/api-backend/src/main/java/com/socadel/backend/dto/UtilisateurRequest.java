package com.socadel.backend.dto;

/** Creation / modification d'un compte technicien ou administrateur. */
public record UtilisateurRequest(String nom, String matricule, String motDePasse,
                                 String role, String zone, String telephone) {
}
