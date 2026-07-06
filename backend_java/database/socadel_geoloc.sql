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
-- DONNEES DE DEMONSTRATION - 30 compteurs geolocalises dans Douala :
--   . 3 boutiques a Ndogpassi
--   . 2 hopitaux a Yassa
--   . 2 ecoles a Nyalla
--   . 3 entreprises a Logbaba
--   . 5 entreprises/ecoles sur l'axe Bonapriso - Bonanjo - Koumassi - Akwa
--   . 10 maisons/restaurants sur l'axe Bonapriso - Bali - PK12 - PK14
--   . 5 boutiques a Akwa
-- ============================================================================

INSERT INTO zone (nom, couleur, couverture) VALUES
  ('Ndogpassi',          '#15357a', 85),   -- 1
  ('Yassa',              '#1763c7', 78),   -- 2
  ('Nyalla',             '#1f9d55', 82),   -- 3
  ('Logbaba',            '#d98a00', 74),   -- 4
  ('Bonapriso-Bonanjo',  '#7a4fb5', 90),   -- 5
  ('Koumassi',           '#0f8a8a', 88),   -- 6
  ('Akwa',               '#c2452e', 92),   -- 7
  ('Bali - PK14',        '#5a6b7a', 70);   -- 8

-- Mot de passe '1234' hache en SHA-256
SET @mdp = '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';

INSERT INTO utilisateur (nom, matricule, mot_de_passe, role, zone, telephone) VALUES
  ('Jean MBALLA',  'TECH-2043', @mdp, 'TECHNICIEN', 'Koumassi',          '+237 6 99 12 34 56'),  -- 1
  ('Alice NGONO',  'ADM-1007',  @mdp, 'ADMIN',      'Siège Koumassi',    '+237 6 77 00 11 22'),  -- 2
  ('Paul ETONDE',  'TECH-2044', @mdp, 'TECHNICIEN', 'Akwa',              '+237 6 90 55 66 77'),  -- 3
  ('Marie FOTSO',  'TECH-2051', @mdp, 'TECHNICIEN', 'Ndogpassi',         '+237 6 95 33 44 55'),  -- 4
  ('Yves KAMGA',   'TECH-2068', @mdp, 'TECHNICIEN', 'Logbaba',           '+237 6 91 22 33 44'),  -- 5
  ('Brice NJOYA',  'ADM-1012',  @mdp, 'ADMIN',      'Siège Koumassi',    '+237 6 78 99 88 77');  -- 6

