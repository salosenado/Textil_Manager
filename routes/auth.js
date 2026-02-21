const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();
const { generateToken, authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  router.post('/login', async (req, res) => {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Ingresa tu correo y contraseña' });
      }

      const result = await pool.query(
        'SELECT * FROM usuarios WHERE email = $1',
        [email.toLowerCase().trim()]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
      }

      const user = result.rows[0];

      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        return res.status(401).json({ error: 'Correo o contraseña incorrectos' });
      }

      if (!user.activo) {
        return res.status(403).json({ error: 'blocked', message: 'Tu cuenta ha sido desactivada. Contacta al administrador.' });
      }

      if (!user.aprobado) {
        return res.status(403).json({ error: 'pending', message: 'Tu cuenta está pendiente de aprobación.' });
      }

      await pool.query('UPDATE usuarios SET ultimo_login = NOW() WHERE id = $1', [user.id]);

      let permisos = [];
      let rol = null;
      let empresa = null;

      if (!user.es_root && user.empresa_id) {
        const empresaResult = await pool.query('SELECT id, nombre, logo_url FROM empresas WHERE id = $1', [user.empresa_id]);
        if (empresaResult.rows.length > 0) empresa = empresaResult.rows[0];

        if (user.rol_id) {
          const rolResult = await pool.query('SELECT * FROM roles WHERE id = $1', [user.rol_id]);
          if (rolResult.rows.length > 0) {
            rol = rolResult.rows[0];
            const permisosResult = await pool.query(
              `SELECT p.clave FROM permisos p
               JOIN rol_permisos rp ON rp.permiso_id = p.id
               WHERE rp.rol_id = $1`,
              [user.rol_id]
            );
            permisos = permisosResult.rows.map(p => p.clave);
          }
        }
      }

      const token = generateToken(user);

      res.json({
        token,
        user: {
          id: user.id,
          email: user.email,
          nombre: user.nombre,
          es_root: user.es_root,
          empresa_id: user.empresa_id,
          empresa,
          rol,
          permisos
        }
      });
    } catch (err) {
      console.error('Login error:', err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/me', authMiddleware, async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM usuarios WHERE id = $1', [req.user.id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const user = result.rows[0];

      let permisos = [];
      let rol = null;
      let empresa = null;

      if (!user.es_root && user.empresa_id) {
        const empresaResult = await pool.query('SELECT id, nombre, logo_url FROM empresas WHERE id = $1', [user.empresa_id]);
        if (empresaResult.rows.length > 0) empresa = empresaResult.rows[0];

        if (user.rol_id) {
          const rolResult = await pool.query('SELECT * FROM roles WHERE id = $1', [user.rol_id]);
          if (rolResult.rows.length > 0) {
            rol = rolResult.rows[0];
            const permisosResult = await pool.query(
              `SELECT p.clave FROM permisos p
               JOIN rol_permisos rp ON rp.permiso_id = p.id
               WHERE rp.rol_id = $1`,
              [user.rol_id]
            );
            permisos = permisosResult.rows.map(p => p.clave);
          }
        }
      }

      res.json({
        id: user.id,
        email: user.email,
        nombre: user.nombre,
        es_root: user.es_root,
        empresa_id: user.empresa_id,
        activo: user.activo,
        aprobado: user.aprobado,
        empresa,
        rol,
        permisos
      });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/cambiar-password', authMiddleware, async (req, res) => {
    try {
      const { password_actual, password_nueva } = req.body;

      if (!password_actual || !password_nueva) {
        return res.status(400).json({ error: 'Ingresa la contraseña actual y la nueva' });
      }

      if (password_nueva.length < 6) {
        return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres' });
      }

      const result = await pool.query('SELECT password_hash FROM usuarios WHERE id = $1', [req.user.id]);
      const valid = await bcrypt.compare(password_actual, result.rows[0].password_hash);

      if (!valid) {
        return res.status(400).json({ error: 'La contraseña actual es incorrecta' });
      }

      const hash = await bcrypt.hash(password_nueva, 10);
      await pool.query('UPDATE usuarios SET password_hash = $1 WHERE id = $2', [hash, req.user.id]);

      res.json({ message: 'Contraseña actualizada correctamente' });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/perfil', authMiddleware, async (req, res) => {
    try {
      const { nombre } = req.body;
      if (!nombre) return res.status(400).json({ error: 'El nombre es requerido' });

      await pool.query('UPDATE usuarios SET nombre = $1 WHERE id = $2', [nombre, req.user.id]);
      res.json({ message: 'Perfil actualizado' });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
