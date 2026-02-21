const express = require('express');
const router = express.Router();
const { authMiddleware, rootOnly } = require('../middleware/auth');

module.exports = function(pool) {

  router.get('/', authMiddleware, rootOnly, async (req, res) => {
    try {
      const result = await pool.query(`
        SELECT e.*,
          (SELECT COUNT(*) FROM usuarios u WHERE u.empresa_id = e.id) as total_usuarios,
          (SELECT COUNT(*) FROM usuarios u WHERE u.empresa_id = e.id AND u.activo = true) as usuarios_activos
        FROM empresas e
        ORDER BY e.nombre
      `);
      res.json(result.rows);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/stats', authMiddleware, rootOnly, async (req, res) => {
    try {
      const [empresas, usuarios, pendientes, roles] = await Promise.all([
        pool.query('SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE activo = true) as activas FROM empresas'),
        pool.query('SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE activo = true) as activos FROM usuarios WHERE es_root = false'),
        pool.query('SELECT COUNT(*) as total FROM usuarios WHERE aprobado = false AND es_root = false'),
        pool.query('SELECT COUNT(*) as total FROM roles'),
      ]);

      res.json({
        empresas: {
          total: parseInt(empresas.rows[0].total),
          activas: parseInt(empresas.rows[0].activas),
        },
        usuarios: {
          total: parseInt(usuarios.rows[0].total),
          activos: parseInt(usuarios.rows[0].activos),
        },
        pendientes: parseInt(pendientes.rows[0].total),
        roles: parseInt(roles.rows[0].total),
      });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:id', authMiddleware, rootOnly, async (req, res) => {
    try {
      const empresa = await pool.query('SELECT * FROM empresas WHERE id = $1', [req.params.id]);
      if (empresa.rows.length === 0) {
        return res.status(404).json({ error: 'Empresa no encontrada' });
      }

      const usuarios = await pool.query(`
        SELECT u.id, u.email, u.nombre, u.activo, u.aprobado, u.ultimo_login, u.created_at,
               r.nombre as rol_nombre
        FROM usuarios u
        LEFT JOIN roles r ON u.rol_id = r.id
        WHERE u.empresa_id = $1
        ORDER BY u.nombre
      `, [req.params.id]);

      const roles = await pool.query(
        'SELECT id, nombre FROM roles WHERE empresa_id = $1 ORDER BY nombre',
        [req.params.id]
      );

      res.json({
        ...empresa.rows[0],
        usuarios: usuarios.rows,
        roles: roles.rows,
      });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, rootOnly, async (req, res) => {
    try {
      const { nombre, rfc, direccion, telefono } = req.body;
      if (!nombre || !nombre.trim()) {
        return res.status(400).json({ error: 'El nombre es requerido' });
      }

      const result = await pool.query(
        `INSERT INTO empresas (nombre, rfc, direccion, telefono, activo, aprobado)
         VALUES ($1, $2, $3, $4, true, true) RETURNING *`,
        [nombre.trim(), rfc || null, direccion || null, telefono || null]
      );
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id', authMiddleware, rootOnly, async (req, res) => {
    try {
      const { nombre, rfc, direccion, telefono } = req.body;
      if (!nombre || !nombre.trim()) {
        return res.status(400).json({ error: 'El nombre es requerido' });
      }

      const result = await pool.query(
        `UPDATE empresas SET nombre = $1, rfc = $2, direccion = $3, telefono = $4
         WHERE id = $5 RETURNING *`,
        [nombre.trim(), rfc || null, direccion || null, telefono || null, req.params.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Empresa no encontrada' });
      }
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:id/toggle-activo', authMiddleware, rootOnly, async (req, res) => {
    try {
      const result = await pool.query(
        'UPDATE empresas SET activo = NOT activo WHERE id = $1 RETURNING activo, nombre',
        [req.params.id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Empresa no encontrada' });
      }
      const estado = result.rows[0].activo ? 'activada' : 'desactivada';
      res.json({ message: `${result.rows[0].nombre} ${estado}`, activo: result.rows[0].activo });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:id/reportes', authMiddleware, rootOnly, async (req, res) => {
    try {
      const empresaId = req.params.id;
      const [usuarios, roles, ordenes, producciones, ventas] = await Promise.all([
        pool.query('SELECT COUNT(*) as total FROM usuarios WHERE empresa_id = $1', [empresaId]),
        pool.query('SELECT COUNT(*) as total FROM roles WHERE empresa_id = $1', [empresaId]),
        pool.query('SELECT COUNT(*) as total FROM ordenes_cliente WHERE empresa_id = $1', [empresaId]),
        pool.query('SELECT COUNT(*) as total FROM producciones WHERE empresa_id = $1', [empresaId]),
        pool.query('SELECT COUNT(*) as total FROM ventas_cliente WHERE empresa_id = $1', [empresaId]),
      ]);

      res.json({
        usuarios: parseInt(usuarios.rows[0].total),
        roles: parseInt(roles.rows[0].total),
        ordenes: parseInt(ordenes.rows[0].total),
        producciones: parseInt(producciones.rows[0].total),
        ventas: parseInt(ventas.rows[0].total),
      });
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.delete('/:id', authMiddleware, rootOnly, async (req, res) => {
    try {
      const empresaId = req.params.id;

      const usuarios = await pool.query('SELECT COUNT(*) as total FROM usuarios WHERE empresa_id = $1', [empresaId]);
      if (parseInt(usuarios.rows[0].total) > 0) {
        return res.status(400).json({ error: 'No se puede eliminar una empresa que tiene usuarios asignados. Elimina o reasigna los usuarios primero.' });
      }

      const result = await pool.query('DELETE FROM empresas WHERE id = $1 RETURNING nombre', [empresaId]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Empresa no encontrada' });
      }

      res.json({ message: `Empresa "${result.rows[0].nombre}" eliminada` });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar la empresa porque tiene datos asociados (roles, órdenes, etc.). Desactívala en su lugar.' });
      }
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
