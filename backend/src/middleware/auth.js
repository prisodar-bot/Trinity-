const jwt = require('jsonwebtoken');

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ erreur: 'Connexion requise' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ erreur: 'Session invalide ou expiree' });
  }
}

function requireRole(...roles) {
  return [requireAuth, (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ erreur: 'Acces refuse' });
    }
    next();
  }];
}

module.exports = { requireAuth, requireRole };
