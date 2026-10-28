// Usage : node scripts/set-password.js marie@mail.fr MonMotDePasse123
// Utile pour les comptes de donnees.sql, dont les mots de passe sont des placeholders ("hash1"...).
require('dotenv').config();
const bcrypt = require('bcryptjs');
const pool = require('../src/db');

(async () => {
  const [email, motDePasse] = process.argv.slice(2);
  if (!email || !motDePasse || motDePasse.length < 8) {
    console.error('Usage : node scripts/set-password.js <email> <mot de passe (8+ caracteres)>');
    process.exit(1);
  }
  const hash = await bcrypt.hash(motDePasse, 10);
  const [r] = await pool.query('UPDATE utilisateurs SET mot_de_passe = ? WHERE email = ?', [hash, email]);
  console.log(r.affectedRows ? `Mot de passe mis a jour pour ${email}` : `Aucun utilisateur avec l'e-mail ${email}`);
  await pool.end();
})();
