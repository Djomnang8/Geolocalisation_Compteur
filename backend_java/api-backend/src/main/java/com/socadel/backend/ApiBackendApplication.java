package com.socadel.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * API BACKEND - microservices metier de l'application SOCADEL Geoloc.
 *
 * Chaine d'appel imposee par le cahier des charges :
 *   Mobile Flutter -> API Frontend (BFF, 8080) -> API Backend (8081)
 *   -> Couche de services metier -> Base MySQL.
 */
@SpringBootApplication
public class ApiBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(ApiBackendApplication.class, args);
    }
}
