# SOCADEL Géoloc — Géolocalisation des compteurs électriques (Douala, Koumassi)

Projet de stage — Licence 3 Génie Logiciel, Institut Supérieur KEYCE.
Application mobile de géolocalisation des compteurs électriques SOCADEL dans la
ville de Douala, réalisée à **50 % de chaque espace** conformément au cahier des
charges (la seconde moitié sera développée dans la phase suivante).

## Architecture (imposée par le cahier des charges)

```
Mobile Flutter  ──►  API Frontend (BFF)  ──►  API Backend (microservices)
(frontend_flutter)    port 8080               port 8081
                                                 │
                                          Couche de services métier
                                                 │
                                          Base MySQL (XAMPP, port 3306)
```

- **API Frontend** (`backend_java/api-frontend`) : seule porte d'entrée exposée au
  mobile. Vérifie le jeton JWT, met en forme les données (ex. GeoJSON) et
  orchestre les appels vers l'API Backend. Aucune logique métier.
- **API Backend** (`backend_java/api-backend`) : microservices métier
  (authentification RBACL, compteurs, attributions, rapports, zones,
  statistiques, audit). Non exposée à Internet.
- **Couche de services** : règles de gestion, transactions, unicité du matricule,
  seule à accéder à MySQL.

## Pages réalisées (moitié de chaque espace)

| Espace | Pages réalisées (maquette) | Restant (2e moitié) |
|---|---|---|
| Commun | Connexion (RBACL) | — |
| Technicien (4/8) | Tableau de bord · Carte des compteurs (recherche + filtres) · Détail compteur (+ historique) · Formulaire d'inspection (GPS + envoi) | Itinéraire · Rapports · Profil · Historique plein écran |
| Administrateur (8/15) | Tableau de bord (KPI) · Carte de Douala · Gestion des compteurs (CRUD) · Fiche compteur (+ attribution) · Rapports · Détail du rapport (valider/rejeter) · Techniciens (CRUD + promouvoir admin) · Fiche technicien | Attribution dédiée · Zones · Statistiques · Suivi · Journal d'audit · Profil · Historique par technicien |

Les diagrammes de séquence couverts : authentification RBAC, consultation carte,
recherche par numéro, capture GPS de visite, envoi du rapport d'inspection,
consultation/validation d'un rapport, gestion des techniciens (CRUD),
attribution d'un compteur, tableau de bord.

## Installation (Windows + XAMPP 8.2.12)

### 1. Base de données
1. Démarrer **MySQL** dans le panneau XAMPP (port 3306).
2. Ouvrir http://localhost/phpmyadmin → **Importer** →
   `backend_java/database/socadel_geoloc.sql`.

> Le script crée la base `socadel_geoloc` (7 tables) avec des données de
> démonstration. Mot de passe des comptes : `1234` (haché SHA-256).
> Comptes : `Jean MBALLA / TECH-2043` (technicien), `Alice NGONO / ADM-1007` (admin).

### 2. Backend (Java 17+ et Maven requis)
Dans deux terminaux séparés (ne rien ajouter après la commande) :
```bat
cd backend_java

:: Terminal 1 — microservices métier (port 8081)
mvn -pl api-backend spring-boot:run

:: Terminal 2 — passerelle BFF (port 8080)
mvn -pl api-frontend spring-boot:run
```
Test rapide : `POST http://localhost:8080/api/auth/login`
avec `{"nom":"Alice NGONO","matricule":"ADM-1007","motDePasse":"1234"}`.

### 3. Frontend Flutter
```bat
cd frontend_flutter
flutter create --org com.socadel .   REM régénère les fichiers binaires Android manquants
flutter pub get
flutter run
```
- **Émulateur Android** : l'application appelle `http://10.0.2.2:8080/api` (déjà configuré).
- **Téléphone physique** : remplacer l'adresse dans `lib/core/api_config.dart`
  par l'IP du PC (ex. `http://192.168.1.20:8080/api`).
- **Cartographie** : OpenStreetMap (`flutter_map`), gratuite et sans clé API,
  fonctionne directement.
- **Logo** : copier `logo.jpeg` de l'entreprise dans `frontend_flutter/assets/`.

## Sécurité : une API ou deux API ? (question du cahier des charges)

**Deux API distinctes** — c'est le choix retenu, voir la réponse détaillée
dans le compte rendu du projet et la section 3.3 du cahier des charges :
l'API Frontend (exposée) et l'API Backend (interne) ne sont jamais confondues,
ce qui réduit la surface d'attaque, permet un double contrôle du jeton JWT et
masque la structure interne du système au mobile.
