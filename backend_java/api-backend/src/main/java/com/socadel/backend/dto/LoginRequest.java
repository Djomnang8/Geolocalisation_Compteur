package com.socadel.backend.dto;

/** Requete d'authentification unifiee : nom + matricule unique + mot de passe. */
public record LoginRequest(String nom, String matricule, String motDePasse) {
}
