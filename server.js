require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./src/db');

if (!process.env.JWT_SECRET) {
  console.error('JWT_SECRET manquant dans le fichier .env');
  process.exit(1);
}

const app = express();

app.use(cors({
  origin: (process.env.CORS_ORIGIN || 'http://127.0.0.1:5500,http://localhost:5500').split(',')
}));
app.use(express.json());

app.get('/api/health', async (req, res) => {
  await pool.query('SELECT 1');
  res.json({ ok: true });
});

app.use('/api/auth', require('./src/routes/auth'));
app.use('/api', require('./src/routes/dons'));
app.use('/api', require('./src/routes/ateliers'));

app.use('/api', (req, res) => {
  res.status(404).json({ erreur: 'Route introuvable' });
});

app.use((err, req, res, next) => {
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ erreur: 'JSON invalide' });
  }
  console.error(err);
  res.status(500).json({ erreur: 'Erreur serveur' });
});

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`API demarree sur http://localhost:${port}`));
