package com.socadel.backend.security;

import java.io.IOException;
import java.util.Map;

import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Filtre de securite : toute requete (sauf l'authentification) doit porter
 * un jeton JWT valide dans l'en-tete "Authorization: Bearer ...".
 * Le matricule et le role extraits du jeton sont mis a disposition des
 * controleurs (attributs de requete) pour le controle d'acces RBACL.
 */
@Component
public class JwtFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;

    public JwtFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return request.getRequestURI().startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        String entete = request.getHeader("Authorization");
        if (entete == null || !entete.startsWith("Bearer ")) {
            refuser(response, "Jeton d'authentification manquant.");
            return;
        }
        Map<String, String> infos = jwtUtil.verifierToken(entete.substring(7));
        if (infos == null) {
            refuser(response, "Jeton invalide ou expiré.");
            return;
        }
        request.setAttribute("matricule", infos.get("sub"));
        request.setAttribute("role", infos.get("role"));
        chain.doFilter(request, response);
    }

    private void refuser(HttpServletResponse response, String message) throws IOException {
        response.setStatus(401);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"message\":\"" + message + "\"}");
    }
}
