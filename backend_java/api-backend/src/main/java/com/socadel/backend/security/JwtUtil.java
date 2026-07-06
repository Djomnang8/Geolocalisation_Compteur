package com.socadel.backend.security;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Gestion des jetons JWT (HMAC-SHA256) securisant les requetes entre
 * l'application mobile, l'API Frontend et l'API Backend (cahier des charges,
 * besoins non fonctionnels - securite).
 */
@Component
public class JwtUtil {

    @Value("${app.jwt.secret}")
    private String secret;

    @Value("${app.jwt.expiration-heures:24}")
    private long expirationHeures;

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();

    /** Genere un jeton signe contenant le matricule, le nom et le role. */
    public String genererToken(String matricule, String nom, String role) {
        long exp = Instant.now().getEpochSecond() + expirationHeures * 3600;
        String header = B64.encodeToString("{\"alg\":\"HS256\",\"typ\":\"JWT\"}"
                .getBytes(StandardCharsets.UTF_8));
        String payload = B64.encodeToString(String.format(
                "{\"sub\":\"%s\",\"nom\":\"%s\",\"role\":\"%s\",\"exp\":%d}",
                echapper(matricule), echapper(nom), echapper(role), exp)
                .getBytes(StandardCharsets.UTF_8));
        return header + "." + payload + "." + signer(header + "." + payload);
    }

    /**
     * Verifie la signature et l'expiration du jeton.
     * Retourne les informations (sub, nom, role) ou null si le jeton est invalide.
     */
    public Map<String, String> verifierToken(String token) {
        try {
            String[] parties = token.split("\\.");
            if (parties.length != 3) return null;
            if (!signer(parties[0] + "." + parties[1]).equals(parties[2])) return null;

            String json = new String(B64D.decode(parties[1]), StandardCharsets.UTF_8);
            Map<String, String> infos = new HashMap<>();
            for (String cle : new String[]{"sub", "nom", "role"}) {
                java.util.regex.Matcher m = java.util.regex.Pattern
                        .compile("\"" + cle + "\"\\s*:\\s*\"([^\"]*)\"").matcher(json);
                if (m.find()) infos.put(cle, m.group(1));
            }
            java.util.regex.Matcher me = java.util.regex.Pattern
                    .compile("\"exp\"\\s*:\\s*(\\d+)").matcher(json);
            if (!me.find() || Long.parseLong(me.group(1)) < Instant.now().getEpochSecond()) {
                return null; // jeton expire
            }
            return infos;
        } catch (Exception e) {
            return null;
        }
    }

    private String signer(String donnees) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return B64.encodeToString(mac.doFinal(donnees.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException("Erreur de signature JWT", e);
        }
    }

    private String echapper(String s) {
        return s == null ? "" : s.replace("\"", "");
    }
}
