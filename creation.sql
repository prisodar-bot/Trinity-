CREATE DATABASE IF NOT EXISTS ressourcerie CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ressourcerie;

-- Nécessite MySQL 8.0.16+ (CHECK appliqués) et 8.0.13+ (DEFAULT avec expression)

DROP TABLE IF EXISTS reservations_permanence;
DROP TABLE IF EXISTS inscriptions;
DROP TABLE IF EXISTS dons;
DROP TABLE IF EXISTS ateliers;
DROP TABLE IF EXISTS permanences;
DROP TABLE IF EXISTS criteres_don;
DROP TABLE IF EXISTS horaires;
DROP TABLE IF EXISTS utilisateurs;

CREATE TABLE utilisateurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    role ENUM('utilisateur', 'admin', 'benevole') NOT NULL DEFAULT 'utilisateur',
    date_creation TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE dons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    categorie VARCHAR(100),
    etat VARCHAR(50),
    date_don DATE NOT NULL DEFAULT (CURRENT_DATE),
    statut ENUM('propose', 'accepte', 'refuse', 'recupere') NOT NULL DEFAULT 'propose',
    statut_vente ENUM('disponible', 'vendu', 'retire') NOT NULL DEFAULT 'disponible',
    utilisateur_id INT,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL,
    INDEX idx_dons_statut (statut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ateliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    date_atelier DATETIME NOT NULL,
    lieu VARCHAR(150),
    capacite INT NOT NULL CHECK (capacite > 0),
    createur_id INT,
    FOREIGN KEY (createur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL,
    INDEX idx_ateliers_date (date_atelier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE inscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atelier_id INT NOT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    date_inscription TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (atelier_id) REFERENCES ateliers(id) ON DELETE CASCADE,
    UNIQUE (atelier_id, email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bloque l'inscription si l'atelier est complet
DELIMITER //
CREATE TRIGGER verif_capacite_atelier
BEFORE INSERT ON inscriptions
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM inscriptions WHERE atelier_id = NEW.atelier_id)
       >= (SELECT capacite FROM ateliers WHERE id = NEW.atelier_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Atelier complet';
    END IF;
END//
DELIMITER ;

-- Bloque la baisse de capacité sous le nombre d'inscrits
DELIMITER //
CREATE TRIGGER verif_capacite_modif_atelier
BEFORE UPDATE ON ateliers
FOR EACH ROW
BEGIN
    IF NEW.capacite < (SELECT COUNT(*) FROM inscriptions WHERE atelier_id = NEW.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacité inférieure au nombre d''inscrits';
    END IF;
END//
DELIMITER ;

CREATE TABLE permanences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date_debut DATETIME NOT NULL,
    date_fin DATETIME NOT NULL,
    nb_places INT NOT NULL DEFAULT 1 CHECK (nb_places > 0),
    CHECK (date_fin > date_debut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE reservations_permanence (
    permanence_id INT NOT NULL,
    utilisateur_id INT NOT NULL,
    PRIMARY KEY (permanence_id, utilisateur_id),
    FOREIGN KEY (permanence_id) REFERENCES permanences(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER //
CREATE TRIGGER verif_places_permanence
BEFORE INSERT ON reservations_permanence
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM reservations_permanence WHERE permanence_id = NEW.permanence_id)
       >= (SELECT nb_places FROM permanences WHERE id = NEW.permanence_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permanence complète';
    END IF;
END//
DELIMITER ;

CREATE TABLE criteres_don (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(150) NOT NULL UNIQUE,
    accepte BOOLEAN NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE horaires (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jour ENUM('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche') NOT NULL UNIQUE,
    heure_ouverture TIME,
    heure_fermeture TIME,
    ferme BOOLEAN NOT NULL DEFAULT FALSE,
    -- Jour fermé : pas d'heures. Jour ouvert : ouverture avant fermeture.
    CHECK (
        (ferme = TRUE AND heure_ouverture IS NULL AND heure_fermeture IS NULL)
        OR (ferme = FALSE AND heure_ouverture < heure_fermeture)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
