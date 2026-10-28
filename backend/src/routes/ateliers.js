const router = require('express').Router();
const crypto = require('crypto');
const pool = require('../db');
const { requireRole } = require('../middleware/auth');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function lireAtelier(body) {
  const { titre, description, date_atelier, lieu, capacite } = body || {};
  const cap = Number(capacite);
  if (!titre || !titre.trim()) return { erreur: 'Le titre est requis' };
  if (!date_atelier || Number.isNaN(Date.parse(date_atelier))) return { erreur: 'Date invalide' };
  if (!Number.isInteger(cap) || cap <= 0) return { erreur: 'Capacite invalide' };
  return { valeurs: { titre: titre.trim(), description: description || null, date_atelier, lieu: lieu || null, capacite: cap } };
}

// US7 : liste publique avec places restantes
router.get('/ateliers', async (req, res) => {
  const [rows] = await pool.query(
    `SELECT a.id, a.titre, a.description, a.date_atelier, a.lieu, a.capacite,
            COUNT(i.id) AS inscrits,
            a.capacite - COUNT(i.id) AS places_restantes
     FROM ateliers a
     LEFT JOIN inscriptions i ON i.atelier_id = a.id
     GROUP BY a.id
     ORDER BY a.date_atelier`
  );
  res.json(rows);
});

// US7 : participants d'un atelier (equipe)
router.get('/ateliers/:id/inscrits', requireRole('admin', 'benevole'), async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  const [rows] = await pool.query(
    'SELECT nom, prenom, email, date_inscription FROM inscriptions WHERE atelier_id = ? ORDER BY date_inscription',
    [id]
  );
  res.json(rows);
});

// US14 : creer un atelier (admin)
router.post('/ateliers', requireRole('admin'), async (req, res) => {
  const { erreur, valeurs } = lireAtelier(req.body);
  if (erreur) return res.status(400).json({ erreur });
  const [r] = await pool.query(
    `INSERT INTO ateliers (titre, description, date_atelier, lieu, capacite, createur_id)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [valeurs.titre, valeurs.description, valeurs.date_atelier, valeurs.lieu, valeurs.capacite, req.user.id]
  );
  res.status(201).json({ id: r.insertId });
});

// US14 : modifier un atelier (admin)
router.put('/ateliers/:id', requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  const { erreur, valeurs } = lireAtelier(req.body);
  if (erreur) return res.status(400).json({ erreur });

  const [[{ n }]] = await pool.query(
    'SELECT COUNT(*) AS n FROM inscriptions WHERE atelier_id = ?', [id]
  );
  if (valeurs.capacite < n) {
    return res.status(409).json({ erreur: `Capacite inferieure au nombre d'inscrits (${n})` });
  }
  const [r] = await pool.query(
    `UPDATE ateliers SET titre = ?, description = ?, date_atelier = ?, lieu = ?, capacite = ?
     WHERE id = ?`,
    [valeurs.titre, valeurs.description, valeurs.date_atelier, valeurs.lieu, valeurs.capacite, id]
  );
  if (r.affectedRows === 0) return res.status(404).json({ erreur: 'Atelier introuvable' });
  res.json({ id });
});

// US14 : supprimer un atelier (admin) - les inscriptions partent avec (ON DELETE CASCADE)
router.delete('/ateliers/:id', requireRole('admin'), async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  const [r] = await pool.query('DELETE FROM ateliers WHERE id = ?', [id]);
  if (r.affectedRows === 0) return res.status(404).json({ erreur: 'Atelier introuvable' });
  res.status(204).end();
});

// US8 / US9 : inscription publique, refusee si l'atelier est complet
router.post('/ateliers/:id/inscriptions', async (req, res) => {
  const id = Number(req.params.id);
  const { nom, prenom, email } = req.body || {};
  if (!Number.isInteger(id)) return res.status(400).json({ erreur: 'Identifiant invalide' });
  if (!nom || !prenom || !EMAIL_RE.test(email || '')) {
    return res.status(400).json({ erreur: 'Nom, prenom et e-mail valide requis' });
  }

  const token = crypto.randomBytes(24).toString('hex');
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    // Verrou sur la ligne de l'atelier : deux inscriptions simultanees ne depassent pas la capacite
    const [[atelier]] = await conn.query(
      'SELECT id, titre, date_atelier, lieu, capacite FROM ateliers WHERE id = ? FOR UPDATE', [id]
    );
    if (!atelier) {
      await conn.rollback();
      return res.status(404).json({ erreur: 'Atelier introuvable' });
    }
    if (new Date(atelier.date_atelier.replace(' ', 'T')) < new Date()) {
      await conn.rollback();
      return res.status(400).json({ erreur: 'Cet atelier est deja passe' });
    }
    const [[{ n }]] = await conn.query(
      'SELECT COUNT(*) AS n FROM inscriptions WHERE atelier_id = ?', [id]
    );
    if (n >= atelier.capacite) {
      await conn.rollback();
      return res.status(409).json({ erreur: 'Atelier complet' });
    }
    await conn.query(
      'INSERT INTO inscriptions (atelier_id, nom, prenom, email, token) VALUES (?, ?, ?, ?, ?)',
      [id, nom.trim(), prenom.trim(), email, token]
    );
    await conn.commit();
    res.status(201).json({
      message: 'Inscription enregistree',
      token, // sert a se desinscrire (US10) ; a envoyer par e-mail plus tard (US9)
      atelier: { titre: atelier.titre, date_atelier: atelier.date_atelier, lieu: atelier.lieu }
    });
  } catch (e) {
    await conn.rollback().catch(() => {});
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ erreur: 'Cet e-mail est deja inscrit a cet atelier' });
    }
    if (e.sqlState === '45000') {
      return res.status(409).json({ erreur: 'Atelier complet' });
    }
    throw e;
  } finally {
    conn.release();
  }
});

// US10 : desinscription via le token
router.delete('/inscriptions/:token', async (req, res) => {
  const [r] = await pool.query('DELETE FROM inscriptions WHERE token = ?', [req.params.token]);
  if (r.affectedRows === 0) return res.status(404).json({ erreur: 'Inscription introuvable' });
  res.status(204).end();
});

module.exports = router;
