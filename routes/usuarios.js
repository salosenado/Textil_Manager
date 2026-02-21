const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  async function verificarAccesoUsuario(req, targetUserId) {
    if (req.user.es_root) return true;
    const result = await pool.query('SELECT empresa_id FROM usuarios WHERE id = $1', [targetUserId]);
    if (result.rows.length === 0) return false;
    return result.rows[0].empresa_id === req.user.empresa_id;
  }

  router.get('/', authMiddleware, async (req, res) => {
    try {
      let query, params;

      if (req.user.es_root) {
        query = `SELECT u.id, u.email, u.nombre, u.es_root, u.empresa_id, u.rol_id, u.activo, u.aprobado, u.ultimo_login, u.created_at,
                        e.nombre as empresa_nombre, r.nombre as rol_nombre
                 FROM usuarios u
                 LEFT JOIN empresas e ON u.empresa_id = e.id
                 LEFT JOIN roles r ON u.rol_id = r.id
                 ORDER BY u.created_at DESC`;
        params = [];
      } else {
        query = `SELECT u.id, u.email, u.nombre, u.es_root, u.empresa_id, u.rol_id, u.activo, u.aprobado, u.ultimo_login, u.created_at,
                        r.nombre as rol_nombre
                 FROM usuarios u
                 LEFT JOIN roles r ON u.rol_id = r.id
                 WHERE u.empresa_id = $1
                 ORDER BY u.nombre`;
        params = [req.user.empresa_id];
      }

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, async (req, res) => {
    try {
      const { email, nombre, password, empresa_id, rol_id } = req.body;

      if (!email || !nombre || !password) {
        return res.status(400).json({ error: 'Correo, nombre y contraseña son requeridos' });
      }

      if (password.length < 6) {
        return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
      }

      const existing = await pool.query('SELECT id FROM usuarios WHERE email = $1', [email.toLowerCase().trim()]);
      if (existing.rows.length > 0) {
        return res.status(400).json({ error: 'Ya existe un usuario con ese correo' });
      }

      const targetEmpresa = req.user.es_root ? (empresa_id || null) : req.user.empresa_id;
      const hash = await bcrypt.hash(password, 10);

      const result = await pool.query(
        `INSERT INTO usuarios (email, nombre, password_hash, empresa_id, rol_id, activo, aprobado, es_root)
         VALUES ($1, $2, $3, $4, $5, true, true, false)
         RETURNING id, email, nombre, empresa_id, activo, aprobado`,
        [email.toLowerCase().trim(), nombre, hash, targetEmpresa, rol_id || null]
      );

      res.json(result.rows[0]);
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id/aprobar', authMiddleware, async (req, res) => {
    try {
      const { id } = req.params;
      const hasAccess = await verificarAccesoUsuario(req, id);
      if (!hasAccess) return res.status(403).json({ error: 'No tienes permiso para esta acción' });

      await pool.query('UPDATE usuarios SET aprobado = true WHERE id = $1', [id]);
      res.json({ message: 'Usuario aprobado' });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id/toggle-activo', authMiddleware, async (req, res) => {
    try {
      const { id } = req.params;
      const hasAccess = await verificarAccesoUsuario(req, id);
      if (!hasAccess) return res.status(403).json({ error: 'No tienes permiso para esta acción' });

      if (id === req.user.id) return res.status(400).json({ error: 'No puedes desactivarte a ti mismo' });

      const result = await pool.query('UPDATE usuarios SET activo = NOT activo WHERE id = $1 RETURNING activo', [id]);
      const estado = result.rows[0].activo ? 'activado' : 'desactivado';
      res.json({ message: `Usuario ${estado}`, activo: result.rows[0].activo });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id/asignar-rol', authMiddleware, async (req, res) => {
    try {
      const { id } = req.params;
      const { rol_id } = req.body;
      const hasAccess = await verificarAccesoUsuario(req, id);
      if (!hasAccess) return res.status(403).json({ error: 'No tienes permiso para esta acción' });

      if (rol_id) {
        const rolCheck = await pool.query('SELECT empresa_id FROM roles WHERE id = $1', [rol_id]);
        if (rolCheck.rows.length === 0) return res.status(400).json({ error: 'Rol no encontrado' });
        if (!req.user.es_root && rolCheck.rows[0].empresa_id !== req.user.empresa_id) {
          return res.status(403).json({ error: 'No puedes asignar un rol de otra empresa' });
        }
      }

      await pool.query('UPDATE usuarios SET rol_id = $1 WHERE id = $2', [rol_id || null, id]);
      res.json({ message: 'Rol asignado correctamente' });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
