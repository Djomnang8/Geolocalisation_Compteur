# backend_java — SOCADEL Géoloc

Deux applications Spring Boot 3.3 (Java 17+, Maven multi-modules), conformes à
l'architecture du cahier des charges : **deux API REST nettement séparées**.

| Module | Rôle | Port |
|---|---|---|
| `api-frontend` | Passerelle **BFF** exposée au mobile : vérification JWT, mise en forme (GeoJSON), orchestration | **8080** |
| `api-backend` | **Microservices métier** + couche de services + accès MySQL. Interne uniquement | **8081** |

## Démarrage

1. XAMPP : démarrer MySQL puis importer `database/socadel_geoloc.sql` dans phpMyAdmin.
2. Terminal 1 :
```bat
mvn -pl api-backend spring-boot:run
```
3. Terminal 2 :
```bat
mvn -pl api-frontend spring-boot:run
```
(Ne rien ajouter après la commande : un commentaire collé sur la même ligne
serait transmis à Maven comme argument et ferait échouer le build.)

## Points d'entrée principaux (préfixe /api, via la passerelle 8080)

| Méthode | Chemin | Rôle |
|---|---|---|
| POST | `/auth/login` | Authentification unifiée (nom + matricule + mot de passe), rôle déterminé par RBACL, jeton JWT |
| PUT | `/profil` | Page profil : modifier nom / mot de passe |
| GET | `/compteurs?technicien=&statut=&q=` | Carte technicien / carte globale admin, recherche, filtres |
| POST/PUT/DELETE | `/compteurs[/{id}]` | CRUD fiches compteurs (admin) |
| PUT | `/compteurs/{id}/attribution` | Attribution d'un compteur à un technicien |
| GET | `/compteurs/{id}/historique` | Historique des interventions / localisations |
| GET/POST | `/rapports` | Liste / envoi d'un rapport d'inspection (met à jour le statut du compteur + capture GPS + audit) |
| PUT | `/rapports/{id}/avis` | Avis admin : Validé / Rejeté + commentaire |
| GET/POST/PUT/DELETE | `/techniciens...` | CRUD techniciens + bascule du rôle admin (réservé ADMIN) |
| GET | `/stats/dashboard`, `/zones`, `/audit` | KPI, zones, journal d'audit |
| GET | `/api-carte/geojson` | (BFF seulement) compteurs au format GeoJSON |

## Sécurité
- Mots de passe **hachés SHA-256** (la modification depuis la page profil reste
  possible : on remplace le hachage).
- **JWT HMAC-SHA256** vérifié deux fois : à la passerelle ET à l'API Backend.
- **RBACL** : le rôle est porté par le jeton ; les opérations d'administration
  sont refusées (403) aux techniciens.
- **Journal d'audit** : connexions, envois de rapports, validations, CRUD,
  attributions, captures GPS (ISO 27001).
