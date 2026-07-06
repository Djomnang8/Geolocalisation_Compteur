package com.socadel.gateway.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Point d'entree de decouverte : l'application mobile teste chaque adresse IP
 * enregistree dans sa configuration et retient la premiere qui repond ici.
 * (Chemin sous /api/auth/ : accessible sans jeton, comme l'authentification.)
 */
@RestController
public class PingController {

    @GetMapping("/api/auth/ping")
    public ResponseEntity<?> ping() {
        return ResponseEntity.ok(Map.of("service", "socadel-api-frontend", "statut", "OK"));
    }
}
