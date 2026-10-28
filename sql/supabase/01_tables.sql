-- ATTENTION : ce fichier efface et recrée toutes les tables.
-- À lancer uniquement sur une base vide ou pour tout remettre à zéro.

DROP TABLE IF EXISTS reservations_permanence CASCADE;
DROP TABLE IF EXISTS inscriptions CASCADE;
DROP TABLE IF EXISTS dons CASCADE;
DROP TABLE IF EXISTS ateliers CASCADE;
DROP TABLE IF EXISTS permanences CASCADE;
DROP TABLE IF EXISTS criteres_don CASCADE;
DROP TABLE IF EXISTS horaires CASCADE;
DROP TABLE IF EXISTS utilisateurs CASCADE;

DROP TYPE IF EXISTS role_utilisateur;
DROP TYPE IF EXISTS type_statut_don;
DROP TYPE IF EXISTS type_statut_vente;
DROP TYPE IF EXISTS type_jour;

CREATE TYPE role_utilisateur AS ENUM ('utilisateur', 'admin', 'benevole');
CREATE TYPE type_statut_don AS ENUM ('propose', 'accepte', 'refuse', 'recupere');
CREATE TYPE type_statut_vente AS ENUM ('disponible', 'vendu', 'retire');
CREATE TYPE type_jour AS ENUM ('lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche');

CREATE TABLE utilisateurs (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    role role_utilisateur NOT NULL DEFAULT 'utilisateur',
    date_creation TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE dons (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    categorie VARCHAR(100),
    etat VARCHAR(50),
    date_don DATE DEFAULT CURRENT_DATE,
    statut type_statut_don NOT NULL DEFAULT 'propose',
    statut_vente type_statut_vente NOT NULL DEFAULT 'disponible',
    utilisateur_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE TABLE ateliers (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titre VARCHAR(150) NOT NULL,
    description TEXT,
    date_atelier TIMESTAMPTZ NOT NULL,
    lieu VARCHAR(150),
    capacite INT NOT NULL CHECK (capacite > 0),
    createur_id UUID REFERENCES utilisateurs(id) ON DELETE SET NULL
);

CREATE TABLE inscriptions (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    atelier_id INT NOT NULL REFERENCES ateliers(id) ON DELETE CASCADE,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE DEFAULT gen_random_uuid()::text,
    date_inscription TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (atelier_id, email)
);

CREATE TABLE permanences (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_debut TIMESTAMPTZ NOT NULL,
    date_fin TIMESTAMPTZ NOT NULL,
    nb_places INT NOT NULL DEFAULT 1 CHECK (nb_places > 0),
    CHECK (date_fin > date_debut)
);

CREATE TABLE reservations_permanence (
    permanence_id INT NOT NULL REFERENCES permanences(id) ON DELETE CASCADE,
    utilisateur_id UUID NOT NULL REFERENCES utilisateurs(id) ON DELETE CASCADE,
    PRIMARY KEY (permanence_id, utilisateur_id)
);

CREATE TABLE criteres_don (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libelle VARCHAR(150) NOT NULL,
    accepte BOOLEAN NOT NULL
);

CREATE TABLE horaires (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jour type_jour NOT NULL UNIQUE,
    heure_ouverture TIME,
    heure_fermeture TIME,
    ferme BOOLEAN NOT NULL DEFAULT FALSE
);

-- Trigger : bloquer l'inscription si l'atelier est complet
CREATE OR REPLACE FUNCTION verif_capacite_atelier()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF (SELECT COUNT(*) FROM inscriptions WHERE atelier_id = NEW.atelier_id)
       >= (SELECT capacite FROM ateliers WHERE id = NEW.atelier_id) THEN
        RAISE EXCEPTION 'Atelier complet';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_capacite_atelier
BEFORE INSERT ON inscriptions
FOR EACH ROW EXECUTE FUNCTION verif_capacite_atelier();

-- Trigger : bloquer la réservation si la permanence est complète
CREATE OR REPLACE FUNCTION verif_places_permanence()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF (SELECT COUNT(*) FROM reservations_permanence WHERE permanence_id = NEW.permanence_id)
       >= (SELECT nb_places FROM permanences WHERE id = NEW.permanence_id) THEN
        RAISE EXCEPTION 'Permanence complète';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_places_permanence
BEFORE INSERT ON reservations_permanence
FOR EACH ROW EXECUTE FUNCTION verif_places_permanence();