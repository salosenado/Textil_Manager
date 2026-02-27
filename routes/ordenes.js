const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  function getEmpresaFilter(req, alias, params) {
    const empresaId = req.user.empresa_id;
    if (empresaId) {
      params.push(empresaId);
      return `${alias}.empresa_id = $${params.length}`;
    }
    if (req.user.es_root) return '1=1';
    return null;
  }

  router.get('/', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'oc', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, estado, periodo } = req.query;
      let query = `
        SELECT oc.*,
          c.nombre_comercial as cliente_nombre_ref,
          a.nombre as agente_nombre,
          COALESCE(SUM(d.cantidad * d.precio_unitario), 0) as subtotal
        FROM ordenes_cliente oc
        LEFT JOIN clientes c ON oc.cliente_id = c.id
        LEFT JOIN agentes a ON oc.agente_id = a.id
        LEFT JOIN orden_cliente_detalles d ON d.orden_id = oc.id
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(oc.cliente_nombre,'')) LIKE $${idx} OR LOWER(COALESCE(c.nombre_comercial,'')) LIKE $${idx})`;
        idx++;
      }

      if (estado === 'canceladas') {
        query += ` AND oc.cancelada = true`;
      } else if (estado === 'activas' || !estado) {
        query += ` AND oc.cancelada = false`;
      }

      if (periodo === 'semana') {
        query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '7 days'`;
      } else if (periodo === 'mes') {
        query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '1 month'`;
      } else if (periodo === 'anio') {
        query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '1 year'`;
      }

      query += ` GROUP BY oc.id, c.nombre_comercial, a.nombre ORDER BY oc.fecha_creacion DESC`;

      const result = await pool.query(query, params);

      const rows = result.rows.map(r => {
        const subtotal = parseFloat(r.subtotal) || 0;
        const iva = r.aplica_iva ? subtotal * 0.16 : 0;
        return { ...r, subtotal, iva, total: subtotal + iva };
      });

      res.json(rows);
    } catch (err) {
      console.error('Error listing ordenes_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'oc', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const orden = await pool.query(
        `SELECT oc.*, c.nombre_comercial as cliente_nombre_ref, a.nombre as agente_nombre
         FROM ordenes_cliente oc
         LEFT JOIN clientes c ON oc.cliente_id = c.id
         LEFT JOIN agentes a ON oc.agente_id = a.id
         WHERE oc.id = $1 AND ${empresaFilter}`,
        params
      );

      if (orden.rows.length === 0) {
        return res.status(404).json({ error: 'Orden no encontrada' });
      }

      const detalles = await pool.query(
        'SELECT * FROM orden_cliente_detalles WHERE orden_id = $1 ORDER BY created_at',
        [req.params.id]
      );

      const movimientos = await pool.query(
        'SELECT * FROM movimientos_pedido WHERE orden_id = $1 ORDER BY fecha DESC',
        [req.params.id]
      );

      const o = orden.rows[0];
      const subtotal = detalles.rows.reduce((sum, d) => sum + (d.cantidad * parseFloat(d.precio_unitario)), 0);
      const iva = o.aplica_iva ? subtotal * 0.16 : 0;

      res.json({
        ...o,
        subtotal,
        iva,
        total: subtotal + iva,
        detalles: detalles.rows,
        movimientos: movimientos.rows
      });
    } catch (err) {
      console.error('Error getting orden_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const {
      cliente_id, cliente_nombre, agente_id, numero_pedido_cliente,
      fecha_entrega, aplica_iva, detalles
    } = req.body;

    if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Se requiere al menos un detalle' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        'SELECT COALESCE(MAX(numero_venta), 0) + 1 as next_num FROM ordenes_cliente WHERE empresa_id = $1',
        [empresaId]
      );
      const numeroVenta = numResult.rows[0].next_num;

      const ordenResult = await client.query(
        `INSERT INTO ordenes_cliente
          (empresa_id, numero_venta, cliente_id, cliente_nombre, agente_id, numero_pedido_cliente, fecha_entrega, aplica_iva)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [empresaId, numeroVenta, cliente_id || null, cliente_nombre || null, agente_id || null,
         numero_pedido_cliente || null, fecha_entrega || null, aplica_iva || false]
      );
      const orden = ordenResult.rows[0];

      for (const d of detalles) {
        await client.query(
          `INSERT INTO orden_cliente_detalles
            (orden_id, articulo, linea, modelo, modelo_id, color, talla, unidad, cantidad, precio_unitario)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
          [orden.id, d.articulo || null, d.linea || null, d.modelo || null, d.modelo_id || null,
           d.color || null, d.talla || null, d.unidad || null, d.cantidad || 0, d.precio_unitario || 0]
        );
      }

      await client.query(
        'INSERT INTO movimientos_pedido (orden_id, movimiento) VALUES ($1, $2)',
        [orden.id, `Orden #${numeroVenta} creada por ${req.user.email || 'usuario'}`]
      );

      await client.query('COMMIT');

      res.json({ ...orden, numero_venta: numeroVenta });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating orden_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const {
      cliente_id, cliente_nombre, agente_id, numero_pedido_cliente,
      fecha_entrega, aplica_iva, detalles
    } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existingQuery = 'SELECT * FROM ordenes_cliente WHERE id = $1';
      const existingParams = [req.params.id];
      if (empresaId) {
        existingQuery += ' AND empresa_id = $2';
        existingParams.push(empresaId);
      }
      const existing = await client.query(existingQuery, existingParams);
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Orden no encontrada' });
      }
      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede editar una orden cancelada' });
      }

      let updateQuery = `UPDATE ordenes_cliente SET
          cliente_id = $1, cliente_nombre = $2, agente_id = $3, numero_pedido_cliente = $4,
          fecha_entrega = $5, aplica_iva = $6, ultimo_usuario_edicion = $7, fecha_ultima_edicion = NOW()
         WHERE id = $8`;
      const updateParams = [cliente_id || null, cliente_nombre || null, agente_id || null, numero_pedido_cliente || null,
         fecha_entrega || null, aplica_iva || false, req.user.email || 'usuario', req.params.id];
      if (empresaId) {
        updateQuery += ` AND empresa_id = $9`;
        updateParams.push(empresaId);
      }
      updateQuery += ' RETURNING *';
      const ordenResult = await client.query(updateQuery, updateParams);

      if (detalles && Array.isArray(detalles)) {
        await client.query('DELETE FROM orden_cliente_detalles WHERE orden_id = $1', [req.params.id]);
        for (const d of detalles) {
          await client.query(
            `INSERT INTO orden_cliente_detalles
              (orden_id, articulo, linea, modelo, modelo_id, color, talla, unidad, cantidad, precio_unitario)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
            [req.params.id, d.articulo || null, d.linea || null, d.modelo || null, d.modelo_id || null,
             d.color || null, d.talla || null, d.unidad || null, d.cantidad || 0, d.precio_unitario || 0]
          );
        }
      }

      await client.query(
        'INSERT INTO movimientos_pedido (orden_id, movimiento) VALUES ($1, $2)',
        [req.params.id, `Orden editada por ${req.user.email || 'usuario'}`]
      );

      await client.query('COMMIT');
      res.json(ordenResult.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating orden_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/:id/cancelar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ordenes_cliente WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Orden no encontrada' });
      }
      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'La orden ya está cancelada' });
      }

      let cancelQ = `UPDATE ordenes_cliente SET cancelada = true, usuario_cancelacion = $1, fecha_cancelacion = NOW()
         WHERE id = $2`;
      const cancelP = [req.user.email || 'usuario', req.params.id];
      if (empresaId) { cancelQ += ` AND empresa_id = $3`; cancelP.push(empresaId); }
      cancelQ += ' RETURNING *';
      const result = await client.query(cancelQ, cancelP);

      await client.query(
        'INSERT INTO movimientos_pedido (orden_id, movimiento) VALUES ($1, $2)',
        [req.params.id, `Orden cancelada por ${req.user.email || 'usuario'}`]
      );

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error canceling orden_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM ordenes_cliente WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Orden no encontrada' });
      }

      res.json({ message: 'Orden eliminada correctamente' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting orden_cliente:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
