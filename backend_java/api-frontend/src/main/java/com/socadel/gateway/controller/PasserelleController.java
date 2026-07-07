package com.socadel.gateway.controller;

import java.util.Enumeration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import com.socadel.gateway.security.JetonVerifier;

import jakarta.servlet.http.HttpServletRequest;

/**
 * Passerelle generique de l'API Frontend : recoit chaque requete du mobile,
 * verifie le jeton JWT (sauf pour l'authentification), puis orchestre l'appel
 * correspondant vers l'API Backend et retransmet la reponse.
 *
 * L'API du Frontend n'est jamais reutilisee comme API du Backend : elle ne
 * porte aucune logique metier, uniquement la securite et la mise en forme.
 */
@RestController
public class PasserelleController {

    private final RestTemplate rest;
    private final JetonVerifier jetonVerifier;

    @Value("${app.backend.url}")
    private String backendUrl;

    public PasserelleController(RestTemplate rest, JetonVerifier jetonVerifier) {
        this.rest = rest;
        this.jetonVerifier = jetonVerifier;
    }

    @RequestMapping("/api/**")
    public ResponseEntity<byte[]> transmettre(HttpServletRequest requete,
                                              @RequestBody(required = false) byte[] corps) {
        String chemin = requete.getRequestURI();
        String parametres = requete.getQueryString();

        // 1. Verification du jeton JWT (l'authentification est le seul point libre)
        if (!chemin.startsWith("/api/auth/")) {
            String entete = requete.getHeader("Authorization");
            if (entete == null || !entete.startsWith("Bearer ")
                    || !jetonVerifier.estValide(entete.substring(7))) {
                return ResponseEntity.status(401)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"message\":\"Jeton invalide ou manquant (API Frontend).\"}"
                                .getBytes(java.nio.charset.StandardCharsets.UTF_8));
            }
        }

        // 2. Orchestration : transmission de la demande a l'API Backend
        String url = backendUrl + chemin + (parametres == null ? "" : "?" + parametres);
        HttpHeaders entetes = new HttpHeaders();
        Enumeration<String> noms = requete.getHeaderNames();
        while (noms.hasMoreElements()) {
            String nom = noms.nextElement();
            if (nom.equalsIgnoreCase("authorization") || nom.equalsIgnoreCase("content-type")) {
                entetes.add(nom, requete.getHeader(nom));
            }
        }
        if (entetes.getContentType() == null) {
            entetes.setContentType(MediaType.APPLICATION_JSON);
        }

        try {
            ResponseEntity<byte[]> reponse = rest.exchange(url,
                    HttpMethod.valueOf(requete.getMethod()),
                    new HttpEntity<>(corps, entetes), byte[].class);
            // 3. Retransmission fidele de la reponse au mobile : le type de
            // contenu d'origine est conserve (JSON, image JPEG, fichier...)
            HttpHeaders entetesReponse = new HttpHeaders();
            MediaType type = reponse.getHeaders().getContentType();
            entetesReponse.setContentType(type == null ? MediaType.APPLICATION_JSON : type);
            String disposition = reponse.getHeaders().getFirst(HttpHeaders.CONTENT_DISPOSITION);
            if (disposition != null) {
                entetesReponse.set(HttpHeaders.CONTENT_DISPOSITION, disposition);
            }
            return ResponseEntity.status(reponse.getStatusCode())
                    .headers(entetesReponse)
                    .body(reponse.getBody());
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            // Erreur metier du backend (400, 401, 404...) : retransmise telle quelle
            return ResponseEntity.status(e.getStatusCode())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(e.getResponseBodyAsByteArray());
        } catch (Exception e) {
            return ResponseEntity.status(503)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(("{\"message\":\"API Backend indisponible. Vérifiez que le service"
                            + " est démarré (port 8081).\"}")
                            .getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }
    }
}
