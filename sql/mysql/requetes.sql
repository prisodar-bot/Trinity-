USE ressourcerie;

-- =====================================================================
-- LECTURES : sans danger, tu peux les lancer à volonté
-- =====================================================================

-- US2 : connexion (récupérer l'utilisateur par email)
SELECT id, nom, prenom, role, mot_de_passe
FROM utilisateurs
WHERE email = 'marie@mail.fr';

-- US3 : liste des comptes
SELECT id, nom, prenom, email, role FROM utilisateurs;

-- US3 : recherche d'un utilisateur par nom ou e-mail
SELECT id, nom, prenom, email, role
FROM utilisateurs
WHERE nom LIKE '%dup%' OR email LIKE '%dup%';

-- US4 : liste des dons avec le donateur
SELECT d.id, d.titre, d.categorie, d.statut, u.nom AS donateur
FROM dons d
JOIN utilisateurs u ON u.id = d.utilisateur_id
ORDER BY d.date_don DESC;

-- US4 : filtrer les dons par statut
SELECT id, titre, categorie, statut FROM dons WHERE statut = 'propose';

-- US5 : critères de don
SELECT libelle, accepte FROM criteres_don ORDER BY accepte DESC, libelle;

-- US6 : objets disponibles à la vente
SELECT id, titre, categorie FROM dons
WHERE statut = 'accepte' AND statut_vente = 'disponible';

-- US7 : places restantes des ateliers
SELECT a.titre, a.capacite,
       COUNT(i.id) AS inscrits,
       a.capacite - COUNT(i.id) AS places_restantes
FROM ateliers a
LEFT JOIN inscriptions i ON i.atelier_id = a.id
GROUP BY a.id, a.titre, a.capacite;

-- US7 : taux de remplissage en %
SELECT a.titre, ROUND(100 * COUNT(i.id) / a.capacite, 1) AS taux
FROM ateliers a
LEFT JOIN inscriptions i ON i.atelier_id = a.id
GROUP BY a.id, a.titre, a.capacite;

-- US7 : ateliers complets
SELECT a.titre
FROM ateliers a
LEFT JOIN inscriptions i ON i.atelier_id = a.id
GROUP BY a.id, a.titre, a.capacite
HAVING COUNT(i.id) >= a.capacite;

-- US7 : participants d'un atelier
SELECT nom, prenom, email FROM inscriptions WHERE atelier_id = 1;

-- US9 : infos pour l'e-mail de confirmation
SELECT i.prenom, i.email, a.titre, a.date_atelier, a.lieu
FROM inscriptions i
JOIN ateliers a ON a.id = i.atelier_id
WHERE i.token = 'tok-aaa111';

-- US11 : permanences encore disponibles
SELECT p.id, p.date_debut, p.date_fin,
       p.nb_places - COUNT(r.utilisateur_id) AS places_restantes
FROM permanences p
LEFT JOIN reservations_permanence r ON r.permanence_id = p.id
GROUP BY p.id, p.date_debut, p.date_fin, p.nb_places
HAVING places_restantes > 0;

-- US12 : planning d'un membre
SELECT p.date_debut, p.date_fin
FROM permanences p
JOIN reservations_permanence r ON r.permanence_id = p.id
WHERE r.utilisateur_id = 2
ORDER BY p.date_debut;

-- US13 : horaires
SELECT jour, heure_ouverture, heure_fermeture, ferme FROM horaires;

-- Tableau de bord de Martine
SELECT
  (SELECT COUNT(*) FROM utilisateurs) AS total_utilisateurs,
  (SELECT COUNT(*) FROM utilisateurs WHERE role = 'benevole') AS benevoles,
  (SELECT COUNT(*) FROM dons WHERE statut = 'propose') AS dons_en_attente,
  (SELECT COUNT(*) FROM dons WHERE statut = 'accepte') AS dons_acceptes,
  (SELECT COUNT(*) FROM dons WHERE statut = 'refuse') AS dons_refuses,
  (SELECT COUNT(*) FROM ateliers WHERE date_atelier > NOW()) AS ateliers_a_venir,
  (SELECT COUNT(*) FROM inscriptions) AS total_inscriptions;


-- =====================================================================
-- MODIFICATIONS : à exécuter UNE PAR UNE, dans l'ordre
-- =====================================================================

-- US3 : changer le rôle d'un utilisateur
UPDATE utilisateurs SET role = 'admin' WHERE id = 2;

-- US4 : ajouter un don
INSERT INTO dons (titre, description, categorie, etat, date_don, statut, utilisateur_id)
VALUES ('Lampe vintage', 'Fonctionne bien', 'décoration', 'bon', CURDATE(), 'propose', 2);

-- US4 : accepter le don « Vélo enfant »
UPDATE dons SET statut = 'accepte' WHERE titre = 'Vélo enfant';

-- US4 : refuser le don « Lampe vintage »
UPDATE dons SET statut = 'refuse' WHERE titre = 'Lampe vintage';

-- US4 : marquer le don « Table en bois » comme récupéré
UPDATE dons SET statut = 'recupere' WHERE titre = 'Table en bois';

-- US6 : marquer un objet comme vendu
UPDATE dons SET statut_vente = 'vendu' WHERE titre = 'Table en bois';

-- US5 : ajouter, modifier, supprimer un critère
INSERT INTO criteres_don (libelle, accepte) VALUES ('Livres', TRUE);
UPDATE criteres_don SET libelle = 'Livres en bon état' WHERE libelle = 'Livres';
DELETE FROM criteres_don WHERE libelle = 'Livres en bon état';

-- US8 : inscription refusée si l'atelier est complet (0 ligne insérée)
INSERT INTO inscriptions (atelier_id, nom, prenom, email, token)
SELECT 1, 'Durand', 'Léa', 'lea@mail.fr', 'tok-ccc333'
FROM ateliers a
WHERE a.id = 1
  AND (SELECT COUNT(*) FROM inscriptions WHERE atelier_id = 1) < a.capacite;

-- US8 : test du trigger (doit échouer avec « Atelier complet »)
INSERT INTO inscriptions (atelier_id, nom, prenom, email, token)
VALUES (1, 'Test', 'Trigger', 'test@mail.fr', 'tok-test');

-- US10 : désinscription via le token
DELETE FROM inscriptions WHERE token = 'tok-aaa111';

-- US11 : réserver une permanence
INSERT INTO reservations_permanence (permanence_id, utilisateur_id) VALUES (2, 3);

-- US11 : annuler une réservation de permanence
DELETE FROM reservations_permanence WHERE permanence_id = 1 AND utilisateur_id = 2;

-- US13 : modifier les horaires
UPDATE horaires
SET heure_ouverture = '10:00', heure_fermeture = '16:00'
WHERE jour = 'mercredi';

-- US14 : créer, modifier, supprimer un atelier
INSERT INTO ateliers (titre, description, date_atelier, lieu, capacite, createur_id)
VALUES ('Initiation peinture', 'Sur objets recyclés', '2026-12-01 15:00:00', 'Salle A', 8, 1);

UPDATE ateliers SET capacite = 12 WHERE titre = 'Réparer son vélo';

DELETE FROM ateliers WHERE titre = 'Initiation peinture';