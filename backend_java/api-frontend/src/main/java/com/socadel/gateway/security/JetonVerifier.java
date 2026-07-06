package com.socadel.gateway.security;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Verification du jeton JWT au niveau de la passerelle : l'API Frontend
 * refuse toute requete non authentifiee avant meme de contacter l'API
 * Backend, ce qui reduit la surface d'attaque.
 */
@Component
public class JetonVerifier {

    @Value("${app.jwt.secret}")
    private String secret;

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final Base64.Decoder B64D = Base64.getUrlDecoder();

    /** Retourne vrai si le jeton est signe correctement et non expire. */
    public boolean estValide(String token) {
        try {
            String[] parties = token.split("\\.");
            if (parties.length != 3) return false;

            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            String signature = B64.encodeToString(
                    mac.doFinal((parties[0] + "." + parties[1]).getBytes(StandardCharsets.UTF_8)));
            if (!signature.equals(parties[2])) return false;

            String json = new String(B64D.decode(parties[1]), StandardCharsets.UTF_8);
            java.util.regex.Matcher m = java.util.regex.Pattern
                    .compile("\"exp\"\\s*:\\s*(\\d+)").matcher(json);
            return m.find() && Long.parseLong(m.group(1)) >= Instant.now().getEpochSecond();
        } catch (Exception e) {
            return false;
        }
    }
}
