# Explication des deux API du backend SOCADEL Géoloc

> Document de vulgarisation : chaque rubrique est expliquée en environ
> 50 mots, avec des mots simples, pour une personne qui a peu de notions
> en informatique.

**L'image à garder en tête** : le backend est un bâtiment d'entreprise.
L'**API Frontend** est la *réceptionniste* à l'entrée : elle vérifie les
badges et transmet les demandes. L'**API Backend** regroupe les *bureaux
spécialisés* qui font le vrai travail et gardent les *archives* (la base
de données MySQL).

---

## Pourquoi deux API au lieu d'une seule ? (~50 mots)

Pour la sécurité et l'organisation. Le téléphone ne parle qu'à la
réceptionniste (API Frontend), jamais aux bureaux. Un pirate ne voit donc
qu'une seule porte, bien gardée, et ignore comment l'intérieur fonctionne.
Chaque partie a un seul métier : contrôler les entrées d'un côté, traiter
les données de l'autre. C'est aussi l'architecture imposée par le cahier
des charges (section 3.3).

---

# 1. API FRONTEND (dossier `api-frontend`, port 8080)

## Son architecture (~50 mots)

C'est la porte d'entrée unique de l'application mobile : une « passerelle »
(en anglais *BFF, Backend For Frontend*). Elle ne contient aucune donnée et
aucune règle métier. Elle reçoit chaque demande du téléphone, vérifie le
badge numérique (jeton JWT), transmet la demande à l'API Backend, puis
renvoie la réponse telle quelle au téléphone.

## Si elle disparaissait ? (~50 mots)

L'application mobile ne pourrait plus rien faire : c'est son seul
interlocuteur. Il faudrait exposer l'API Backend directement à Internet,
ce qui serait dangereux : plus de double contrôle des badges, structure
interne visible par tous, surface d'attaque plus grande. C'est comme
retirer la réceptionniste et laisser le public entrer dans les bureaux.

## Ses classes, une par une (~50 mots chacune)

### `ApiFrontendApplication`
C'est le bouton « démarrer » de l'API Frontend. Quand on lance le
programme, cette classe réveille tout le reste : elle ouvre le port 8080,
prépare l'outil qui téléphone à l'API Backend (RestTemplate) et met le
service en attente des demandes. Sans elle, rien ne démarre : le programme
ne serait qu'un dossier de fichiers inertes.

### `PasserelleController`
C'est la réceptionniste elle-même. Chaque demande du téléphone passe par
elle : elle contrôle le badge (jeton JWT), refuse poliment les inconnus
(erreur 401), puis transmet la demande au bon bureau de l'API Backend et
rapporte la réponse — texte, photo ou fichier. Sans elle, plus aucun
échange entre le mobile et le système.

