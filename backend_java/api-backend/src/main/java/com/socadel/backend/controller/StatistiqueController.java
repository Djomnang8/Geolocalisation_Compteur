package com.socadel.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.socadel.backend.service.AuditService;
import com.socadel.backend.service.StatistiqueService;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Microservice des statistiques, zones, suivi des deplacements et journal
 * d'audit. Diagramme de sequence : "Tableau de bord et export (PDF/Excel)".
 */
@RestController
@RequestMapping("/api")
public class StatistiqueController {

    private final StatistiqueService statistiqueService;
    private final AuditService auditService;

    public StatistiqueController(StatistiqueService statistiqueService, AuditService auditService) {
        this.statistiqueService = statistiqueService;
        this.auditService = auditService;
    }

    @GetMapping("/stats/dashboard")
    public ResponseEntity<?> tableauDeBord() {
        return ResponseEntity.ok(statistiqueService.tableauDeBord());
    }

    @GetMapping("/zones")
    public ResponseEntity<?> zones() {
        return ResponseEntity.ok(statistiqueService.zones());
    }

    /** Creation d'une zone de service (RBACL : administrateur uniquement). */
    @PostMapping("/zones")
    public ResponseEntity<?> creerZone(@RequestBody Map<String, Object> corps,
                                       HttpServletRequest req) {
        if (!"ADMIN".equals(req.getAttribute("role"))) {
            return ResponseEntity.status(403)
                    .body(Map.of("message", "Accès réservé à l'administrateur (RBACL)."));
        }
        try {
            Object couverture = corps.get("couverture");
            return ResponseEntity.ok(statistiqueService.creerZone(
                    (String) corps.get("nom"),
                    (String) corps.get("couleur"),
                    couverture == null ? null : ((Number) couverture).intValue(),
                    auteur(req)));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    /** Suivi des deplacements des techniciens (page administrateur). */
    @GetMapping("/suivi")
    public ResponseEntity<?> suivi() {
        return ResponseEntity.ok(statistiqueService.suivi());
    }

    @GetMapping("/audit")
    public ResponseEntity<?> journal() {
        return ResponseEntity.ok(auditService.journal());
    }

    private String auteur(HttpServletRequest req) {
        Object matricule = req.getAttribute("matricule");
        return matricule == null ? "Système" : matricule.toString();
    }
}
