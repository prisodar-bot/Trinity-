-- À lancer une seule fois, après avoir créé les 3 comptes de test
-- (marie@mail.fr, paul@mail.fr, sophie@mail.fr) dans Authentication > Users.

-- Compléter les profils et donner les rôles
UPDATE utilisateurs SET nom = 'Dupont', prenom = 'Marie', role = 'admin'    WHERE email = 'marie@mail.fr';
UPDATE utilisateurs SET nom = 'Martin', prenom = 'Paul',  role = 'benevole' WHERE email = 'paul@mail.fr';
UPDATE utilisateurs SET nom = 'Leroy',  prenom = 'Sophie'                   WHERE email = 'sophie@mail.fr';

INSERT INTO dons (titre, description, categorie, etat, date_don, statut, utilisateur_id) VALUES
('Table en bois', 'Table de salon', 'meuble', 'bon', '2026-10-20', 'accepte', (SELECT id FROM utilisateurs WHERE email = 'marie@mail.fr')),
('Vélo enfant', 'Roues neuves', 'jouet', 'très bon', '2026-10-22', 'propose', (SELECT id FROM utilisateurs WHERE email = 'sophie@mail.fr')),
('Matelas 2 places', 'Très usé', 'literie', 'mauvais', '2026-10-18', 'refuse', (SELECT id FROM utilisateurs WHERE email = 'sophie@mail.fr')),
('Chaise de bureau', 'Roulettes à changer', 'meuble', 'bon', '2026-10-15', 'recupere', (SELECT id FROM utilisateurs WHERE email = 'paul@mail.fr'));

INSERT INTO ateliers (titre, description, date_atelier, lieu, capacite, createur_id) VALUES
('Réparer son vélo', 'Atelier pratique', '2026-11-10 14:00:00+01', 'Salle A', 2, (SELECT id FROM utilisateurs WHERE email = 'marie@mail.fr')),
('Couture zéro déchet', 'Débutants bienvenus', '2026-11-17 10:00:00+01', 'Salle B', 10, (SELECT id FROM utilisateurs WHERE email = 'marie@mail.fr'));

INSERT INTO inscriptions (atelier_id, nom, prenom, email, token)
SELECT id, 'Bernard', 'Luc', 'luc@mail.fr', 'tok-aaa111' FROM ateliers WHERE titre = 'Réparer son vélo';
INSERT INTO inscriptions (atelier_id, nom, prenom, email, token)
SELECT id, 'Petit', 'Emma', 'emma@mail.fr', 'tok-bbb222' FROM ateliers WHERE titre = 'Réparer son vélo';

INSERT INTO permanences (date_debut, date_fin, nb_places) VALUES
('2026-11-05 09:00:00+01', '2026-11-05 12:00:00+01', 2),
('2026-11-05 14:00:00+01', '2026-11-05 17:00:00+01', 1);

INSERT INTO reservations_permanence (permanence_id, utilisateur_id)
SELECT 1, id FROM utilisateurs WHERE email = 'paul@mail.fr';

INSERT INTO criteres_don (libelle, accepte) VALUES
('Meubles en bon état', TRUE),
('Vêtements propres', TRUE),
('Matelas', FALSE),
('Électroménager cassé', FALSE);

INSERT INTO horaires (jour, heure_ouverture, heure_fermeture, ferme) VALUES
('lundi', NULL, NULL, TRUE),
('mardi', NULL, NULL, TRUE),
('mercredi', '09:00', '17:00', FALSE),
('jeudi', NULL, NULL, TRUE),
('vendredi', NULL, NULL, TRUE),
('samedi', '10:00', '18:00', FALSE),
('dimanche', NULL, NULL, TRUE);