INSERT INTO compteur (reference, marque, modele, type, index_initial, statut, quartier, latitude, longitude, zone_id, technicien_id) VALUES
  -- 3 boutiques a Ndogpassi (zone 1, technicienne Marie FOTSO)
  ('CPT-001432', 'HEXING',    '0142',   'Prépayé STS1', '00412', 'ACTIF',        'Boutique Chez Mado, Ndogpassi II',                4.016500, 9.766200, 1, 4),
  ('CPT-001518', 'INHEMETER', '3723',   'Prépayé STS1', '01290', 'NON_INSPECTE', 'Boutique La Grâce, carrefour Ndogpassi',          4.019800, 9.760900, 1, 4),
  ('CPT-001694', 'DONSUN',    '017900', 'Prépayé STS2', '00088', 'PANNE',        'Boutique Étoile du Sud, Ndogpassi III',           4.012700, 9.771400, 1, 4),
  -- 2 hopitaux a Yassa (zone 2, technicienne Marie FOTSO)
  ('CPT-002045', 'GENTAI',    '026',    'Postpayé',     '18740', 'ACTIF',        'Hôpital Gynéco-Obstétrique et Pédiatrique, Yassa', 4.001200, 9.794500, 2, 4),
  ('CPT-002210', 'HEXING',    '0144',   'Postpayé',     '09215', 'MAINTENANCE',  'Centre hospitalier de Yassa, route de Japoma',    3.995800, 9.801300, 2, 4),
  -- 2 ecoles a Nyalla (zone 3, technicienne Marie FOTSO)
  ('CPT-002478', 'INHEMETER', '3724',   'Prépayé STS1', '02158', 'NON_INSPECTE', 'École publique de Nyalla',                        4.024600, 9.771800, 3, 4),
  ('CPT-002593', 'DONSUN',    '017900', 'Prépayé STS2', '00910', 'NON_INSPECTE', 'Collège bilingue de Nyalla',                      4.027900, 9.766500, 3, 4),
  -- 3 entreprises a Logbaba (zone 4, technicien Yves KAMGA)
  ('CPT-003067', 'GENTAI',    '026',    'Postpayé',     '31840', 'NON_INSPECTE', 'Société industrielle, zone Logbaba',              4.038400, 9.772600, 4, 5),
  ('CPT-003184', 'HEXING',    '0143',   'Postpayé',     '00233', 'PANNE',        'Entrepôt de distribution, Logbaba',               4.041700, 9.778900, 4, 5),
  ('CPT-003342', 'INHEMETER', '3723',   'Postpayé',     '04102', 'NON_INSPECTE', 'Usine de transformation, Logbaba gare',           4.036200, 9.768100, 4, 5),
  -- 5 entreprises/ecoles sur l'axe Bonapriso - Bonanjo - Koumassi - Akwa (technicien Jean MBALLA / Paul ETONDE)
  ('CPT-004120', 'DONSUN',    '017900', 'Postpayé',     '00540', 'ACTIF',        'Collège de Bonapriso, rue Njo-Njo',               4.034100, 9.693800, 5, 1),
  ('CPT-004256', 'GENTAI',    '026',    'Postpayé',     '02770', 'NON_INSPECTE', 'Immeuble d''affaires, Bonanjo',                   4.042600, 9.686900, 5, 1),
  ('CPT-004399', 'HEXING',    '0142',   'Prépayé STS1', '00019', 'ACTIF',        'École primaire de Koumassi',                      4.044300, 9.711500, 6, 1),
  ('CPT-004481', 'INHEMETER', '3724',   'Postpayé',     '05630', 'MAINTENANCE',  'PME de services, carrefour Koumassi',             4.046800, 9.705900, 6, 1),
  ('CPT-004577', 'DONSUN',    '017900', 'Prépayé STS2', '01463', 'NON_INSPECTE', 'École bilingue d''Akwa',                          4.048900, 9.699400, 7, 3),
  -- 10 maisons/restaurants sur l'axe Bonapriso - Bali - PK12 - PK14
  ('CPT-005003', 'HEXING',    '0144',   'Prépayé STS1', '00765', 'NON_INSPECTE', 'Maison, Bonapriso Sud',                           4.036200, 9.696300, 5, 1),
  ('CPT-005129', 'INHEMETER', '3723',   'Prépayé STS1', '03471', 'ACTIF',        'Restaurant Le Palmier, Bali',                     4.044100, 9.702700, 8, 5),
  ('CPT-005248', 'GENTAI',    '026',    'Prépayé STS2', '00654', 'NON_INSPECTE', 'Maison, Bali Est',                                4.046200, 9.712500, 8, 5),
  ('CPT-005316', 'DONSUN',    '017900', 'Prépayé STS1', '01822', 'NON_INSPECTE', 'Maison, PK8 route de Yaoundé',                    4.047900, 9.752600, 8, 5),
  ('CPT-005477', 'HEXING',    '0142',   'Prépayé STS1', '02047', 'PANNE',        'Restaurant Chez Tanty, PK9',                      4.049100, 9.768400, 8, 5),
  ('CPT-005562', 'INHEMETER', '3724',   'Prépayé STS1', '00389', 'NON_INSPECTE', 'Maison, PK10',                                    4.050200, 9.783800, 8, 5),
  ('CPT-005638', 'GENTAI',    '026',    'Prépayé STS2', '01175', 'NON_INSPECTE', 'Restaurant Le Terminus, PK11',                    4.051100, 9.799600, 8, 5),
  ('CPT-005794', 'DONSUN',    '017900', 'Prépayé STS1', '00931', 'MAINTENANCE',  'Maison, PK12',                                    4.052300, 9.815200, 8, 5),
  ('CPT-005861', 'HEXING',    '0143',   'Prépayé STS1', '00246', 'NON_INSPECTE', 'Restaurant La Détente, PK13',                     4.055100, 9.824100, 8, 5),
  ('CPT-005948', 'INHEMETER', '3723',   'Prépayé STS1', '01518', 'AUTRE',        'Maison, PK14',                                    4.058200, 9.832900, 8, 5),
  -- 5 boutiques a Akwa (zone 7, technicien Paul ETONDE)
  ('CPT-006330', 'GENTAI',    '026',    'Prépayé STS2', '02034', 'ACTIF',        'Boutique Bd de la Liberté, Akwa',                 4.047300, 9.700800, 7, 3),
  ('CPT-006415', 'HEXING',    '0142',   'Prépayé STS1', '00577', 'NON_INSPECTE', 'Boutique Rue Joss, Akwa',                         4.045900, 9.694700, 7, 3),
  ('CPT-006542', 'INHEMETER', '3724',   'Prépayé STS1', '01903', 'PANNE',        'Boutique Av. de Gaulle, Akwa',                    4.050600, 9.697900, 7, 3),
  ('CPT-006788', 'DONSUN',    '017900', 'Prépayé STS2', '00068', 'NON_INSPECTE', 'Boutique Rue Gallieni, Akwa',                     4.049200, 9.702400, 7, NULL),
  ('CPT-007145', 'GENTAI',    '026',    'Prépayé STS1', '02611', 'ACTIF',        'Boutique Bd de la Réunification, Akwa',           4.052400, 9.701100, 7, 3);

