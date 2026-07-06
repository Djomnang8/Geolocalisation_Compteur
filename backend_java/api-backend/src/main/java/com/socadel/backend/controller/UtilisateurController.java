package com.socadel.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.socadel.backend.dto.UtilisateurRequest;
import com.socadel.backend.service.UtilisateurService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Microservice de gestion des techniciens (CRUD administrateur).
 * Diagramme de sequence : "Gestion des techniciens (CRUD)".
 * Controle d'acces RBACL : reserve au role ADMIN.
 */
@RestController
@RequestMapping("/api/techniciens")
public class UtilisateurController {

    private final UtilisateurService utilisateurService;

    public UtilisateurController(UtilisateurService utilisateurService) {
        this.utilisateurService = utilisateurService;
    }

    @GetMapping
    public ResponseEntity<?> lister(@RequestParam(required = false, name = "q") String recherche) {
        return ResponseEntity.ok(utilisateurService.lister(recherche));
    }

    @PostMapping
    public ResponseEntity<?> creer(@RequestBody UtilisateurRequest requete, HttpServletRequest req) {
        try {
            verifierAdmin(req);
            return ResponseEntity.ok(utilisateurService.creer(requete, auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> modifier(@PathVariable Long id,
                                      @RequestBody UtilisateurRequest requete, HttpServletRequest req) {
        try {
            verifierAdmin(req);
            return ResponseEntity.ok(utilisateurService.modifier(id, requete, auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/role")
    public ResponseEntity<?> basculerRole(@PathVariable Long id, HttpServletRequest req) {
        try {
            verifierAdmin(req);
            return ResponseEntity.ok(utilisateurService.basculerRole(id, auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> supprimer(@PathVariable Long id, HttpServletRequest req) {
        try {
            verifierAdmin(req);
            utilisateurService.supprimer(id, auteur(req));
            return ResponseEntity.ok(Map.of("message", "Compte supprimé."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        } catch (SecurityException e) {
            return ResponseEntity.status(403).body(Map.of("message", e.getMessage()));
        }
    }

    /** RBACL : seul un administrateur peut gerer les comptes. */
    private void verifierAdmin(HttpServletRequest req) {
        if (!"ADMIN".equals(req.getAttribute("role"))) {
            throw new SecurityException("Accès réservé à l'administrateur (RBACL).");
        }
    }

    private String auteur(HttpServletRequest req) {
        Object matricule = req.getAttribute("matricule");
        return matricule == null ? "Système" : matricule.toString();
    }
}
