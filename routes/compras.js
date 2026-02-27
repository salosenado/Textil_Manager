const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  function getEmpresaFilter(req, alias, params) {
    const empresaId = req.user.empresa_id;
    if (empresaId) {
      params.push(empresaId);
      return alias ? `${alias}.empresa_id = $${params.length}` : `empresa_id = $${params.length}`;
    }
    if (req.user.es_root) return '1=1';
    return null;
  }

  function addEmpresaCondition(req, params) {
    const empresaId = req.user.empresa_id;
    if (empresaId) {
      params.push(empresaId);
      return ` AND empresa_id = $${params.length}`;
    }
    return '';
  }

  // ============================================================
  // ÓRDENES DE COMPRA
  // ============================================================

  router.get('/ordenes-compra', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'oc', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, estado, periodo } = req.query;
      let query = `SELECT oc.*, p.nombre as proveedor_nombre_rel
                    FROM ordenes_compra oc
                    LEFT JOIN proveedores p ON oc.proveedor_id = p.id
                    WHERE ${empresaFilter}`;
      let idx = params.length + 1;

      if (estado === 'canceladas') {
        query += ` AND oc.cancelada = true`;
      } else if (estado === 'activas') {
        query += ` AND oc.cancelada = false`;
      }

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(oc.proveedor_nombre) LIKE $${idx} OR LOWER(p.nombre) LIKE $${idx})`;
        idx++;
      }

      if (periodo) {
        if (periodo === 'semana') {
          query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '7 days'`;
        } else if (periodo === 'mes') {
          query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '1 month'`;
        } else if (periodo === 'anio') {
          query += ` AND oc.fecha_creacion >= NOW() - INTERVAL '1 year'`;
        }
      }

      query += ` ORDER BY oc.fecha_creacion DESC`;

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      console.error('Error listing ordenes_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/ordenes-compra/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'oc', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const orden = await pool.query(
        `SELECT oc.*, p.nombre as proveedor_nombre_rel
         FROM ordenes_compra oc
         LEFT JOIN proveedores p ON oc.proveedor_id = p.id
         WHERE oc.id = $1 AND ${empresaFilter}`,
        params
      );

      if (orden.rows.length === 0) {
        return res.status(404).json({ error: 'Orden de compra no encontrada' });
      }

      const detalles = await pool.query(
        `SELECT * FROM orden_compra_detalles WHERE orden_id = $1 ORDER BY created_at`,
        [req.params.id]
      );

      const movimientos = await pool.query(
        `SELECT * FROM orden_compra_movimientos WHERE orden_id = $1 ORDER BY fecha DESC`,
        [req.params.id]
      );

      res.json({
        ...orden.rows[0],
        detalles: detalles.rows,
        movimientos: movimientos.rows
      });
    } catch (err) {
      console.error('Error getting orden_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/ordenes-compra', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { proveedor_id, proveedor_nombre, fecha_recepcion, aplica_iva, observaciones, detalles } = req.body;

    if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Se requiere al menos un detalle' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        `SELECT COALESCE(MAX(numero_compra), 0) + 1 as next_num FROM ordenes_compra WHERE empresa_id = $1`,
        [empresaId]
      );
      const numeroCompra = numResult.rows[0].next_num;

      const ordenResult = await client.query(
        `INSERT INTO ordenes_compra (empresa_id, numero_compra, proveedor_id, proveedor_nombre, fecha_recepcion, aplica_iva, observaciones)
         VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
        [empresaId, numeroCompra, proveedor_id || null, proveedor_nombre || null, fecha_recepcion || null, aplica_iva || false, observaciones || null]
      );
      const orden = ordenResult.rows[0];

      for (const det of detalles) {
        await client.query(
          `INSERT INTO orden_compra_detalles (orden_id, articulo, modelo, modelo_id, cantidad, costo_unitario)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [orden.id, det.articulo || null, det.modelo || null, det.modelo_id || null, det.cantidad || 0, det.costo_unitario || 0]
        );
      }

      await client.query(
        `INSERT INTO orden_compra_movimientos (orden_id, movimiento) VALUES ($1, $2)`,
        [orden.id, `Orden de compra OC-${numeroCompra} creada`]
      );

      await client.query('COMMIT');
      res.json(orden);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating orden_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/ordenes-compra/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { proveedor_id, proveedor_nombre, fecha_recepcion, aplica_iva, observaciones, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ordenes_compra WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Orden de compra no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede editar una orden cancelada' });
      }

      let upQ = `UPDATE ordenes_compra SET proveedor_id = $1, proveedor_nombre = $2, fecha_recepcion = $3, aplica_iva = $4, observaciones = $5 WHERE id = $6`;
      const upP = [proveedor_id || null, proveedor_nombre || null, fecha_recepcion || null, aplica_iva || false, observaciones || null, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $7`; upP.push(empresaId); }
      await client.query(upQ, upP);

      if (detalles && Array.isArray(detalles)) {
        await client.query(`DELETE FROM orden_compra_detalles WHERE orden_id = $1`, [req.params.id]);
        for (const det of detalles) {
          await client.query(
            `INSERT INTO orden_compra_detalles (orden_id, articulo, modelo, modelo_id, cantidad, costo_unitario)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [req.params.id, det.articulo || null, det.modelo || null, det.modelo_id || null, det.cantidad || 0, det.costo_unitario || 0]
          );
        }
      }

      await client.query(
        `INSERT INTO orden_compra_movimientos (orden_id, movimiento) VALUES ($1, $2)`,
        [req.params.id, `Orden de compra OC-${existing.rows[0].numero_compra} editada`]
      );

      await client.query('COMMIT');

      const updated = await pool.query(`SELECT * FROM ordenes_compra WHERE id = $1`, [req.params.id]);
      res.json(updated.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating orden_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/ordenes-compra/:id/cancelar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ordenes_compra WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Orden de compra no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'La orden ya está cancelada' });
      }

      await client.query(
        `UPDATE ordenes_compra SET cancelada = true WHERE id = $1`,
        [req.params.id]
      );

      await client.query(
        `INSERT INTO orden_compra_movimientos (orden_id, movimiento) VALUES ($1, $2)`,
        [req.params.id, `Orden de compra OC-${existing.rows[0].numero_compra} cancelada`]
      );

      await client.query('COMMIT');
      res.json({ message: 'Orden de compra cancelada' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error cancelling orden_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/ordenes-compra/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM ordenes_compra WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Orden de compra no encontrada' });
      }

      res.json({ message: 'Orden de compra eliminada' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting orden_compra:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  // ============================================================
  // COMPRAS DE INSUMO
  // ============================================================

  router.get('/compras-insumo', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, null, params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, periodo } = req.query;
      let query = `SELECT * FROM compras_insumo WHERE ${empresaFilter}`;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND LOWER(proveedor_cliente) LIKE $${idx}`;
        idx++;
      }

      if (periodo) {
        if (periodo === 'semana') {
          query += ` AND fecha_creacion >= NOW() - INTERVAL '7 days'`;
        } else if (periodo === 'mes') {
          query += ` AND fecha_creacion >= NOW() - INTERVAL '1 month'`;
        } else if (periodo === 'anio') {
          query += ` AND fecha_creacion >= NOW() - INTERVAL '1 year'`;
        }
      }

      query += ` ORDER BY fecha_creacion DESC`;

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      console.error('Error listing compras_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/compras-insumo/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, null, params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const compra = await pool.query(
        `SELECT * FROM compras_insumo WHERE id = $1 AND ${empresaFilter}`,
        params
      );

      if (compra.rows.length === 0) {
        return res.status(404).json({ error: 'Compra de insumo no encontrada' });
      }

      const detalles = await pool.query(
        `SELECT * FROM compra_insumo_detalles WHERE compra_id = $1 ORDER BY created_at`,
        [req.params.id]
      );

      res.json({
        ...compra.rows[0],
        detalles: detalles.rows
      });
    } catch (err) {
      console.error('Error getting compra_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/compras-insumo', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { proveedor_cliente, fecha_recepcion, aplica_iva, observaciones, detalles } = req.body;

    if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Se requiere al menos un detalle' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        `SELECT COALESCE(MAX(numero_compra), 0) + 1 as next_num FROM compras_insumo WHERE empresa_id = $1`,
        [empresaId]
      );
      const numeroCompra = numResult.rows[0].next_num;

      const compraResult = await client.query(
        `INSERT INTO compras_insumo (empresa_id, numero_compra, proveedor_cliente, fecha_recepcion, aplica_iva, observaciones)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [empresaId, numeroCompra, proveedor_cliente || null, fecha_recepcion || null, aplica_iva || false, observaciones || null]
      );
      const compra = compraResult.rows[0];

      for (const det of detalles) {
        await client.query(
          `INSERT INTO compra_insumo_detalles (compra_id, articulo, linea, modelo, color, talla, unidad, cantidad, costo_unitario)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
          [compra.id, det.articulo || null, det.linea || null, det.modelo || null, det.color || null, det.talla || null, det.unidad || null, det.cantidad || 0, det.costo_unitario || 0]
        );
      }

      await client.query('COMMIT');
      res.json(compra);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating compra_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/compras-insumo/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { proveedor_cliente, fecha_recepcion, aplica_iva, observaciones, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM compras_insumo WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Compra de insumo no encontrada' });
      }

      let upQ = `UPDATE compras_insumo SET proveedor_cliente = $1, fecha_recepcion = $2, aplica_iva = $3, observaciones = $4 WHERE id = $5`;
      const upP = [proveedor_cliente || null, fecha_recepcion || null, aplica_iva || false, observaciones || null, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $6`; upP.push(empresaId); }
      await client.query(upQ, upP);

      if (detalles && Array.isArray(detalles)) {
        await client.query(`DELETE FROM compra_insumo_detalles WHERE compra_id = $1`, [req.params.id]);
        for (const det of detalles) {
          await client.query(
            `INSERT INTO compra_insumo_detalles (compra_id, articulo, linea, modelo, color, talla, unidad, cantidad, costo_unitario)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [req.params.id, det.articulo || null, det.linea || null, det.modelo || null, det.color || null, det.talla || null, det.unidad || null, det.cantidad || 0, det.costo_unitario || 0]
          );
        }
      }

      await client.query('COMMIT');

      const updated = await pool.query(`SELECT * FROM compras_insumo WHERE id = $1`, [req.params.id]);
      res.json(updated.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating compra_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/compras-insumo/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM compras_insumo WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Compra de insumo no encontrada' });
      }

      res.json({ message: 'Compra de insumo eliminada' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting compra_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
