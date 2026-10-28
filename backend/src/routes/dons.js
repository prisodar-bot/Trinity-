const router = require('express').Router();
const pool = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');

const STATUTS = ['propose', 'accepte', 'refuse', 'recupere'];
const STATUTS_VENTE = ['disponible', 'vendu', 'retire'];

// US4 : liste des dons (equipe), filtre possible ?statut=propose
router.get('/dons', requireRole('admin', 'benevole'), async (req, res) => {
  const { statut } = req.query;
  if (statut && !STATUTS.includes(statut)) {
    return res.status(400).json({ erreur: 'Statut invalide' });
  }
  const [rows] = await pool.query(
    `SELECT d.id, d.titre, d.description, d.categorie, d.etat, d.date_don,
            d.statut, d.statut_vente, u.nom AS donateur
     FROM dons d
     LEFT JOIN utilisateurs u ON u.id = d.utilisateur_id
     ${statut ? 'WHERE d.statut = ?' : ''}
     ORDER BY d.date_don DESC, d.id DESC`,
    statut ? [statut] : []
  );
  res.json(rows);
});

// US4 : proposer un don (utilisateur connecte)
router.post('/dons', requireAuth, async (req, res) => {
  const { titre, description, categorie, etat } = req.body || {};
  if (!titre || !titre.trim()) {
    return res.status(400).json({ erreur: 'Le titre est requis' });
  }
  const [r] = await pool.query(
    `INSERT INTO dons (titre, description, categorie, etat, date_don, statut, utilisateur_id)
     VALUES (?, ?, ?, ?, CURDATE(), 'propose', ?)`,
    [titre.trim(), description || null, categorie || null, etat || null, req.user.id]
  );
  res.status(201).json({ id: r.insertId, statut: 'propose' });
});

// US4 : accepter / refuser / marquer recupere
router.patch('/dons/:id/statut', requireRole('admin', 'benevole'), async (req, res) => {
  const id = Number(req.params.id);
  const { statut } = req.body || {};
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  if (!STATUTS.includes(statut)) return res.status(400).json({ erreur: 'Statut invalide' });

  const [r] = await pool.query('UPDATE dons SET statut = ? WHERE id = ?', [statut, id]);
  if (r.affectedRows === 0) return res.status(404).json({ erreur: 'Don introuvable' });
  res.json({ id, statut });
});

// US6 : objets en vente (public, pour la boutique)
router.get('/boutique', async (req, res) => {
  const [rows] = await pool.query(
    `SELECT id, titre, description, categorie, etat
     FROM dons
     WHERE statut = 'accepte' AND statut_vente = 'disponible'
     ORDER BY date_don DESC, id DESC`
  );
  res.json(rows);
});

// US6 : marquer vendu / retire
router.patch('/dons/:id/vente', requireRole('admin', 'benevole'), async (req, res) => {
  const id = Number(req.params.id);
  const { statut_vente } = req.body || {};
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  if (!STATUTS_VENTE.includes(statut_vente)) {
    return res.status(400).json({ erreur: 'Statut de vente invalide' });
  }
  const [r] = await pool.query('UPDATE dons SET statut_vente = ? WHERE id = ?', [statut_vente, id]);
  if (r.affectedRows === 0) return res.status(404).json({ erreur: 'Don introuvable' });
  res.json({ id, statut_vente });
});

module.exports = router;
