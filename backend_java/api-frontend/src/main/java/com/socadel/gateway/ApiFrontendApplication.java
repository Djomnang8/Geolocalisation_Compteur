package com.socadel.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * API FRONTEND (Backend For Frontend) de l'application SOCADEL Geoloc.
 *
 * Seule porte d'entree exposee a l'application mobile Flutter :
 *   1. recoit les requetes des techniciens et administrateurs ;
 *   2. verifie le jeton JWT ;
 *   3. transmet la demande a l'API Backend (microservices metier) ;
 *   4. met en forme les donnees attendues par l'interface (ex. GeoJSON).
 * Elle ne contient aucune logique metier sensible.
 */
@SpringBootApplication
public class ApiFrontendApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiFrontendApplication.class, args);
    }

    @Bean
    public RestTemplate restTemplate() {
        // Ne pas lever d'exception sur les erreurs HTTP : la passerelle
        // retransmet fidelement la reponse de l'API Backend au mobile.
        RestTemplate rest = new RestTemplate();
        rest.setErrorHandler(new org.springframework.web.client.DefaultResponseErrorHandler() {
            @Override
            public boolean hasError(org.springframework.http.client.ClientHttpResponse response) {
                return false;
            }
        });
        return rest;
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOrigins("*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE");
            }
        };
    }
}
