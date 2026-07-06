-- ============================================================================
-- SOCADEL GEOLOC - Base de donnees MySQL (XAMPP 8.2.12, MySQL/MariaDB, port 3306)
-- Application mobile de geolocalisation des compteurs electriques - Douala
-- ----------------------------------------------------------------------------
-- Importation :
--   1. Demarrer MySQL depuis le panneau de controle XAMPP
--   2. Ouvrir http://localhost/phpmyadmin  ->  onglet "Importer"  ->  ce fichier
--      (ou en ligne de commande :  c:\xampp\mysql\bin\mysql.exe -u root < socadel_geoloc.sql)
--
-- Mot de passe des comptes de demonstration : 1234
-- (stocke sous forme de hachage SHA-256, conformement au cahier des charges)
-- Comptes : Jean MBALLA / TECH-2043  (technicien)
--           Alice NGONO / ADM-1007   (administrateur)
-- ============================================================================

DROP DATABASE IF EXISTS socadel_geoloc;
CREATE DATABASE socadel_geoloc CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE socadel_geoloc;

-- ----------------------------------------------------------------------------
-- Table ZONE : zones de service de l'agence de Koumassi
-- ----------------------------------------------------------------------------
CREATE TABLE zone (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  nom         VARCHAR(80)  NOT NULL UNIQUE,
  couleur     VARCHAR(10)  NOT NULL DEFAULT '#15357a',
  couverture  INT          NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table UTILISATEUR : techniciens et administrateurs (RBACL)
-- Authentification unifiee : nom + matricule (unique) + mot de passe (hache)
-- ----------------------------------------------------------------------------
CREATE TABLE utilisateur (
  id            BIGINT AUTO_INCREMENT PRIMARY KEY,
  nom           VARCHAR(120) NOT NULL,
  matricule     VARCHAR(30)  NOT NULL UNIQUE,
  mot_de_passe  VARCHAR(64)  NOT NULL COMMENT 'Hachage SHA-256',
  role          ENUM('TECHNICIEN','ADMIN') NOT NULL DEFAULT 'TECHNICIEN',
  zone          VARCHAR(80),
  telephone     VARCHAR(30)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table COMPTEUR : fiche compteur (reference, marque, modele, type, index)
-- + localisation du point de livraison (latitude / longitude / quartier)
-- ----------------------------------------------------------------------------
CREATE TABLE compteur (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  reference      VARCHAR(30)  NOT NULL UNIQUE,
  marque         VARCHAR(60),
  modele         VARCHAR(60),
  type           VARCHAR(40)  NOT NULL DEFAULT 'Prépayé STS1',
  index_initial  VARCHAR(20)  NOT NULL DEFAULT '00000',
  statut         ENUM('NON_INSPECTE','ACTIF','MAINTENANCE','PANNE','AUTRE') NOT NULL DEFAULT 'NON_INSPECTE',
  statut_autre   VARCHAR(120),
  quartier       VARCHAR(160) COMMENT 'Adresse du point de livraison',
  latitude       DECIMAL(10,6) NOT NULL,
  longitude      DECIMAL(10,6) NOT NULL,
  zone_id        BIGINT,
  technicien_id  BIGINT COMMENT 'Technicien actuellement attribue',
  CONSTRAINT fk_compteur_zone       FOREIGN KEY (zone_id)       REFERENCES zone(id)        ON DELETE SET NULL,
  CONSTRAINT fk_compteur_technicien FOREIGN KEY (technicien_id) REFERENCES utilisateur(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table ATTRIBUTION : historique des affectations compteur -> technicien
-- ----------------------------------------------------------------------------
CREATE TABLE attribution (
  id                BIGINT AUTO_INCREMENT PRIMARY KEY,
  compteur_id       BIGINT NOT NULL,
  technicien_id     BIGINT,
  date_attribution  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_attr_compteur   FOREIGN KEY (compteur_id)   REFERENCES compteur(id)    ON DELETE CASCADE,
  CONSTRAINT fk_attr_technicien FOREIGN KEY (technicien_id) REFERENCES utilisateur(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table RAPPORT_INSPECTION : rapport envoye par le technicien a l'administrateur
-- (etat, anomalies, observations, photo, GPS, horodatage, avis de l'admin)
-- ----------------------------------------------------------------------------
CREATE TABLE rapport_inspection (
  id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
  compteur_id        BIGINT NOT NULL,
  technicien_id      BIGINT,
  date_intervention  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Horodatage automatique',
  etat               ENUM('ACTIF','MAINTENANCE','PANNE','AUTRE') NOT NULL,
  etat_autre         VARCHAR(120),
  anomalies          TEXT COMMENT 'Anomalies separees par des points-virgules',
  observations       TEXT,
  photo              TINYINT(1) NOT NULL DEFAULT 0,
  fichier            VARCHAR(190),
  latitude           DECIMAL(10,6) COMMENT 'Position GPS capturee lors de la visite',
  longitude          DECIMAL(10,6),
  statut             ENUM('EN_ATTENTE','VALIDE','REJETE') NOT NULL DEFAULT 'EN_ATTENTE',
  commentaire_admin  TEXT,
  CONSTRAINT fk_rapport_compteur   FOREIGN KEY (compteur_id)   REFERENCES compteur(id)    ON DELETE CASCADE,
  CONSTRAINT fk_rapport_technicien FOREIGN KEY (technicien_id) REFERENCES utilisateur(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table HISTORIQUE_LOCALISATION : positions GPS enregistrees lors des visites
-- ----------------------------------------------------------------------------
CREATE TABLE historique_localisation (
  id             BIGINT AUTO_INCREMENT PRIMARY KEY,
  compteur_id    BIGINT NOT NULL,
  technicien_id  BIGINT,
  latitude       DECIMAL(10,6) NOT NULL,
  longitude      DECIMAL(10,6) NOT NULL,
  date_capture   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note           VARCHAR(255),
  CONSTRAINT fk_hist_compteur   FOREIGN KEY (compteur_id)   REFERENCES compteur(id)    ON DELETE CASCADE,
  CONSTRAINT fk_hist_technicien FOREIGN KEY (technicien_id) REFERENCES utilisateur(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Table JOURNAL_AUDIT : tracabilite des actions sensibles (ISO 27001)
-- ----------------------------------------------------------------------------
CREATE TABLE journal_audit (
  id           BIGINT AUTO_INCREMENT PRIMARY KEY,
  utilisateur  VARCHAR(120) NOT NULL,
  action       VARCHAR(255) NOT NULL,
  date_action  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================================
-- DONNEES DE DEMONSTRATION (localisations fictives mais realistes - Douala)
-- ============================================================================

INSERT INTO zone (nom, couleur, couverture) VALUES
  ('Koumassi', '#15357a', 88),
  ('New-Bell', '#1763c7', 74),
  ('Deïdo',    '#1f9d55', 81),
  ('Akwa',     '#d98a00', 92),
  ('Bassa',    '#7a4fb5', 69);

-- Mot de passe '1234' hache en SHA-256
SET @mdp = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';

INSERT INTO utilisateur (nom, matricule, mot_de_passe, role, zone, telephone) VALUES
  ('Jean MBALLA',  'TECH-2043', @mdp, 'TECHNICIEN', 'Koumassi',       '+237 6 99 12 34 56'),
  ('Alice NGONO',  'ADM-1007',  @mdp, 'ADMIN',      'Siège Koumassi', '+237 6 77 00 11 22'),
  ('Paul ETONDE',  'TECH-2044', @mdp, 'TECHNICIEN', 'Akwa',           '+237 6 90 55 66 77'),
  ('Marie FOTSO',  'TECH-2051', @mdp, 'TECHNICIEN', 'Bassa',          '+237 6 95 33 44 55'),
  ('Yves KAMGA',   'TECH-2068', @mdp, 'TECHNICIEN', 'Deïdo',          '+237 6 91 22 33 44'),
  ('Brice NJOYA',  'ADM-1012',  @mdp, 'ADMIN',      'Siège Koumassi', '+237 6 78 99 88 77');

INSERT INTO compteur (reference, marque, modele, type, index_initial, statut, quartier, latitude, longitude, zone_id, technicien_id) VALUES
  ('CPT-001432', 'HEXING',    '0142',   'Prépayé STS1', '00412', 'ACTIF',        'Rue 2.045, Koumassi',            4.043200, 9.739800, 1, 1),
  ('CPT-001876', 'INHEMETER', '3723',   'Prépayé STS1', '01290', 'NON_INSPECTE', 'Rue 2.112, Koumassi',            4.041500, 9.742600, 1, 1),
  ('CPT-002301', 'DONSUN',    '017900', 'Prépayé STS2', '00088', 'PANNE',        'Bd de la Liberté, Koumassi',     4.039800, 9.737100, 1, 1),
  ('CPT-002654', 'GENTAI',    '026',    'Prépayé STS2', '03471', 'MAINTENANCE',  'Rue Bonadibong, New-Bell',       4.046900, 9.716400, 2, 1),
  ('CPT-003012', 'HEXING',    '0143',   'Prépayé STS1', '00765', 'NON_INSPECTE', 'Rue 2.301, Koumassi',            4.038400, 9.741200, 1, 1),
  ('CPT-003489', 'INHEMETER', '3724',   'Prépayé STS1', '02158', 'ACTIF',        'Rue Deïdo Centre',               4.069800, 9.701900, 3, 1),
  ('CPT-004120', 'DONSUN',    '017900', 'Prépayé STS2', '00910', 'ACTIF',        'Bd de la Réunification, Akwa',   4.051200, 9.708100, 4, 3),
  ('CPT-004552', 'GENTAI',    '026',    'Prépayé STS2', '01840', 'NON_INSPECTE', 'Rue Joss, Akwa',                 4.048700, 9.695500, 4, 3),
  ('CPT-005003', 'HEXING',    '0144',   'Prépayé STS1', '00233', 'PANNE',        'Zone industrielle Bassa',        4.028900, 9.738800, 5, 4),
  ('CPT-005477', 'INHEMETER', '3723',   'Prépayé STS1', '04102', 'ACTIF',        'Rue Ndogpassi, Bassa',           4.022400, 9.752300, 5, 4),
  ('CPT-005901', 'DONSUN',    '017900', 'Prépayé STS2', '00540', 'MAINTENANCE',  'Rue Deïdo Marché',               4.073500, 9.697200, 3, 3),
  ('CPT-006330', 'GENTAI',    '026',    'Prépayé STS2', '02770', 'NON_INSPECTE', 'Rue Madagascar, New-Bell',       4.042100, 9.712800, 2, 4),
  ('CPT-006788', 'HEXING',    '0142',   'Prépayé STS1', '00019', 'NON_INSPECTE', 'Rue 2.401, Koumassi',            4.036700, 9.744900, 1, NULL),
  ('CPT-007145', 'INHEMETER', '3724',   'Postpayé',     '05630', 'AUTRE',        'Av. de Gaulle, Akwa',            4.053800, 9.692400, 4, 3);

INSERT INTO attribution (compteur_id, technicien_id, date_attribution) VALUES
  (1, 1, '2026-06-15 08:00:00'), (2, 1, '2026-06-15 08:00:00'), (3, 1, '2026-06-15 08:00:00'),
  (4, 1, '2026-06-15 08:00:00'), (5, 1, '2026-06-15 08:00:00'), (6, 1, '2026-06-15 08:00:00'),
  (7, 3, '2026-06-15 08:05:00'), (8, 3, '2026-06-15 08:05:00'), (11, 3, '2026-06-15 08:05:00'),
  (14, 3, '2026-06-15 08:05:00'), (9, 4, '2026-06-15 08:10:00'), (10, 4, '2026-06-15 08:10:00'),
  (12, 4, '2026-06-15 08:10:00');

INSERT INTO rapport_inspection
  (compteur_id, technicien_id, date_intervention, etat, etat_autre, anomalies, observations, photo, latitude, longitude, statut, commentaire_admin) VALUES
  (1,  1, '2026-06-22 09:14:00', 'ACTIF', NULL, NULL, 'Compteur opérationnel, scellé intact.', 1, 4.042100, 9.729800, 'VALIDE', 'Bon travail, RAS.'),
  (3,  1, '2026-06-21 15:40:00', 'PANNE', NULL, 'Afficheur HS;Suspicion de fraude', 'Afficheur éteint, scellé brisé.', 1, 4.039800, 9.726100, 'EN_ATTENTE', NULL),
  (7,  3, '2026-06-23 10:20:00', 'ACTIF', NULL, NULL, 'RAS.', 0, 4.051200, 9.708100, 'EN_ATTENTE', NULL),
  (9,  4, '2026-06-18 14:11:00', 'PANNE', NULL, 'Câblage endommagé', 'Câblage endommagé par travaux voisins.', 1, 4.028900, 9.738800, 'VALIDE', 'Intervention de réparation à planifier.'),
  (4,  1, '2026-06-20 11:02:00', 'MAINTENANCE', NULL, NULL, 'Remplacement du boîtier programmé.', 0, 4.046900, 9.716400, 'VALIDE', 'OK.'),
  (14, 3, '2026-06-24 13:45:00', 'AUTRE', 'Compteur déplacé', 'Compteur introuvable', 'Compteur introuvable à l''adresse, déplacé par le client.', 1, 4.053800, 9.692400, 'EN_ATTENTE', NULL);

INSERT INTO historique_localisation (compteur_id, technicien_id, latitude, longitude, date_capture, note) VALUES
  (1,  1, 4.042100, 9.729800, '2026-06-22 09:14:00', 'Capture lors de l''inspection'),
  (3,  1, 4.039800, 9.726100, '2026-06-21 15:40:00', 'Capture lors de l''inspection'),
  (7,  3, 4.051200, 9.708100, '2026-06-23 10:20:00', 'Capture lors de l''inspection'),
  (9,  4, 4.028900, 9.738800, '2026-06-18 14:11:00', 'Capture lors de l''inspection'),
  (4,  1, 4.046900, 9.716400, '2026-06-20 11:02:00', 'Capture lors de l''inspection'),
  (14, 3, 4.053800, 9.692400, '2026-06-24 13:45:00', 'Capture lors de l''inspection');

INSERT INTO journal_audit (utilisateur, action, date_action) VALUES
  ('Paul ETONDE',  'Envoi rapport d''inspection · CPT-007145', '2026-06-24 13:45:00'),
  ('Paul ETONDE',  'Envoi rapport d''inspection · CPT-004120', '2026-06-23 10:20:00'),
  ('Alice NGONO',  'Validation du rapport R01',                '2026-06-22 16:02:00'),
  ('Jean MBALLA',  'Capture GPS · CPT-001432',                 '2026-06-22 09:14:00'),
  ('Alice NGONO',  'Attribution CPT-006788 → (non assigné)',   '2026-06-21 08:30:00'),
  ('Alice NGONO',  'Connexion administrateur',                 '2026-06-20 17:50:00');
