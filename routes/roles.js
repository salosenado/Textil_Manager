const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  router.get('/permisos', authMiddleware, async (req, res) => {
    try {
      const result = await pool.query('SELECT * FROM permisos ORDER BY categoria, clave');
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/', authMiddleware, async (req, res) => {
    try {
      const empresaId = req.user.es_root ? req.query.empresa_id : req.user.empresa_id;

      if (!empresaId) {
        return res.json([]);
      }

      const result = await pool.query(
        `SELECT r.*, 
                (SELECT COUNT(*) FROM usuarios u WHERE u.rol_id = r.id) as num_usuarios
         FROM roles r 
         WHERE r.empresa_id = $1 
         ORDER BY r.nombre`,
        [empresaId]
      );

      for (const rol of result.rows) {
        const permisos = await pool.query(
          `SELECT p.id, p.clave, p.nombre, p.categoria FROM permisos p
           JOIN rol_permisos rp ON rp.permiso_id = p.id
           WHERE rp.rol_id = $1
           ORDER BY p.categoria, p.clave`,
          [rol.id]
        );
        rol.permisos = permisos.rows;
      }

      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, async (req, res) => {
    try {
      const { nombre, descripcion, permisos } = req.body;
      const empresaId = req.user.es_root ? req.body.empresa_id : req.user.empresa_id;

      if (!nombre) return res.status(400).json({ error: 'El nombre del rol es requerido' });
      if (!empresaId) return res.status(400).json({ error: 'Se requiere una empresa' });

      const existing = await pool.query(
        'SELECT id FROM roles WHERE nombre = $1 AND empresa_id = $2',
        [nombre, empresaId]
      );
      if (existing.rows.length > 0) {
        return res.status(400).json({ error: 'Ya existe un rol con ese nombre en esta empresa' });
      }

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        const result = await client.query(
          'INSERT INTO roles (nombre, descripcion, empresa_id) VALUES ($1, $2, $3) RETURNING *',
          [nombre, descripcion || null, empresaId]
        );
        const rol = result.rows[0];

        if (permisos && permisos.length > 0) {
          for (const permisoId of permisos) {
            await client.query(
              'INSERT INTO rol_permisos (rol_id, permiso_id) VALUES ($1, $2)',
              [rol.id, permisoId]
            );
          }
        }

        await client.query('COMMIT');

        const permisosResult = await pool.query(
          `SELECT p.id, p.clave, p.nombre, p.categoria FROM permisos p
           JOIN rol_permisos rp ON rp.permiso_id = p.id
           WHERE rp.rol_id = $1`,
          [rol.id]
        );
        rol.permisos = permisosResult.rows;

        res.json(rol);
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      } finally {
        client.release();
      }
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id', authMiddleware, async (req, res) => {
    try {
      const { id } = req.params;
      const { nombre, descripcion, permisos } = req.body;

      const rolCheck = await pool.query('SELECT empresa_id FROM roles WHERE id = $1', [id]);
      if (rolCheck.rows.length === 0) return res.status(404).json({ error: 'Rol no encontrado' });
      if (!req.user.es_root && rolCheck.rows[0].empresa_id !== req.user.empresa_id) {
        return res.status(403).json({ error: 'No tienes permiso para editar este rol' });
      }

      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        await client.query(
          'UPDATE roles SET nombre = $1, descripcion = $2 WHERE id = $3',
          [nombre, descripcion || null, id]
        );

        await client.query('DELETE FROM rol_permisos WHERE rol_id = $1', [id]);

        if (permisos && permisos.length > 0) {
          for (const permisoId of permisos) {
            await client.query(
              'INSERT INTO rol_permisos (rol_id, permiso_id) VALUES ($1, $2)',
              [id, permisoId]
            );
          }
        }

        await client.query('COMMIT');
        res.json({ message: 'Rol actualizado' });
      } catch (err) {
        await client.query('ROLLBACK');
        throw err;
      } finally {
        client.release();
      }
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.delete('/:id', authMiddleware, async (req, res) => {
    try {
      const { id } = req.params;

      const rolCheck = await pool.query('SELECT empresa_id FROM roles WHERE id = $1', [id]);
      if (rolCheck.rows.length === 0) return res.status(404).json({ error: 'Rol no encontrado' });
      if (!req.user.es_root && rolCheck.rows[0].empresa_id !== req.user.empresa_id) {
        return res.status(403).json({ error: 'No tienes permiso para eliminar este rol' });
      }

      const usersWithRole = await pool.query('SELECT COUNT(*) as count FROM usuarios WHERE rol_id = $1', [id]);
      if (parseInt(usersWithRole.rows[0].count) > 0) {
        return res.status(400).json({ error: 'No se puede eliminar un rol asignado a usuarios. Reasigna los usuarios primero.' });
      }

      await pool.query('DELETE FROM rol_permisos WHERE rol_id = $1', [id]);
      await pool.query('DELETE FROM roles WHERE id = $1', [id]);
      res.json({ message: 'Rol eliminado' });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