INSERT INTO attribution (compteur_id, technicien_id, date_attribution) VALUES
  -- Jean MBALLA (axe Bonapriso - Bonanjo - Koumassi)
  (11, 1, '2026-06-15 08:00:00'), (12, 1, '2026-06-15 08:00:00'), (13, 1, '2026-06-15 08:00:00'),
  (14, 1, '2026-06-15 08:00:00'), (16, 1, '2026-06-15 08:00:00'),
  -- Paul ETONDE (Akwa)
  (15, 3, '2026-06-15 08:05:00'), (26, 3, '2026-06-15 08:05:00'), (27, 3, '2026-06-15 08:05:00'),
  (28, 3, '2026-06-15 08:05:00'), (30, 3, '2026-06-15 08:05:00'),
  -- Marie FOTSO (Ndogpassi, Yassa, Nyalla)
  (1, 4, '2026-06-15 08:10:00'), (2, 4, '2026-06-15 08:10:00'), (3, 4, '2026-06-15 08:10:00'),
  (4, 4, '2026-06-15 08:10:00'), (5, 4, '2026-06-15 08:10:00'), (6, 4, '2026-06-15 08:10:00'),
  (7, 4, '2026-06-15 08:10:00'),
  -- Yves KAMGA (Logbaba, axe Bali - PK14)
  (8, 5, '2026-06-15 08:15:00'), (9, 5, '2026-06-15 08:15:00'), (10, 5, '2026-06-15 08:15:00'),
  (17, 5, '2026-06-15 08:15:00'), (18, 5, '2026-06-15 08:15:00'), (19, 5, '2026-06-15 08:15:00'),
  (20, 5, '2026-06-15 08:15:00'), (21, 5, '2026-06-15 08:15:00'), (22, 5, '2026-06-15 08:15:00'),
  (23, 5, '2026-06-15 08:15:00'), (24, 5, '2026-06-15 08:15:00'), (25, 5, '2026-06-15 08:15:00');

INSERT INTO rapport_inspection
  (compteur_id, technicien_id, date_intervention, etat, etat_autre, anomalies, observations, photo, latitude, longitude, statut, commentaire_admin) VALUES
  (1,  4, '2026-06-22 09:14:00', 'ACTIF',       NULL, NULL, 'Compteur opérationnel, scellé intact.',                       1, 4.016520, 9.766180, 'VALIDE',     'Bon travail, RAS.'),
  (3,  4, '2026-06-21 15:40:00', 'PANNE',       NULL, 'Afficheur HS;Suspicion de fraude', 'Afficheur éteint, scellé brisé.', 1, 4.012680, 9.771430, 'EN_ATTENTE', NULL),
  (4,  4, '2026-06-23 10:20:00', 'ACTIF',       NULL, NULL, 'Compteur de l''hôpital en bon état, local technique propre.', 0, 4.001210, 9.794480, 'VALIDE',     'OK.'),
  (5,  4, '2026-06-24 11:02:00', 'MAINTENANCE', NULL, 'Bornier oxydé', 'Remplacement du bornier programmé.',               1, 3.995810, 9.801270, 'EN_ATTENTE', NULL),
  (9,  5, '2026-06-18 14:11:00', 'PANNE',       NULL, 'Câblage endommagé', 'Câblage endommagé par des travaux voisins.',   1, 4.041690, 9.778920, 'VALIDE',     'Intervention de réparation à planifier.'),
  (11, 1, '2026-06-25 08:47:00', 'ACTIF',       NULL, NULL, 'RAS, index relevé.',                                          0, 4.034120, 9.693790, 'EN_ATTENTE', NULL),
  (13, 1, '2026-06-26 09:33:00', 'ACTIF',       NULL, NULL, 'Compteur de l''école opérationnel.',                          1, 4.044310, 9.711480, 'VALIDE',     'OK.'),
  (14, 1, '2026-06-27 14:05:00', 'MAINTENANCE', NULL, 'Boîtier fissuré', 'Remplacement du boîtier programmé.',             0, 4.046790, 9.705920, 'VALIDE',     'OK.'),
  (17, 5, '2026-06-28 10:15:00', 'ACTIF',       NULL, NULL, 'Compteur du restaurant en bon état.',                         0, 4.044120, 9.702680, 'EN_ATTENTE', NULL),
  (20, 5, '2026-06-29 16:22:00', 'PANNE',       NULL, 'Disjoncteur grillé;Odeur de brûlé', 'Coupure signalée par le gérant.', 1, 4.049080, 9.768430, 'EN_ATTENTE', NULL),
  (23, 5, '2026-06-30 09:50:00', 'MAINTENANCE', NULL, 'Écran peu lisible', 'Nettoyage et resserrage effectués.',           0, 4.052280, 9.815230, 'VALIDE',     'OK.'),
  (25, 5, '2026-07-01 13:45:00', 'AUTRE',       'Compteur déplacé', 'Compteur introuvable', 'Compteur introuvable à l''adresse, déplacé par le client.', 1, 4.058180, 9.832870, 'EN_ATTENTE', NULL),
  (26, 3, '2026-07-02 10:08:00', 'ACTIF',       NULL, NULL, 'RAS.',                                                        0, 4.047310, 9.700830, 'EN_ATTENTE', NULL),
  (28, 3, '2026-07-03 15:30:00', 'PANNE',       NULL, 'Compteur muet;Clavier bloqué', 'Recharge impossible, clavier hors service.', 1, 4.050580, 9.697930, 'EN_ATTENTE', NULL);

