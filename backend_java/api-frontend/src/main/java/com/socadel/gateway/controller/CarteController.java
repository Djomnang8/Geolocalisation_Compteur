package com.socadel.gateway.controller;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.web.client.RestTemplate;

import com.socadel.gateway.security.JetonVerifier;

/**
 * Exemple du role "mise en forme" du BFF : ce point d'entree transforme la
 * liste des compteurs fournie par l'API Backend au format GeoJSON attendu
 * par les bibliotheques cartographiques (OpenStreetMap / flutter_map), sans
 * exposer la structure interne du systeme.
 */
@RestController
public class CarteController {

    private final RestTemplate rest;
    private final JetonVerifier jetonVerifier;

    @Value("${app.backend.url}")
    private String backendUrl;

    public CarteController(RestTemplate rest, JetonVerifier jetonVerifier) {
        this.rest = rest;
        this.jetonVerifier = jetonVerifier;
    }

    @GetMapping("/api-carte/geojson")
    public ResponseEntity<?> geojson(@RequestHeader(value = "Authorization", required = false) String autorisation,
                                     @RequestParam(required = false) String technicien) {
        if (autorisation == null || !autorisation.startsWith("Bearer ")
                || !jetonVerifier.estValide(autorisation.substring(7))) {
            return ResponseEntity.status(401).body(Map.of("message", "Jeton invalide ou manquant."));
        }
        HttpHeaders entetes = new HttpHeaders();
        entetes.add("Authorization", autorisation);
        String url = backendUrl + "/api/compteurs" + (technicien == null ? "" : "?technicien=" + technicien);
        ResponseEntity<List<Map<String, Object>>> reponse = rest.exchange(url, HttpMethod.GET,
                new HttpEntity<>(entetes), new ParameterizedTypeReference<>() { });

        List<Map<String, Object>> features = new ArrayList<>();
        for (Map<String, Object> c : reponse.getBody() == null ? List.<Map<String, Object>>of() : reponse.getBody()) {
            Map<String, Object> feature = new LinkedHashMap<>();
            feature.put("type", "Feature");
            feature.put("geometry", Map.of(
                    "type", "Point",
                    "coordinates", List.of(c.get("longitude"), c.get("latitude"))));
            feature.put("properties", Map.of(
                    "reference", c.get("reference"),
                    "statut", c.get("statut"),
                    "zone", c.get("zone") == null ? "" : c.get("zone")));
            features.add(feature);
        }
        return ResponseEntity.ok(Map.of("type", "FeatureCollection", "features", features));
    }
}
