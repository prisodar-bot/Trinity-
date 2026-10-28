USE ressourcerie;

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
    role ENUM('utilisateur', 'admin', 'benevole') DEFAULT 'utilisateur',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    categorie VARCHAR(100),
    etat VARCHAR(50),
    date_don DATE,
    statut ENUM('propose', 'accepte', 'refuse', 'recupere') DEFAULT 'propose',
    statut_vente ENUM('disponible', 'vendu', 'retire') DEFAULT 'disponible',
    utilisateur_id INT,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE TABLE ateliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    date_atelier DATETIME NOT NULL,
    lieu VARCHAR(150),
    capacite INT NOT NULL CHECK (capacite > 0),
    createur_id INT,
    FOREIGN KEY (createur_id) REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE TABLE inscriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    atelier_id INT NOT NULL,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    date_inscription TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (atelier_id) REFERENCES ateliers(id) ON DELETE CASCADE,
    UNIQUE (atelier_id, email)
);

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

CREATE TABLE permanences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date_debut DATETIME NOT NULL,
    date_fin DATETIME NOT NULL,
    nb_places INT NOT NULL DEFAULT 1 CHECK (nb_places > 0),
    CHECK (date_fin > date_debut)
);

CREATE TABLE reservations_permanence (
    permanence_id INT NOT NULL,
    utilisateur_id INT NOT NULL,
    PRIMARY KEY (permanence_id, utilisateur_id),
    FOREIGN KEY (permanence_id) REFERENCES permanences(id) ON DELETE CASCADE,
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

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
    libelle VARCHAR(150) NOT NULL,
    accepte BOOLEAN NOT NULL
);

CREATE TABLE horaires (
    id INT AUTO_INCREMENT PRIMARY KEY,
    jour ENUM('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche') NOT NULL UNIQUE,
    heure_ouverture TIME,
    heure_fermeture TIME,
    ferme BOOLEAN NOT NULL DEFAULT FALSE
);