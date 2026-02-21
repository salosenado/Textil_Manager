const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'textil_secret_key_change_in_production_2026';

function generateToken(user) {
  return jwt.sign(
    {
      id: user.id,
      email: user.email,
      empresa_id: user.empresa_id,
      es_root: user.es_root
    },
    JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No autorizado' });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Sesión expirada, inicia sesión de nuevo' });
  }
}

function rootOnly(req, res, next) {
  if (!req.user.es_root) {
    return res.status(403).json({ error: 'Acceso restringido a administrador del sistema' });
  }
  next();
}

module.exports = { generateToken, authMiddleware, rootOnly, JWT_SECRET };
