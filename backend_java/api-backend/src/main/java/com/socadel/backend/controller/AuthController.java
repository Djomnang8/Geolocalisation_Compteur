package com.socadel.backend.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.socadel.backend.dto.LoginRequest;
import com.socadel.backend.dto.ProfilRequest;
import com.socadel.backend.service.AuthService;

/**
 * Microservice d'authentification (RBACL) et de gestion du profil.
 * Diagramme de sequence : "Authentification du technicien et de l'administrateur".
 */
@RestController
@RequestMapping("/api")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> connecter(@RequestBody LoginRequest requete) {
        try {
            return ResponseEntity.ok(authService.connecter(requete));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(401).body(Map.of("message", e.getMessage()));
        }
    }

    @PutMapping("/profil")
    public ResponseEntity<?> modifierProfil(@RequestBody ProfilRequest requete) {
        try {
            return ResponseEntity.ok(authService.modifierProfil(requete));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("message", e.getMessage()));
        }
    }
}
