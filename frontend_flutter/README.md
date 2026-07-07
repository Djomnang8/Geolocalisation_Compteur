# frontend_flutter — SOCADEL Géoloc (application mobile Android)

Application Flutter reproduisant fidèlement la maquette UX/UI
(couleurs bleu/vert/rouge/gris/blanc du logo, polices IBM Plex Sans / Mono).

## Pages réalisées (moitié de chaque espace)

- **Commun** : Connexion (nom + matricule + mot de passe, rôle déterminé par RBACL,
  comptes de démonstration).
- **Espace technicien (4/8)** :
  1. Tableau de bord (KPI personnels, "Itinéraire du jour", "Mes compteurs")
  2. Carte des compteurs attribués (OpenStreetMap, recherche, filtres par statut, légende)
  3. Détail compteur (fiche + historique des interventions en feuille)
  4. Formulaire d'inspection (état, anomalies, observations, pièces jointes,
     capture GPS automatique, envoi du rapport)
- **Espace administrateur (8/15)** :
  1. Tableau de bord (KPI, compteurs par zone, rapports récents)
  2. Carte de Douala (tous les compteurs + fiche rapide)
  3. Gestion des compteurs (CRUD, recherche, filtres)
  4. Fiche compteur (ajout/modification + attribution à un technicien)
  5. Rapports d'inspection (filtres En attente / Validés / Rejetés)
  6. Détail du rapport (valider / rejeter + commentaire)
  7. Techniciens (CRUD, recherche, promouvoir/retirer admin)
  8. Fiche technicien (+ interrupteur "Rôle administrateur")

Les onglets/menus restants affichent un écran « seconde moitié du projet ».

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
├── core/        couleurs de la charte, config API, session (JWT + profil)
├── models/      Utilisateur, Compteur, Rapport
├── services/    client HTTP (JWT) + auth, compteurs, rapports, techniciens, stats
├── widgets/     composants de la maquette (cartes, badges, puces, champs...)
└── pages/
    ├── login_page.dart
    ├── tech/    shell + tableau de bord, carte, détail compteur, inspection
    └── admin/   shell + tableau de bord, carte, compteurs, fiche compteur,
                 rapports, détail rapport, techniciens, fiche technicien
```
