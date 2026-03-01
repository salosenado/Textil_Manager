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
    const empresaFilter = getEmpresaFilter(req, 'p', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search, estado } = req.query;
      let query = `
        SELECT p.*,
          m.nombre as maquilero_nombre_ref,
          d.articulo as articulo_nombre,
          d.modelo as modelo_nombre,
          d.linea as detalle_linea,
          d.color as detalle_color,
          d.talla as detalle_talla,
          d.cantidad as detalle_cantidad,
          d.precio_unitario as detalle_precio_unitario,
          oc.numero_venta,
          oc.cliente_nombre,
          oc.numero_pedido_cliente,
          oc.fecha_entrega,
          oc.aplica_iva,
          COALESCE(r.total_recibos, 0) as total_recibos,
          COALESCE(r.total_recibido, 0) as total_recibido
        FROM producciones p
        LEFT JOIN maquileros m ON p.maquilero_id = m.id
        LEFT JOIN orden_cliente_detalles d ON p.detalle_orden_id = d.id
        LEFT JOIN ordenes_cliente oc ON d.orden_id = oc.id
        LEFT JOIN LATERAL (
          SELECT COUNT(*) as total_recibos, COALESCE(SUM(cantidad), 0) as total_recibido
          FROM recibos_produccion WHERE produccion_id = p.id
        ) r ON true
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(d.modelo,'')) LIKE $${idx} OR LOWER(COALESCE(d.articulo,'')) LIKE $${idx} OR LOWER(COALESCE(p.maquilero_nombre,'')) LIKE $${idx} OR LOWER(COALESCE(oc.cliente_nombre,'')) LIKE $${idx})`;
        idx++;
      }

      if (estado === 'canceladas') {
        query += ` AND p.cancelada = true`;
      } else if (estado === 'activas' || !estado) {
        query += ` AND p.cancelada = false`;
      }

      query += ` ORDER BY p.created_at DESC`;

      const result = await pool.query(query, params);

      const rows = result.rows.map(r => {
        const subtotal = (parseInt(r.pz_cortadas) || 0) * (parseFloat(r.costo_maquila) || 0);
        const iva = r.aplica_iva ? subtotal * 0.16 : 0;
        return { ...r, subtotal, iva, total: subtotal + iva };
      });

      res.json(rows);
    } catch (err) {
      console.error('Error listing producciones:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'p', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const produccion = await pool.query(
        `SELECT p.*,
          m.nombre as maquilero_nombre_ref,
          d.articulo as articulo_nombre,
          d.modelo as modelo_nombre,
          d.linea as detalle_linea,
          d.color as detalle_color,
          d.talla as detalle_talla,
          d.cantidad as detalle_cantidad,
          d.precio_unitario as detalle_precio_unitario,
          oc.numero_venta,
          oc.cliente_nombre,
          oc.numero_pedido_cliente,
          oc.fecha_entrega,
          oc.aplica_iva
        FROM producciones p
        LEFT JOIN maquileros m ON p.maquilero_id = m.id
        LEFT JOIN orden_cliente_detalles d ON p.detalle_orden_id = d.id
        LEFT JOIN ordenes_cliente oc ON d.orden_id = oc.id
        WHERE p.id = $1 AND ${empresaFilter}`,
        params
      );

      if (produccion.rows.length === 0) {
        return res.status(404).json({ error: 'Producción no encontrada' });
      }

      const recibosResult = await pool.query(
        `SELECT * FROM recibos_produccion WHERE produccion_id = $1 ORDER BY fecha_recibo DESC`,
        [req.params.id]
      );

      const recibos = [];
      for (const recibo of recibosResult.rows) {
        const detalles = await pool.query(
          `SELECT * FROM recibo_produccion_detalles WHERE recibo_id = $1 ORDER BY created_at`,
          [recibo.id]
        );
        recibos.push({ ...recibo, detalles: detalles.rows });
      }

      const pagos = await pool.query(
        `SELECT * FROM pagos_recibo WHERE recibo_id IN (SELECT id FROM recibos_produccion WHERE produccion_id = $1) AND fecha_eliminacion IS NULL ORDER BY fecha_pago DESC`,
        [req.params.id]
      );

      const p = produccion.rows[0];
      const totalRecibido = recibosResult.rows.reduce((sum, r) => sum + (parseInt(r.cantidad) || 0), 0);
      const subtotal = (parseInt(p.pz_cortadas) || 0) * (parseFloat(p.costo_maquila) || 0);
      const iva = p.aplica_iva ? subtotal * 0.16 : 0;

      const detalleOrden = p.detalle_orden_id ? {
        articulo: p.articulo_nombre,
        modelo: p.modelo_nombre,
        linea: p.detalle_linea,
        color: p.detalle_color,
        talla: p.detalle_talla,
        cantidad: p.detalle_cantidad,
        precio_unitario: p.detalle_precio_unitario,
        numero_venta: p.numero_venta,
        cliente_nombre: p.cliente_nombre,
        numero_pedido_cliente: p.numero_pedido_cliente,
        fecha_entrega: p.fecha_entrega,
        aplica_iva: p.aplica_iva
      } : null;

      res.json({
        ...p,
        subtotal,
        iva,
        total: subtotal + iva,
        total_recibido: totalRecibido,
        detalle_orden: detalleOrden,
        recibos,
        pagos: pagos.rows
      });
    } catch (err) {
      console.error('Error getting produccion:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { maquilero_id, maquilero_nombre, detalle_orden_id, pz_cortadas, costo_maquila } = req.body;

    if (!maquilero_nombre) {
      return res.status(400).json({ error: 'Se requiere el nombre del maquilero' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let ordenMaquila = null;
      let fechaOrdenMaquila = null;
      const pzVal = parseInt(pz_cortadas) || 0;
      const costoVal = parseFloat(costo_maquila) || 0;

      if (maquilero_nombre && pzVal > 0 && costoVal > 0) {
        const numResult = await client.query(
          `SELECT COALESCE(MAX(CAST(SUBSTRING(orden_maquila FROM 4) AS INT)), 0) + 1 as next_num FROM producciones WHERE empresa_id = $1 AND orden_maquila IS NOT NULL`,
          [empresaId]
        );
        const nextNum = numResult.rows[0].next_num;
        ordenMaquila = `OM-${String(nextNum).padStart(5, '0')}`;
        fechaOrdenMaquila = new Date();
      }

      const result = await client.query(
        `INSERT INTO producciones (empresa_id, maquilero_id, maquilero_nombre, detalle_orden_id, pz_cortadas, costo_maquila, orden_maquila, fecha_orden_maquila)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [empresaId, maquilero_id || null, maquilero_nombre, detalle_orden_id || null, pzVal, costoVal, ordenMaquila, fechaOrdenMaquila]
      );

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating produccion:', err.message);
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

    const { maquilero_id, maquilero_nombre, pz_cortadas, costo_maquila } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM producciones WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Producción no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede editar una producción cancelada' });
      }

      const current = existing.rows[0];
      const newMaquileroNombre = maquilero_nombre !== undefined ? maquilero_nombre : current.maquilero_nombre;
      const newPz = pz_cortadas !== undefined ? (parseInt(pz_cortadas) || 0) : (parseInt(current.pz_cortadas) || 0);
      const newCosto = costo_maquila !== undefined ? (parseFloat(costo_maquila) || 0) : (parseFloat(current.costo_maquila) || 0);
      const newMaquileroId = maquilero_id !== undefined ? (maquilero_id || null) : current.maquilero_id;

      let ordenMaquila = current.orden_maquila;
      let fechaOrdenMaquila = current.fecha_orden_maquila;

      if (!current.orden_maquila && newMaquileroNombre && newPz > 0 && newCosto > 0) {
        const numResult = await client.query(
          `SELECT COALESCE(MAX(CAST(SUBSTRING(orden_maquila FROM 4) AS INT)), 0) + 1 as next_num FROM producciones WHERE empresa_id = $1 AND orden_maquila IS NOT NULL`,
          [empresaId]
        );
        const nextNum = numResult.rows[0].next_num;
        ordenMaquila = `OM-${String(nextNum).padStart(5, '0')}`;
        fechaOrdenMaquila = new Date();
      }

      let upQ = `UPDATE producciones SET maquilero_id = $1, maquilero_nombre = $2, pz_cortadas = $3, costo_maquila = $4, orden_maquila = $5, fecha_orden_maquila = $6 WHERE id = $7`;
      const upP = [newMaquileroId, newMaquileroNombre, newPz, newCosto, ordenMaquila, fechaOrdenMaquila, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $8`; upP.push(empresaId); }
      upQ += ' RETURNING *';
      const result = await client.query(upQ, upP);

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating produccion:', err.message);
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

      let existQ = 'SELECT * FROM producciones WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Producción no encontrada' });
      }

      if (existing.rows[0].cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'La producción ya está cancelada' });
      }

      const recibosCount = await client.query(
        'SELECT COUNT(*) as cnt FROM recibos_produccion WHERE produccion_id = $1',
        [req.params.id]
      );
      if (parseInt(recibosCount.rows[0].cnt) > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se puede cancelar porque tiene recibos asociados' });
      }

      let cancelQ = `UPDATE producciones SET cancelada = true, usuario_cancelacion = $1, fecha_cancelacion = NOW() WHERE id = $2`;
      const cancelP = [req.user.nombre || req.user.email || 'usuario', req.params.id];
      if (empresaId) { cancelQ += ` AND empresa_id = $3`; cancelP.push(empresaId); }
      cancelQ += ' RETURNING *';
      const result = await client.query(cancelQ, cancelP);

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error canceling produccion:', err.message);
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
      const recibosCount = await pool.query(
        'SELECT COUNT(*) as cnt FROM recibos_produccion WHERE produccion_id = $1',
        [req.params.id]
      );
      if (parseInt(recibosCount.rows[0].cnt) > 0) {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene recibos asociados' });
      }

      let delQ = 'DELETE FROM producciones WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Producción no encontrada' });
      }

      res.json({ message: 'Producción eliminada correctamente' });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: 'No se puede eliminar porque tiene datos asociados' });
      }
      console.error('Error deleting produccion:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/:id/recibos', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { cantidad, observaciones, nombre_entrega, nombre_recepcion, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM producciones WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Producción no encontrada' });
      }

      const prod = existing.rows[0];
      if (prod.cancelada) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'No se pueden registrar recepciones en una producción cancelada' });
      }

      const pzCortadas = parseInt(prod.pz_cortadas) || 0;
      const recibidoResult = await client.query(
        'SELECT COALESCE(SUM(cantidad), 0) as total FROM recibos_produccion WHERE produccion_id = $1',
        [req.params.id]
      );
      const yaRecibido = parseInt(recibidoResult.rows[0].total) || 0;
      const disponible = pzCortadas - yaRecibido;
      const cantidadSolicitada = parseInt(cantidad) || 0;

      if (disponible <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Ya se recibieron todas las piezas cortadas' });
      }

      if (cantidadSolicitada > disponible) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `Solo quedan ${disponible} piezas por recibir` });
      }

      if (cantidadSolicitada <= 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'La cantidad debe ser mayor a 0' });
      }

      const reciboResult = await client.query(
        `INSERT INTO recibos_produccion (produccion_id, cantidad, observaciones, nombre_entrega, nombre_recepcion)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [req.params.id, parseInt(cantidad) || 0, observaciones || null, nombre_entrega || null, nombre_recepcion || null]
      );
      const recibo = reciboResult.rows[0];

      if (detalles && Array.isArray(detalles)) {
        for (const det of detalles) {
          await client.query(
            `INSERT INTO recibo_produccion_detalles (recibo_id, talla, color, cantidad)
             VALUES ($1, $2, $3, $4)`,
            [recibo.id, det.talla || null, det.color || null, parseInt(det.cantidad) || 0]
          );
        }
      }

      await client.query('COMMIT');
      res.json(recibo);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating recibo_produccion:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/recibos/:reciboId', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let verifyQ = `SELECT rp.* FROM recibos_produccion rp
        JOIN producciones p ON rp.produccion_id = p.id
        WHERE rp.id = $1`;
      const verifyP = [req.params.reciboId];
      if (empresaId) { verifyQ += ' AND p.empresa_id = $2'; verifyP.push(empresaId); }
      const verify = await pool.query(verifyQ, verifyP);

      if (verify.rows.length === 0) {
        return res.status(404).json({ error: 'Recibo no encontrado' });
      }

      await pool.query('DELETE FROM recibos_produccion WHERE id = $1', [req.params.reciboId]);
      res.json({ message: 'Recibo eliminado correctamente' });
    } catch (err) {
      console.error('Error deleting recibo_produccion:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/recibos/:reciboId/pagos', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { monto, observaciones } = req.body;

    try {
      let verifyQ = `SELECT rp.* FROM recibos_produccion rp
        JOIN producciones p ON rp.produccion_id = p.id
        WHERE rp.id = $1`;
      const verifyP = [req.params.reciboId];
      if (empresaId) { verifyQ += ' AND p.empresa_id = $2'; verifyP.push(empresaId); }
      const verify = await pool.query(verifyQ, verifyP);

      if (verify.rows.length === 0) {
        return res.status(404).json({ error: 'Recibo no encontrado' });
      }

      const result = await pool.query(
        `INSERT INTO pagos_recibo (recibo_id, monto, observaciones)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [req.params.reciboId, parseFloat(monto) || 0, observaciones || null]
      );

      res.json(result.rows[0]);
    } catch (err) {
      console.error('Error creating pago_recibo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.delete('/pagos/:pagoId', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let verifyQ = `SELECT pr.* FROM pagos_recibo pr
        JOIN recibos_produccion rp ON pr.recibo_id = rp.id
        JOIN producciones p ON rp.produccion_id = p.id
        WHERE pr.id = $1`;
      const verifyP = [req.params.pagoId];
      if (empresaId) { verifyQ += ' AND p.empresa_id = $2'; verifyP.push(empresaId); }
      const verify = await pool.query(verifyQ, verifyP);

      if (verify.rows.length === 0) {
        return res.status(404).json({ error: 'Pago no encontrado' });
      }

      await pool.query(
        `UPDATE pagos_recibo SET usuario_eliminacion = $1, fecha_eliminacion = NOW() WHERE id = $2`,
        [req.user.nombre || req.user.email || 'usuario', req.params.pagoId]
      );

      res.json({ message: 'Pago eliminado correctamente' });
    } catch (err) {
      console.error('Error deleting pago_recibo:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
