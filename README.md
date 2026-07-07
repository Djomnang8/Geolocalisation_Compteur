# SOCADEL Géoloc — Géolocalisation des compteurs électriques (Douala, Koumassi)

Projet de stage — Licence 3 Génie Logiciel, Institut Supérieur KEYCE.
Application mobile **complète** de géolocalisation des compteurs électriques
SOCADEL dans la ville de Douala : toutes les pages de la maquette UX/UI sont
réalisées et connectées au backend.

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

## Pages réalisées (application complète)

| Espace | Pages |
|---|---|
| Commun | Splash animé · Connexion (RBACL) |
| Technicien | Tableau de bord · Carte des compteurs (recherche + filtres) · Détail compteur (+ historique) · Formulaire d'inspection (GPS + pièces jointes réelles) · **Itinéraire du jour** (distance, chemin tracé, temps en voiture et à pied) · Mes rapports (+ avis reçus) · Mon profil |
| Administrateur | Tableau de bord (KPI) · Carte de Douala · Gestion des compteurs (CRUD) · Fiche compteur (+ attribution) · Rapports (**recherche technicien/zone, filtre par état du compteur, plage de dates**) · Détail du rapport (**photo consultable + fichier joint ouvrable**, valider/rejeter) · Techniciens (CRUD + promouvoir admin) · Fiche technicien · Attribution des compteurs · Zones de service (+ création) · Statistiques par zone (+ export CSV/Excel) · Suivi des déplacements · Journal d'audit (filtres) · Mon profil |

Les diagrammes de séquence couverts : authentification RBAC, consultation carte,
recherche par numéro, capture GPS de visite, envoi du rapport d'inspection
(avec pièces jointes), consultation/validation d'un rapport, gestion des
techniciens (CRUD), attribution d'un compteur, tableau de bord et export,
suivi des déplacements, journal d'audit.

L'itinéraire est calculé par le service public **OSRM** (OpenStreetMap,
gratuit, sans clé API) avec repli sur une estimation à vol d'oiseau
hors connexion.

## Installation (Windows + XAMPP 8.2.12)

### 1. Base de données
1. Démarrer **MySQL** dans le panneau XAMPP (port 3306).
2. Ouvrir http://localhost/phpmyadmin → **Importer** →
   `backend_java/database/socadel_geoloc.sql`.

> Le script crée la base `socadel_geoloc` (7 tables, 30 compteurs géolocalisés
> dans Douala). Mot de passe des comptes : `1234` (haché SHA-256).
> Comptes : `Jean MBALLA / TECH-2043` (technicien), `Alice NGONO / ADM-1007` (admin).
> En ligne de commande, toujours utiliser :
> `c:\xampp\mysql\bin\mysql.exe --default-character-set=utf8mb4 -u root < socadel_geoloc.sql`
>
> **Base déjà en place ?** Pour ajouter uniquement les colonnes des pièces
> jointes sans perdre vos données :
> `ALTER TABLE rapport_inspection ADD COLUMN photo_donnees LONGBLOB NULL AFTER photo, ADD COLUMN fichier_donnees LONGBLOB NULL AFTER fichier;`

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
flutter create --org com.socadel 
flutter pub get
flutter run -d chrome
```
- **Émulateur Android** : l'application appelle `http://10.0.2.2:8080/api` (déjà configuré).
- **Téléphone physique** : ajouter l'IP du PC dans `serveursEnregistres`
  (`lib/core/api_config.dart`) — la bonne adresse est détectée automatiquement.
- **Cartographie et itinéraires** : OpenStreetMap + OSRM, gratuits et sans clé
  API — aucune configuration nécessaire.
- **Logo** : copier `logo.jpeg` de l'entreprise dans `frontend_flutter/assets/`.

## Sécurité : une API ou deux API ? (question du cahier des charges)

**Deux API distinctes** — c'est le choix retenu, voir la réponse détaillée
dans le compte rendu du projet et la section 3.3 du cahier des charges :
l'API Frontend (exposée) et l'API Backend (interne) ne sont jamais confondues,
ce qui réduit la surface d'attaque, permet un double contrôle du jeton JWT et
masque la structure interne du système au mobile.
