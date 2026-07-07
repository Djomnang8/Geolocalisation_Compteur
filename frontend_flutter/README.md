# frontend_flutter — SOCADEL Géoloc (application mobile Android)

Application Flutter reproduisant fidèlement la maquette UX/UI
(couleurs bleu/vert/rouge/gris/blanc du logo, polices IBM Plex Sans / Mono).

## Pages réalisées (application complète)

- **Commun** : Splash animé · Connexion (nom + matricule + mot de passe, rôle
  déterminé par RBACL, comptes de démonstration).
- **Espace technicien (7/7)** :
  1. Tableau de bord (KPI personnels, "Itinéraire du jour", "Mes compteurs")
  2. Carte des compteurs attribués (OpenStreetMap, recherche, filtres par statut, légende)
  3. Détail compteur (fiche + historique des interventions en feuille)
  4. Formulaire d'inspection (état, anomalies, observations, pièces jointes
     réelles — photo caméra/galerie + fichier —, capture GPS, envoi du rapport)
  5. Itinéraire du jour (trajet optimisé sur la carte, distance de chaque
     compteur, chemin tracé par OSRM, temps estimé en voiture et à pied)
  6. Mes rapports (statut du traitement + avis de l'administrateur)
  7. Mon profil (modification du nom / mot de passe, déconnexion)
- **Espace administrateur (14/14)** :
  1. Tableau de bord (KPI, compteurs par zone, rapports récents)
  2. Carte de Douala (tous les compteurs + fiche rapide)
  3. Gestion des compteurs (CRUD, recherche, filtres)
  4. Fiche compteur (ajout/modification + attribution à un technicien)
  5. Rapports d'inspection (recherche par technicien/zone, filtres par statut
     du rapport et par état du compteur, sélecteur de plage de dates)
  6. Détail du rapport (photo de l'inspection affichée + zoom, fichier joint
     ouvrable, valider / rejeter + commentaire)
  7. Techniciens (CRUD, recherche, promouvoir/retirer admin)
  8. Fiche technicien (+ interrupteur "Rôle administrateur")
  9. Attribution des compteurs (sélecteur de technicien avec recherche)
  10. Zones de service (statistiques par zone + création de zone)
  11. Statistiques par zone (barres + export CSV lisible dans Excel)
  12. Suivi des déplacements (dernière position, temps de trajet, distance,
      compteurs inspectés par technicien)
  13. Journal d'audit (filtres utilisateur / date / type, frise chronologique)
  14. Mon profil

## Lancer l'application

```bat
flutter create --org com.socadel .   REM une seule fois : régénère les binaires Android
flutter pub get
flutter run
```

Configuration :
- `lib/core/api_config.dart` : adresse de l'API Frontend
  (émulateur : `http://10.0.2.2:8080/api` ; téléphone : IP du PC).
- Cartographie : OpenStreetMap (`flutter_map`), gratuite et sans clé API,
  aucune configuration nécessaire.
- `assets/logo.jpeg` : copier le logo de l'entreprise (sinon une icône de
  remplacement est affichée).

## Structure

```
lib/
├── core/        couleurs de la charte, config API (multi-IP), session (JWT + profil)
├── models/      Utilisateur, Compteur, Rapport
├── services/    client HTTP (JWT + binaire) + auth, compteurs, rapports,
│                techniciens, stats/zones/suivi/audit, itinéraires (OSRM)
├── widgets/     composants de la maquette (cartes, badges, puces, champs,
│                carte OpenStreetMap des compteurs...)
└── pages/
    ├── splash_page.dart · login_page.dart · profile_page.dart
    ├── tech/    shell + tableau de bord, carte, détail compteur, inspection,
    │            itinéraire du jour, mes rapports
    └── admin/   shell + tableau de bord, carte, compteurs, fiche compteur,
                 rapports, détail rapport, techniciens, fiche technicien,
                 attribution, zones, statistiques, suivi, journal d'audit
```
