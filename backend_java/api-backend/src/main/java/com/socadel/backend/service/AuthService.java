package com.socadel.backend.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

import org.springframework.stereotype.Service;

import com.socadel.backend.dto.LoginRequest;
import com.socadel.backend.dto.LoginResponse;
import com.socadel.backend.dto.ProfilRequest;
import com.socadel.backend.dto.UtilisateurDto;
import com.socadel.backend.entity.Utilisateur;
import com.socadel.backend.repository.CompteurRepository;
import com.socadel.backend.repository.UtilisateurRepository;
import com.socadel.backend.security.JwtUtil;

/**
 * Service metier d'authentification (RBACL).
 *
 * Le technicien et l'administrateur s'authentifient de la meme maniere
 * (nom + matricule unique + mot de passe) ; le role est ensuite determine
 * par le systeme, qui delivre un jeton JWT signe. Les mots de passe sont
 * stockes sous forme de hachage SHA-256 : la modification du mot de passe
 * depuis la page profil reste possible (on remplace simplement le hachage).
 */
@Service
public class AuthService {

    private final UtilisateurRepository utilisateurRepo;
    private final CompteurRepository compteurRepo;
    private final AuditService auditService;
    private final JwtUtil jwtUtil;

    public AuthService(UtilisateurRepository utilisateurRepo, CompteurRepository compteurRepo,
                       AuditService auditService, JwtUtil jwtUtil) {
        this.utilisateurRepo = utilisateurRepo;
        this.compteurRepo = compteurRepo;
        this.auditService = auditService;
        this.jwtUtil = jwtUtil;
    }

    /** Verifie les identifiants et delivre le jeton JWT. */
    public LoginResponse connecter(LoginRequest requete) {
        if (estVide(requete.nom()) || estVide(requete.matricule()) || estVide(requete.motDePasse())) {
            throw new IllegalArgumentException("Veuillez renseigner tous les champs.");
        }
        Utilisateur u = utilisateurRepo.findByMatriculeIgnoreCase(requete.matricule().trim())
                .orElseThrow(() -> new IllegalArgumentException("Matricule ou mot de passe incorrect."));

        if (!hacher(requete.motDePasse().trim()).equals(u.getMotDePasse())) {
            throw new IllegalArgumentException("Matricule ou mot de passe incorrect.");
        }
        String role = u.getRole() == Utilisateur.Role.ADMIN ? "Administrateur" : "Technicien";
        auditService.tracer(u.getNom(), "Connexion " + role.toLowerCase());

        String token = jwtUtil.genererToken(u.getMatricule(), u.getNom(), u.getRole().name());
        long compteurs = compteurRepo
                .findByTechnicienMatriculeIgnoreCaseOrderByReference(u.getMatricule()).size();
        return new LoginResponse(token, UtilisateurDto.depuis(u, compteurs));
    }

    /** Page profil : modification du nom et/ou du mot de passe. */
    public UtilisateurDto modifierProfil(ProfilRequest requete) {
        Utilisateur u = utilisateurRepo.findByMatriculeIgnoreCase(requete.matricule())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur introuvable."));
        if (!estVide(requete.nom())) {
            u.setNom(requete.nom().trim());
        }
        if (!estVide(requete.motDePasse())) {
            u.setMotDePasse(hacher(requete.motDePasse().trim()));
        }
        utilisateurRepo.save(u);
        auditService.tracer(u.getNom(), "Mise à jour du profil " + u.getMatricule());
        long compteurs = compteurRepo
                .findByTechnicienMatriculeIgnoreCaseOrderByReference(u.getMatricule()).size();
        return UtilisateurDto.depuis(u, compteurs);
    }

    /** Hachage SHA-256 (hexadecimal) d'un mot de passe. */
    public static String hacher(String motDePasse) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] octets = digest.digest(motDePasse.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : octets) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (Exception e) {
            throw new IllegalStateException("Hachage SHA-256 indisponible", e);
        }
    }

    private static boolean estVide(String s) {
        return s == null || s.isBlank();
    }
}
