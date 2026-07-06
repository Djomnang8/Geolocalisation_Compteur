package com.socadel.backend.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.socadel.backend.service.AuditService;
import com.socadel.backend.service.StatistiqueService;

/**
 * Microservice des statistiques, zones et journal d'audit.
 * Diagramme de sequence : "Tableau de bord et export (PDF/Excel)".
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

    @GetMapping("/audit")
    public ResponseEntity<?> journal() {
        return ResponseEntity.ok(auditService.journal());
    }
}
