const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { requireAuth } = require('../middleware/auth');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function signer(u) {
  return jwt.sign({ id: u.id, role: u.role }, process.env.JWT_SECRET, { expiresIn: '8h' });
}

// US2 : connexion
router.post('/login', async (req, res) => {
  const { email, mot_de_passe } = req.body || {};
  if (!email || !mot_de_passe) {
    return res.status(400).json({ erreur: 'E-mail et mot de passe requis' });
  }
  const [rows] = await pool.query(
    'SELECT id, nom, prenom, email, role, mot_de_passe FROM utilisateurs WHERE email = ?',
    [email]
  );
  const u = rows[0];
  const ok = u && await bcrypt.compare(mot_de_passe, u.mot_de_passe);
  if (!ok) return res.status(401).json({ erreur: 'Identifiants incorrects' });

  res.json({
    token: signer(u),
    utilisateur: { id: u.id, nom: u.nom, prenom: u.prenom, email: u.email, role: u.role }
  });
});

// Creation de compte (le role est toujours "utilisateur" ; un admin le change ensuite)
router.post('/register', async (req, res) => {
  const { nom, prenom, email, mot_de_passe } = req.body || {};
  if (!nom || !prenom || !EMAIL_RE.test(email || '')) {
    return res.status(400).json({ erreur: 'Nom, prenom et e-mail valide requis' });
  }
  if (!mot_de_passe || mot_de_passe.length < 8) {
    return res.status(400).json({ erreur: 'Mot de passe : 8 caracteres minimum' });
  }
  const hash = await bcrypt.hash(mot_de_passe, 10);
  try {
    const [r] = await pool.query(
      'INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe) VALUES (?, ?, ?, ?)',
      [nom, prenom, email, hash]
    );
    const u = { id: r.insertId, role: 'utilisateur' };
    res.status(201).json({
      token: signer(u),
      utilisateur: { id: u.id, nom, prenom, email, role: u.role }
    });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ erreur: 'Cet e-mail est deja utilise' });
    }
    throw e;
  }
});

router.get('/me', requireAuth, async (req, res) => {
  const [rows] = await pool.query(
    'SELECT id, nom, prenom, email, role FROM utilisateurs WHERE id = ?',
    [req.user.id]
  );
  if (!rows[0]) return res.status(404).json({ erreur: 'Utilisateur introuvable' });
  res.json(rows[0]);
});

module.exports = router;
