package com.socadel.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.socadel.backend.dto.CompteurRequest;
import com.socadel.backend.service.CompteurService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Microservice des compteurs : consultation sur la carte, recherche par numero,
 * filtrage par statut, CRUD des fiches, attribution et historique.
 * Diagrammes de sequence : "Consultation des compteurs sur la carte",
 * "Recherche d'un compteur par numero", "Attribution d'un compteur",
 * "Consultation de l'historique de localisation".
 */
@RestController
@RequestMapping("/api/compteurs")
public class CompteurController {

    private final CompteurService compteurService;

    public CompteurController(CompteurService compteurService) {
        this.compteurService = compteurService;
    }

    @GetMapping
    public ResponseEntity<?> lister(@RequestParam(required = false) String technicien,
                                    @RequestParam(required = false) String statut,
                                    @RequestParam(required = false, name = "q") String recherche) {
        return ResponseEntity.ok(compteurService.lister(technicien, statut, recherche));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtenir(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(compteurService.obtenir(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @GetMapping("/{id}/historique")
    public ResponseEntity<?> historique(@PathVariable Long id) {
        return ResponseEntity.ok(compteurService.historique(id));
    }

    @PostMapping
    public ResponseEntity<?> creer(@RequestBody CompteurRequest requete, HttpServletRequest req) {
        try {
            return ResponseEntity.ok(compteurService.creer(requete, auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> modifier(@PathVariable Long id,
                                      @RequestBody CompteurRequest requete, HttpServletRequest req) {
        try {
            return ResponseEntity.ok(compteurService.modifier(id, requete, auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/attribution")
    public ResponseEntity<?> attribuer(@PathVariable Long id,
                                       @RequestBody Map<String, String> corps, HttpServletRequest req) {
        try {
            return ResponseEntity.ok(compteurService.attribuer(id, corps.get("matricule"), auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> supprimer(@PathVariable Long id, HttpServletRequest req) {
        try {
            compteurService.supprimer(id, auteur(req));
            return ResponseEntity.ok(Map.of("message", "Compteur supprimé."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /** Nom de l'utilisateur porte par le jeton JWT (pour le journal d'audit). */
    private String auteur(HttpServletRequest req) {
        Object matricule = req.getAttribute("matricule");
        return matricule == null ? "Système" : matricule.toString();
    }
}
