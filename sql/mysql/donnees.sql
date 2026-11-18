USE ressourcerie;

-- Les dates sont relatives à aujourd'hui : les données restent valables quand on relance le script.

INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe, role) VALUES
('Dupont', 'Marie', 'marie@mail.fr', 'hash1', 'admin'),
('Martin', 'Paul', 'paul@mail.fr', 'hash2', 'benevole'),
('Leroy', 'Sophie', 'sophie@mail.fr', 'hash3', 'utilisateur');

INSERT INTO dons (titre, description, categorie, etat, date_don, statut, utilisateur_id) VALUES
('Table en bois', 'Table de salon', 'meuble', 'bon', DATE_SUB(CURDATE(), INTERVAL 5 DAY), 'accepte', 1),
('Vélo enfant', 'Roues neuves', 'jouet', 'très bon', DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'propose', 3),
('Matelas 2 places', 'Très usé', 'literie', 'mauvais', DATE_SUB(CURDATE(), INTERVAL 7 DAY), 'refuse', 3),
('Chaise de bureau', 'Roulettes à changer', 'meuble', 'bon', DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'recupere', 2);

INSERT INTO ateliers (titre, description, date_atelier, lieu, capacite, createur_id) VALUES
('Réparer son vélo', 'Atelier pratique', TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 7 DAY), '14:00:00'), 'Salle A', 2, 1),
('Couture zéro déchet', 'Débutants bienvenus', TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 14 DAY), '10:00:00'), 'Salle B', 10, 1);

INSERT INTO inscriptions (atelier_id, nom, prenom, email, token) VALUES
(1, 'Bernard', 'Luc', 'luc@mail.fr', 'tok-aaa111'),
(1, 'Petit', 'Emma', 'emma@mail.fr', 'tok-bbb222');

INSERT INTO permanences (date_debut, date_fin, nb_places) VALUES
(TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 3 DAY), '09:00:00'), TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 3 DAY), '12:00:00'), 2),
(TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 3 DAY), '14:00:00'), TIMESTAMP(DATE_ADD(CURDATE(), INTERVAL 3 DAY), '17:00:00'), 1);

INSERT INTO reservations_permanence (permanence_id, utilisateur_id) VALUES (1, 2);

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