### `JetonVerifier`
C'est la loupe qui examine les badges. Un jeton JWT est un badge numérique
signé ; cette classe vérifie que la signature est authentique (secret
partagé avec l'API Backend) et que le badge n'est pas périmé. Sans elle,
n'importe qui pourrait fabriquer un faux badge et consulter les données de
SOCADEL sans mot de passe.

### `PingController`
C'est la sonnette d'entrée. Le téléphone connaît plusieurs adresses
possibles pour joindre le serveur (Wi-Fi maison, bureau...) ; il « sonne »
à chacune (`/api/auth/ping`) et la première qui répond devient la bonne.
Sans elle, l'application ne saurait pas retrouver automatiquement son
serveur quand on change de réseau Wi-Fi : il faudrait la reconfigurer.

### `CarteController`
C'est le traducteur cartographique. Il demande la liste des compteurs à
l'API Backend puis la met en forme « GeoJSON », le langage standard des
cartes, prêt à être dessiné. C'est la seule mise en forme faite côté
Frontend. Sans lui, cette présentation spéciale carte n'existerait plus,
il faudrait la construire ailleurs.

---

# 2. API BACKEND (dossier `api-backend`, port 8081)

## Son architecture (~50 mots)

C'est le cœur du système, organisé en « microservices » : un bureau par
métier (authentification, compteurs, rapports, statistiques, techniciens).
Chaque bureau suit la même chaîne : le **contrôleur** reçoit la demande,
le **service** applique les règles de gestion, le **repository** lit ou
écrit dans les archives MySQL, et les **DTO** emballent les réponses.

## Si elle disparaissait ? (~50 mots)

Plus rien ne fonctionnerait : la réceptionniste transmettrait les demandes
dans le vide (message « API Backend indisponible »). Plus de connexion,
plus de compteurs, plus de rapports : toute l'intelligence du système —
règles de gestion, calculs, accès à la base de données — vit ici. C'est
comme un hôtel dont tous les employés auraient disparu, sauf la
réceptionniste.

## Ses classes, une par une (~50 mots chacune)

### `ApiBackendApplication`
Le bouton « démarrer » de l'API Backend. Il ouvre le port 8081, connecte
le programme à la base MySQL et réveille tous les bureaux (contrôleurs,
services, repositories). Sans lui, aucun microservice ne démarre et la
réceptionniste n'aurait plus personne à qui transmettre les demandes du
téléphone : le système entier resterait éteint.

### `security/JwtUtil`
Le fabricant de badges. À chaque connexion réussie, il crée le jeton JWT :
une carte d'identité numérique signée (algorithme HMAC-SHA256) contenant le
matricule, le nom et le rôle, valable 24 heures. Sans lui, impossible de
délivrer des badges : personne ne pourrait prouver son identité après la
connexion, donc plus aucun accès.

### `security/JwtFilter`
Le vigile intérieur. Même si la réceptionniste a déjà contrôlé le badge,
lui le revérifie à l'entrée de chaque bureau (double contrôle) et note sur
la demande qui est là et avec quel rôle. C'est ce qui permet le RBACL.
Sans lui, un appel direct au port 8081 contournerait toute la sécurité.

### `config/CorsConfig`
Le règlement d'accès pour navigateurs. Quand l'application tourne dans
Chrome (version web), le navigateur exige une autorisation spéciale pour
appeler un autre serveur : cette classe la donne (règles CORS). Sans elle,
la version web serait bloquée par le navigateur lui-même, même avec un
badge parfaitement valide. Le téléphone, lui, n'en a pas besoin.

### Les 7 entités (`entity/`) — les fiches des archives
Chaque entité est un modèle de fiche qui correspond exactement à une table
MySQL. Sans elles, le programme ne saurait pas lire ni écrire les archives.
En ~50 mots chacune :

- **`Utilisateur`** : la fiche du personnel. Nom, matricule unique, mot de
  passe (jamais en clair : empreinte SHA-256), rôle (technicien ou
  administrateur), zone, téléphone. C'est elle qui permet de savoir qui a
  le droit de faire quoi. Sans elle : plus de comptes, plus de connexion,
  plus de rôles — l'application deviendrait une porte sans serrure.
- **`Compteur`** : la fiche d'un compteur électrique. Référence unique,
  marque, modèle, type, index initial, statut (actif, en panne...),
  adresse et surtout position GPS (latitude/longitude). C'est la matière
  première de la carte. Sans elle : plus d'inventaire des compteurs, plus
  de géolocalisation — le cœur même du projet disparaîtrait.
- **`Zone`** : la fiche d'un quartier de service (Ndogpassi, Akwa...).
  Nom, couleur d'affichage, taux de couverture. Elle sert à regrouper les
  compteurs, colorer la carte et calculer les statistiques par secteur.
  Sans elle : plus de découpage géographique, statistiques et filtres par
  zone impossibles, carte moins lisible pour l'administrateur.
- **`Attribution`** : le registre des affectations. Chaque ligne dit
  « tel compteur a été confié à tel technicien, à telle date ». C'est la
  mémoire des décisions de l'administrateur. Sans elle : on saurait encore
  qui s'occupe d'un compteur aujourd'hui, mais tout l'historique des
  affectations passées serait perdu.
- **`RapportInspection`** : la fiche de compte rendu de visite. État
  constaté, anomalies, observations, photo et fichier joints (stockés en
  octets), position GPS, horodatage, puis avis de l'administrateur
  (validé/rejeté + commentaire). Sans elle : les techniciens ne pourraient
  plus rien rapporter, l'administrateur ne pourrait plus rien contrôler.
- **`HistoriqueLocalisation`** : le carnet de bord GPS. Chaque visite y
  ajoute la position exacte capturée, la date et le technicien. Il permet
  l'historique d'un compteur et le suivi des déplacements des équipes.
  Sans elle : plus de traçabilité des visites sur le terrain ni de page
  « Suivi des déplacements ».
- **`JournalAudit`** : le registre de sécurité (norme ISO 27001). Chaque
  action sensible y est notée : qui, quoi, quand — connexions, envois de
  rapports, suppressions... Sans elle : impossible de prouver qui a fait
  quoi en cas de litige ou de fraude ; la page « Journal d'audit »
  n'aurait plus rien à afficher.

### Les 7 repositories (`repository/`) — les archivistes
Ce sont des interfaces : on y écrit seulement le *nom* de la recherche
souhaitée (« trouver les compteurs d'un technicien, triés par référence »)
et Spring fabrique tout seul la requête SQL correspondante. Un archiviste
par type de fiche : `UtilisateurRepository`, `CompteurRepository`,
`ZoneRepository`, `AttributionRepository`, `RapportInspectionRepository`,
`HistoriqueLocalisationRepository`, `JournalAuditRepository`. Sans eux,
il faudrait écrire chaque requête SQL à la main — long et source d'erreurs
— et les services ne pourraient plus ni lire ni enregistrer quoi que ce
soit dans MySQL.

### Les 11 DTO (`dto/`) — les enveloppes
Un DTO (*Data Transfer Object*) est une enveloppe : il transporte
exactement les informations à échanger, ni plus ni moins. On ne montre
jamais la fiche d'archive brute — par exemple, jamais le mot de passe.
Enveloppes d'**entrée** (ce que le mobile envoie) : `LoginRequest`
(identifiants), `UtilisateurRequest` (création/modification d'un compte),
`CompteurRequest` (fiche compteur), `RapportRequest` (rapport + pièces
jointes en Base64), `AvisRequest` (décision de l'admin), `ProfilRequest`
(nom, téléphone, mot de passe). Enveloppes de **sortie** (ce que le serveur
renvoie) : `LoginResponse` (badge JWT + profil), `UtilisateurDto`,
`CompteurDto`, `RapportDto`, `HistoriqueDto`. Sans elles : on exposerait
des secrets (mots de passe) et le moindre changement interne casserait
l'application mobile.

### `service/AuthService`
Le bureau de la sécurité des personnes. Il vérifie les identifiants en
comparant les empreintes SHA-256 des mots de passe, détermine le rôle
(RBACL), demande un badge à JwtUtil et gère la page profil (nom, téléphone,
mot de passe). Sans lui : plus personne ne pourrait se connecter ni prouver
son identité.

### `service/CompteurService`
Le bureau des compteurs. Il applique les règles de gestion : référence
unique, création, modification, suppression, recherche par numéro, filtre
par statut, attribution à un technicien (enregistrée dans le registre) et
historique d'un compteur. Chaque action sensible est notée au journal.
Sans lui : plus aucune gestion du parc de compteurs.

### `service/RapportService`
Le bureau des comptes rendus. À l'envoi d'un rapport, il fait tout d'un
coup (transaction) : enregistre le rapport et ses pièces jointes, met à
jour le statut du compteur sur la carte, note la position GPS au carnet de
bord et trace l'action. Il gère aussi l'avis de l'administrateur. Sans
lui : plus de rapports.

### `service/UtilisateurService`
Le bureau du personnel. Réservé à l'administrateur : créer un compte
technicien (matricule unique), modifier, rechercher, supprimer, et
promouvoir ou rétrograder un administrateur. Chaque opération est inscrite
au journal d'audit. Sans lui : impossible de faire évoluer l'équipe —
aucun nouveau technicien ne pourrait recevoir de compte ni de compteurs.

### `service/StatistiqueService`
Le bureau des chiffres. Il calcule les indicateurs du tableau de bord
(total, pannes, taux, couverture), les statistiques par zone, crée les
nouvelles zones et produit le « Suivi des déplacements » : distance
parcourue (formule de haversine), temps de trajet estimé et compteurs
inspectés par technicien. Sans lui : l'administrateur piloterait à
l'aveugle.

### `service/AuditService`
Le greffier. Une seule mission : inscrire chaque action sensible au
registre (« Alice NGONO — Validation du rapport R12 — 07/07/2026 14:03 »)
et relire ce registre pour la page Journal d'audit. Tous les autres bureaux
font appel à lui. Sans lui : plus aucune traçabilité, et une exigence du
cahier des charges (ISO 27001) non respectée.

### Les 5 contrôleurs (`controller/`) — les guichets
Chaque contrôleur est le guichet d'un bureau : il reçoit la demande HTTP
transmise par la réceptionniste, vérifie sa forme (et parfois le rôle,
ex. réservé ADMIN), confie le travail au service, puis renvoie l'enveloppe
réponse ou un message d'erreur clair. `AuthController` (connexion, profil),
`CompteurController` (compteurs, attribution, historique),
`RapportController` (rapports, photo, fichier joint), `UtilisateurController`
(comptes techniciens, RBACL admin), `StatistiqueController` (tableau de
bord, zones, suivi, audit). Sans eux : les bureaux existeraient mais
n'auraient aucun guichet — aucune demande ne pourrait leur parvenir.

---

## En résumé

| | API Frontend (8080) | API Backend (8081) |
|---|---|---|
| Image | La réceptionniste | Les bureaux et les archives |
| Rôle | Contrôler les badges, transmettre | Décider, calculer, enregistrer |
| Contient des données ? | Non | Oui (via MySQL) |
| Exposée au téléphone ? | Oui, seule porte d'entrée | Non, jamais |
| Si elle tombe ? | Plus d'accès à l'application | Plus aucun traitement possible |
