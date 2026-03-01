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

  // ============================================================
  // SALIDAS DE INSUMO
  // ============================================================

  router.get('/salidas', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 's', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, estado } = req.query;
      let query = `
        SELECT s.*,
          COALESCE(d.total_items, 0) as total_items,
          COALESCE(d.total_monto, 0) as total_monto
        FROM salidas_insumo s
        LEFT JOIN LATERAL (
          SELECT COUNT(*) as total_items, COALESCE(SUM(cantidad * costo_unitario), 0) as total_monto
          FROM salida_insumo_detalles WHERE salida_id = s.id
        ) d ON true
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(s.folio,'')) LIKE $${idx} OR LOWER(COALESCE(s.destino,'')) LIKE $${idx} OR LOWER(COALESCE(s.observaciones,'')) LIKE $${idx})`;
        idx++;
      }

      if (estado === 'canceladas') {
        query += ` AND s.cancelada = true`;
      } else if (estado === 'activas' || !estado) {
        query += ` AND s.cancelada = false`;
      }

      query += ` ORDER BY s.created_at DESC`;

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      console.error('Error listing salidas_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/salidas/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 's', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const salida = await pool.query(
        `SELECT s.* FROM salidas_insumo s WHERE s.id = $1 AND ${empresaFilter}`,
        params
      );

      if (salida.rows.length === 0) {
        return res.status(404).json({ error: 'Salida de insumo no encontrada' });
      }

      const detalles = await pool.query(
        'SELECT * FROM salida_insumo_detalles WHERE salida_id = $1 ORDER BY created_at',
        [req.params.id]
      );

      const s = salida.rows[0];
      const totalMonto = detalles.rows.reduce((sum, d) => sum + ((parseInt(d.cantidad) || 0) * (parseFloat(d.costo_unitario) || 0)), 0);

      res.json({
        ...s,
        detalles: detalles.rows,
        total_monto: totalMonto
      });
    } catch (err) {
      console.error('Error getting salida_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/salidas', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { destino, observaciones, fecha_salida, detalles } = req.body;

    if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Se requiere al menos un detalle' });
    }

    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      const cantidad = parseInt(det.cantidad) || 0;
      const costoUnitario = parseFloat(det.costo_unitario) || 0;
      if (cantidad <= 0) {
        return res.status(400).json({ error: `La cantidad del detalle ${i + 1} debe ser mayor a 0` });
      }
      if (costoUnitario < 0) {
        return res.status(400).json({ error: `El costo unitario del detalle ${i + 1} no puede ser negativo` });
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        `SELECT COALESCE(MAX(CAST(SUBSTRING(folio FROM 5) AS INT)), 0) + 1 as next_num FROM salidas_insumo WHERE empresa_id = $1 AND folio LIKE 'SAL-%'`,
        [empresaId]
      );
      const nextNum = numResult.rows[0].next_num;
      const folio = `SAL-${String(nextNum).padStart(5, '0')}`;

      const usuarioNombre = req.user.nombre || req.user.email || 'usuario';
      const salidaResult = await client.query(
        `INSERT INTO salidas_insumo (empresa_id, folio, fecha_salida, destino, observaciones, usuario_creacion)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [empresaId, folio, fecha_salida || new Date(), destino || null, observaciones || null, usuarioNombre]
      );
      const salida = salidaResult.rows[0];

      for (const det of detalles) {
        await client.query(
          `INSERT INTO salida_insumo_detalles (salida_id, articulo, modelo, cantidad, costo_unitario, unidad)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [salida.id, det.articulo || null, det.modelo || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0, det.unidad || null]
        );
      }

      await client.query('COMMIT');
      res.json(salida);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating salida_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/salidas/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { destino, observaciones, fecha_salida, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM salidas_insumo WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Salida de insumo no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede editar una salida cancelada' });
      }

      if (detalles && Array.isArray(detalles)) {
        for (let i = 0; i < detalles.length; i++) {
          const det = detalles[i];
          const cantidad = parseInt(det.cantidad) || 0;
          const costoUnitario = parseFloat(det.costo_unitario) || 0;
          if (cantidad <= 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `La cantidad del detalle ${i + 1} debe ser mayor a 0` });
          }
          if (costoUnitario < 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `El costo unitario del detalle ${i + 1} no puede ser negativo` });
          }
        }
      }

      let upQ = `UPDATE salidas_insumo SET destino = $1, observaciones = $2, fecha_salida = $3 WHERE id = $4`;
      const upP = [destino || null, observaciones || null, fecha_salida || existing.rows[0].fecha_salida, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $5`; upP.push(empresaId); }
      upQ += ' RETURNING *';
      const result = await client.query(upQ, upP);

      if (detalles && Array.isArray(detalles)) {
        await client.query('DELETE FROM salida_insumo_detalles WHERE salida_id = $1', [req.params.id]);
        for (const det of detalles) {
          await client.query(
            `INSERT INTO salida_insumo_detalles (salida_id, articulo, modelo, cantidad, costo_unitario, unidad)
             VALUES ($1, $2, $3, $4, $5, $6)`,
            [req.params.id, det.articulo || null, det.modelo || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0, det.unidad || null]
          );
        }
      }

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating salida_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/salidas/:id/cancelar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM salidas_insumo WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Salida de insumo no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'La salida ya está cancelada' });
      }

      let cancelQ = `UPDATE salidas_insumo SET cancelada = true WHERE id = $1`;
      const cancelP = [req.params.id];
      if (empresaId) { cancelQ += ` AND empresa_id = $2`; cancelP.push(empresaId); }
      cancelQ += ' RETURNING *';
      const result = await client.query(cancelQ, cancelP);

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error canceling salida_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/salidas/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM salidas_insumo WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Salida de insumo no encontrada' });
      }

      res.json({ message: 'Salida de insumo eliminada correctamente' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting salida_insumo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  // ============================================================
  // REINGRESOS
  // ============================================================

  router.get('/reingresos', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'r', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, estado } = req.query;
      let query = `
        SELECT r.*,
          c.nombre_comercial as cliente_nombre,
          COALESCE(d.total_items, 0) as total_items,
          COALESCE(d.total_monto, 0) as total_monto
        FROM reingresos r
        LEFT JOIN clientes c ON r.cliente_id = c.id
        LEFT JOIN LATERAL (
          SELECT COUNT(*) as total_items, COALESCE(SUM(cantidad * costo_unitario), 0) as total_monto
          FROM reingreso_detalles WHERE reingreso_id = r.id
        ) d ON true
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(r.folio,'')) LIKE $${idx} OR LOWER(COALESCE(r.motivo,'')) LIKE $${idx} OR LOWER(COALESCE(c.nombre_comercial,'')) LIKE $${idx} OR LOWER(COALESCE(r.observaciones,'')) LIKE $${idx})`;
        idx++;
      }

      if (estado === 'cancelados') {
        query += ` AND r.cancelado = true`;
      } else if (estado === 'activos' || !estado) {
        query += ` AND r.cancelado = false`;
      }

      query += ` ORDER BY r.created_at DESC`;

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      console.error('Error listing reingresos:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/reingresos/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'r', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const reingreso = await pool.query(
        `SELECT r.*, c.nombre_comercial as cliente_nombre
         FROM reingresos r
         LEFT JOIN clientes c ON r.cliente_id = c.id
         WHERE r.id = $1 AND ${empresaFilter}`,
        params
      );

      if (reingreso.rows.length === 0) {
        return res.status(404).json({ error: 'Reingreso no encontrado' });
      }

      const detalles = await pool.query(
        'SELECT * FROM reingreso_detalles WHERE reingreso_id = $1 ORDER BY created_at',
        [req.params.id]
      );

      const r = reingreso.rows[0];
      const totalMonto = detalles.rows.reduce((sum, d) => sum + ((parseInt(d.cantidad) || 0) * (parseFloat(d.costo_unitario) || 0)), 0);

      res.json({
        ...r,
        detalles: detalles.rows,
        total_monto: totalMonto
      });
    } catch (err) {
      console.error('Error getting reingreso:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/reingresos', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { cliente_id, venta_id, motivo, observaciones, fecha_reingreso, detalles } = req.body;

    if (!detalles || !Array.isArray(detalles) || detalles.length === 0) {
      return res.status(400).json({ error: 'Se requiere al menos un detalle' });
    }

    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      const cantidad = parseInt(det.cantidad) || 0;
      const costoUnitario = parseFloat(det.costo_unitario) || 0;
      if (cantidad <= 0) {
        return res.status(400).json({ error: `La cantidad del detalle ${i + 1} debe ser mayor a 0` });
      }
      if (costoUnitario < 0) {
        return res.status(400).json({ error: `El costo unitario del detalle ${i + 1} no puede ser negativo` });
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        `SELECT COALESCE(MAX(CAST(SUBSTRING(folio FROM 5) AS INT)), 0) + 1 as next_num FROM reingresos WHERE empresa_id = $1 AND folio LIKE 'REI-%'`,
        [empresaId]
      );
      const nextNum = numResult.rows[0].next_num;
      const folio = `REI-${String(nextNum).padStart(5, '0')}`;

      const usuarioNombre = req.user.nombre || req.user.email || 'usuario';
      const reingresoResult = await client.query(
        `INSERT INTO reingresos (empresa_id, folio, fecha_reingreso, venta_id, cliente_id, motivo, observaciones, usuario_creacion)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [empresaId, folio, fecha_reingreso || new Date(), venta_id || null, cliente_id || null, motivo || null, observaciones || null, usuarioNombre]
      );
      const reingreso = reingresoResult.rows[0];

      for (const det of detalles) {
        await client.query(
          `INSERT INTO reingreso_detalles (reingreso_id, es_servicio, nombre, talla, unidad, cantidad, costo_unitario)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [reingreso.id, det.es_servicio || false, det.nombre || null, det.talla || null, det.unidad || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0]
        );
      }

      await client.query('COMMIT');
      res.json(reingreso);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating reingreso:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/reingresos/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { cliente_id, venta_id, motivo, observaciones, fecha_reingreso, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM reingresos WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Reingreso no encontrado' });
      }

      if (existing.rows[0].cancelado) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede editar un reingreso cancelado' });
      }

      if (detalles && Array.isArray(detalles)) {
        for (let i = 0; i < detalles.length; i++) {
          const det = detalles[i];
          const cantidad = parseInt(det.cantidad) || 0;
          const costoUnitario = parseFloat(det.costo_unitario) || 0;
          if (cantidad <= 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `La cantidad del detalle ${i + 1} debe ser mayor a 0` });
          }
          if (costoUnitario < 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: `El costo unitario del detalle ${i + 1} no puede ser negativo` });
          }
        }
      }

      let upQ = `UPDATE reingresos SET cliente_id = $1, venta_id = $2, motivo = $3, observaciones = $4, fecha_reingreso = $5 WHERE id = $6`;
      const upP = [cliente_id || null, venta_id || null, motivo || null, observaciones || null, fecha_reingreso || existing.rows[0].fecha_reingreso, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $7`; upP.push(empresaId); }
      upQ += ' RETURNING *';
      const result = await client.query(upQ, upP);

      if (detalles && Array.isArray(detalles)) {
        await client.query('DELETE FROM reingreso_detalles WHERE reingreso_id = $1', [req.params.id]);
        for (const det of detalles) {
          await client.query(
            `INSERT INTO reingreso_detalles (reingreso_id, es_servicio, nombre, talla, unidad, cantidad, costo_unitario)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [req.params.id, det.es_servicio || false, det.nombre || null, det.talla || null, det.unidad || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0]
          );
        }
      }

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating reingreso:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/reingresos/:id/cancelar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM reingresos WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Reingreso no encontrado' });
      }

      if (existing.rows[0].cancelado) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'El reingreso ya está cancelado' });
      }

      let cancelQ = `UPDATE reingresos SET cancelado = true WHERE id = $1`;
      const cancelP = [req.params.id];
      if (empresaId) { cancelQ += ` AND empresa_id = $2`; cancelP.push(empresaId); }
      cancelQ += ' RETURNING *';
      const result = await client.query(cancelQ, cancelP);

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error canceling reingreso:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/reingresos/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM reingresos WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Reingreso no encontrado' });
      }

      res.json({ message: 'Reingreso eliminado correctamente' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting reingreso:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