INSERT INTO historique_localisation (compteur_id, technicien_id, latitude, longitude, date_capture, note) VALUES
  (1,  4, 4.016520, 9.766180, '2026-06-22 09:14:00', 'Capture lors de l''inspection'),
  (3,  4, 4.012680, 9.771430, '2026-06-21 15:40:00', 'Capture lors de l''inspection'),
  (4,  4, 4.001210, 9.794480, '2026-06-23 10:20:00', 'Capture lors de l''inspection'),
  (5,  4, 3.995810, 9.801270, '2026-06-24 11:02:00', 'Capture lors de l''inspection'),
  (9,  5, 4.041690, 9.778920, '2026-06-18 14:11:00', 'Capture lors de l''inspection'),
  (11, 1, 4.034120, 9.693790, '2026-06-25 08:47:00', 'Capture lors de l''inspection'),
  (13, 1, 4.044310, 9.711480, '2026-06-26 09:33:00', 'Capture lors de l''inspection'),
  (14, 1, 4.046790, 9.705920, '2026-06-27 14:05:00', 'Capture lors de l''inspection'),
  (17, 5, 4.044120, 9.702680, '2026-06-28 10:15:00', 'Capture lors de l''inspection'),
  (20, 5, 4.049080, 9.768430, '2026-06-29 16:22:00', 'Capture lors de l''inspection'),
  (23, 5, 4.052280, 9.815230, '2026-06-30 09:50:00', 'Capture lors de l''inspection'),
  (25, 5, 4.058180, 9.832870, '2026-07-01 13:45:00', 'Capture lors de l''inspection'),
  (26, 3, 4.047310, 9.700830, '2026-07-02 10:08:00', 'Capture lors de l''inspection'),
  (28, 3, 4.050580, 9.697930, '2026-07-03 15:30:00', 'Capture lors de l''inspection');

INSERT INTO journal_audit (utilisateur, action, date_action) VALUES
  ('Paul ETONDE',  'Envoi rapport d''inspection · CPT-006542', '2026-07-03 15:30:00'),
  ('Paul ETONDE',  'Envoi rapport d''inspection · CPT-006330', '2026-07-02 10:08:00'),
  ('Yves KAMGA',   'Envoi rapport d''inspection · CPT-005948', '2026-07-01 13:45:00'),
  ('Alice NGONO',  'Validation du rapport · CPT-005794',       '2026-06-30 16:02:00'),
  ('Jean MBALLA',  'Capture GPS · CPT-004399',                 '2026-06-26 09:33:00'),
  ('Marie FOTSO',  'Envoi rapport d''inspection · CPT-002210', '2026-06-24 11:02:00'),
  ('Alice NGONO',  'Attribution CPT-006788 → (non assigné)',   '2026-06-21 08:30:00'),
  ('Alice NGONO',  'Connexion administrateur',                 '2026-06-20 17:50:00');
