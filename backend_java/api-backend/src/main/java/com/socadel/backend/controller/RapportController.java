package com.socadel.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.socadel.backend.dto.AvisRequest;
import com.socadel.backend.dto.RapportRequest;
import com.socadel.backend.service.RapportService;

/**
 * Microservice des rapports d'inspection.
 * Diagrammes de sequence : "Remplir et envoyer un rapport d'inspection",
 * "Consultation et validation d'un rapport".
 */
@RestController
@RequestMapping("/api/rapports")
public class RapportController {

    private final RapportService rapportService;

    public RapportController(RapportService rapportService) {
        this.rapportService = rapportService;
    }

    @GetMapping
    public ResponseEntity<?> lister(@RequestParam(required = false) String matricule,
                                    @RequestParam(required = false) String statut) {
        return ResponseEntity.ok(rapportService.lister(matricule, statut));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> obtenir(@PathVariable Long id) {
        try {
            return ResponseEntity.ok(rapportService.obtenir(id));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(404).body(Map.of("message", e.getMessage()));
        }
    }

    @PostMapping
    public ResponseEntity<?> envoyer(@RequestBody RapportRequest requete) {
        try {
            return ResponseEntity.ok(rapportService.envoyer(requete));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/{id}/avis")
    public ResponseEntity<?> donnerAvis(@PathVariable Long id, @RequestBody AvisRequest avis) {
        try {
            return ResponseEntity.ok(rapportService.donnerAvis(id, avis));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}
