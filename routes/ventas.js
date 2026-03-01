const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  pool.query(`ALTER TABLE ventas_cliente ADD COLUMN IF NOT EXISTS usuario_creacion VARCHAR(255)`).catch(() => {});

  function getEmpresaFilter(req, alias, params) {
    const empresaId = req.user.empresa_id;
    if (empresaId) {
      params.push(empresaId);
      return `${alias}.empresa_id = $${params.length}`;
    }
    if (req.user.es_root) return '1=1';
    return null;
  }

  function getUserName(req) {
    return req.user.nombre || req.user.email || 'usuario';
  }

  router.get('/', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'v', params);
    if (!empresaFilter) return res.status(403).json({ error: 'No tienes empresa asignada' });

    try {
      const { search, estado } = req.query;
      let query = `
        SELECT v.*,
          c.nombre_comercial as cliente_nombre,
          a.nombre as agente_nombre,
          COALESCE(SUM(d.cantidad * d.costo_unitario), 0) as subtotal,
          COALESCE((SELECT SUM(cb.monto) FROM cobros_venta cb WHERE cb.venta_id = v.id AND cb.fecha_eliminacion IS NULL), 0) as total_cobrado
        FROM ventas_cliente v
        LEFT JOIN clientes c ON v.cliente_id = c.id
        LEFT JOIN agentes a ON v.agente_id = a.id
        LEFT JOIN venta_cliente_detalles d ON d.venta_id = v.id
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(v.folio,'')) LIKE $${idx} OR LOWER(COALESCE(c.nombre_comercial,'')) LIKE $${idx})`;
        idx++;
      }

      if (estado === 'canceladas') {
        query += ` AND v.cancelada = true`;
      } else if (estado === 'activas' || !estado) {
        query += ` AND v.cancelada = false`;
      }

      query += ` GROUP BY v.id, c.nombre_comercial, a.nombre ORDER BY v.created_at DESC`;

      const result = await pool.query(query, params);
      const ventas = result.rows.map(v => {
        const subtotal = parseFloat(v.subtotal) || 0;
        const iva = v.aplica_iva ? subtotal * 0.16 : 0;
        const total = subtotal + iva;
        const totalCobrado = parseFloat(v.total_cobrado) || 0;
        return { ...v, subtotal, iva, total, total_cobrado: totalCobrado, saldo: total - totalCobrado };
      });
      res.json(ventas);
    } catch (err) {
      console.error('Error GET ventas:', err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:id', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'v', params);
    if (!empresaFilter) return res.status(403).json({ error: 'No tienes empresa asignada' });

    try {
      const ventaResult = await pool.query(
        `SELECT v.*, c.nombre_comercial as cliente_nombre, a.nombre as agente_nombre
         FROM ventas_cliente v
         LEFT JOIN clientes c ON v.cliente_id = c.id
         LEFT JOIN agentes a ON v.agente_id = a.id
         WHERE v.id = $${params.length + 1} AND ${empresaFilter}`,
        [...params, req.params.id]
      );

      if (ventaResult.rows.length === 0) return res.status(404).json({ error: 'Venta no encontrada' });
      const venta = ventaResult.rows[0];

      const detalles = await pool.query(
        `SELECT d.*, m.nombre as marca_nombre
         FROM venta_cliente_detalles d
         LEFT JOIN marcas m ON d.marca_id = m.id
         WHERE d.venta_id = $1
         ORDER BY d.created_at`,
        [venta.id]
      );

      const movimientos = await pool.query(
        `SELECT * FROM venta_cliente_movimientos WHERE venta_id = $1 ORDER BY fecha DESC`,
        [venta.id]
      );

      const cobros = await pool.query(
        `SELECT * FROM cobros_venta WHERE venta_id = $1 AND fecha_eliminacion IS NULL ORDER BY fecha_cobro DESC`,
        [venta.id]
      );

      const subtotal = detalles.rows.reduce((sum, d) => sum + ((parseInt(d.cantidad) || 0) * (parseFloat(d.costo_unitario) || 0)), 0);
      const iva = venta.aplica_iva ? subtotal * 0.16 : 0;
      const total = subtotal + iva;
      const totalCobrado = cobros.rows.reduce((sum, c) => sum + (parseFloat(c.monto) || 0), 0);

      res.json({
        ...venta,
        detalles: detalles.rows,
        movimientos: movimientos.rows,
        cobros: cobros.rows,
        subtotal,
        iva,
        total,
        total_cobrado: totalCobrado,
        saldo: total - totalCobrado
      });
    } catch (err) {
      console.error('Error GET venta detalle:', err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId) return res.status(400).json({ error: 'Se requiere una empresa' });

    const { fecha_entrega, cliente_id, agente_id, numero_factura, aplica_iva, observaciones, detalles } = req.body;

    if (!cliente_id) return res.status(400).json({ error: 'Se requiere un cliente' });
    if (!detalles || detalles.length === 0) return res.status(400).json({ error: 'Se requiere al menos un artículo' });

    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      const cantidad = parseInt(det.cantidad) || 0;
      const costo = parseFloat(det.costo_unitario) || 0;
      if (cantidad <= 0) return res.status(400).json({ error: `La cantidad del artículo ${i + 1} debe ser mayor a 0` });
      if (costo < 0) return res.status(400).json({ error: `El precio del artículo ${i + 1} no puede ser negativo` });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const numResult = await client.query(
        `SELECT COALESCE(MAX(CAST(SUBSTRING(folio FROM 5) AS INT)), 0) + 1 as next_num FROM ventas_cliente WHERE empresa_id = $1 AND folio LIKE 'VTA-%' FOR UPDATE`,
        [empresaId]
      );
      const folio = `VTA-${String(numResult.rows[0].next_num).padStart(5, '0')}`;
      const usuario = getUserName(req);

      const ventaResult = await client.query(
        `INSERT INTO ventas_cliente (empresa_id, folio, fecha_venta, fecha_entrega, cliente_id, agente_id, numero_factura, aplica_iva, observaciones, usuario_creacion)
         VALUES ($1, $2, NOW(), $3, $4, $5, $6, $7, $8, $9)
         RETURNING *`,
        [empresaId, folio, fecha_entrega || null, cliente_id, agente_id || null, numero_factura || null, aplica_iva || false, observaciones || null, usuario]
      );
      const venta = ventaResult.rows[0];

      for (const det of detalles) {
        await client.query(
          `INSERT INTO venta_cliente_detalles (venta_id, modelo_nombre, modelo_id, marca_id, cantidad, costo_unitario, unidad)
           VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [venta.id, det.modelo_nombre || null, det.modelo_id || null, det.marca_id || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0, det.unidad || null]
        );
      }

      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [venta.id, 'Venta creada', usuario, 'add-circle', 'green']
      );

      await client.query('COMMIT');
      res.json(venta);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error POST venta:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    const { fecha_entrega, cliente_id, agente_id, numero_factura, aplica_iva, observaciones, detalles } = req.body;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ventas_cliente WHERE id = $1';
      let existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }

      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Venta no encontrada' }); }

      const venta = existing.rows[0];
      if (venta.cancelada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'No se puede editar una venta cancelada' }); }
      if (venta.mercancia_enviada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'No se puede editar una venta con mercancía enviada' }); }

      if (detalles && detalles.length > 0) {
        for (let i = 0; i < detalles.length; i++) {
          const det = detalles[i];
          const cantidad = parseInt(det.cantidad) || 0;
          const costo = parseFloat(det.costo_unitario) || 0;
          if (cantidad <= 0) { await client.query('ROLLBACK'); return res.status(400).json({ error: `La cantidad del artículo ${i + 1} debe ser mayor a 0` }); }
          if (costo < 0) { await client.query('ROLLBACK'); return res.status(400).json({ error: `El precio del artículo ${i + 1} no puede ser negativo` }); }
        }
      }

      let upQ = `UPDATE ventas_cliente SET fecha_entrega=$1, cliente_id=$2, agente_id=$3, numero_factura=$4, aplica_iva=$5, observaciones=$6 WHERE id=$7`;
      let upP = [fecha_entrega || null, cliente_id || null, agente_id || null, numero_factura || null, aplica_iva || false, observaciones || null, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $8`; upP.push(empresaId); }

      await client.query(upQ, upP);

      if (detalles) {
        await client.query('DELETE FROM venta_cliente_detalles WHERE venta_id = $1', [req.params.id]);
        for (const det of detalles) {
          await client.query(
            `INSERT INTO venta_cliente_detalles (venta_id, modelo_nombre, modelo_id, marca_id, cantidad, costo_unitario, unidad)
             VALUES ($1, $2, $3, $4, $5, $6, $7)`,
            [req.params.id, det.modelo_nombre || null, det.modelo_id || null, det.marca_id || null, parseInt(det.cantidad) || 0, parseFloat(det.costo_unitario) || 0, det.unidad || null]
          );
        }
      }

      const usuario = getUserName(req);
      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [req.params.id, 'Venta editada', usuario, 'create', 'blue']
      );

      await client.query('COMMIT');
      res.json({ message: 'Venta actualizada' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error PUT venta:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/:id/cancelar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ventas_cliente WHERE id = $1';
      let existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }

      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Venta no encontrada' }); }
      if (existing.rows[0].cancelada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'La venta ya está cancelada' }); }

      let cancelQ = `UPDATE ventas_cliente SET cancelada = true WHERE id = $1`;
      let cancelP = [req.params.id];
      if (empresaId) { cancelQ += ` AND empresa_id = $2`; cancelP.push(empresaId); }
      await client.query(cancelQ, cancelP);

      const usuario = getUserName(req);
      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [req.params.id, 'Venta cancelada', usuario, 'close-circle', 'red']
      );

      await client.query('COMMIT');
      res.json({ message: 'Venta cancelada' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error cancelar venta:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/:id/enviar', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM ventas_cliente WHERE id = $1';
      let existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }

      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Venta no encontrada' }); }
      if (existing.rows[0].cancelada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'No se puede enviar una venta cancelada' }); }
      if (existing.rows[0].mercancia_enviada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'La mercancía ya fue enviada' }); }

      let enviarQ = `UPDATE ventas_cliente SET mercancia_enviada = true, fecha_envio = NOW() WHERE id = $1`;
      let enviarP = [req.params.id];
      if (empresaId) { enviarQ += ` AND empresa_id = $2`; enviarP.push(empresaId); }
      await client.query(enviarQ, enviarP);

      const usuario = getUserName(req);
      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [req.params.id, 'Mercancía enviada', usuario, 'send', 'blue']
      );

      await client.query('COMMIT');
      res.json({ message: 'Mercancía enviada' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error enviar venta:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    try {
      let delQ = 'DELETE FROM ventas_cliente WHERE id = $1';
      let delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }

      const result = await pool.query(delQ, delP);
      if (result.rowCount === 0) return res.status(404).json({ error: 'Venta no encontrada' });
      res.json({ message: 'Venta eliminada' });
    } catch (err) {
      console.error('Error DELETE venta:', err);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/:id/cobros', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    const { monto, referencia, observaciones } = req.body;

    if (!monto || parseFloat(monto) <= 0) return res.status(400).json({ error: 'El monto debe ser mayor a 0' });

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT v.*, COALESCE(SUM(d.cantidad * d.costo_unitario), 0) as subtotal FROM ventas_cliente v LEFT JOIN venta_cliente_detalles d ON d.venta_id = v.id WHERE v.id = $1';
      let existP = [req.params.id];
      if (empresaId) { existQ += ' AND v.empresa_id = $2'; existP.push(empresaId); }
      existQ += ' GROUP BY v.id';

      const existing = await client.query(existQ, existP);
      if (existing.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Venta no encontrada' }); }

      const venta = existing.rows[0];
      if (venta.cancelada) { await client.query('ROLLBACK'); return res.status(400).json({ error: 'No se puede cobrar una venta cancelada' }); }

      const subtotal = parseFloat(venta.subtotal) || 0;
      const iva = venta.aplica_iva ? subtotal * 0.16 : 0;
      const total = subtotal + iva;

      const cobrosResult = await client.query(
        `SELECT COALESCE(SUM(monto), 0) as cobrado FROM cobros_venta WHERE venta_id = $1 AND fecha_eliminacion IS NULL`,
        [req.params.id]
      );
      const cobrado = parseFloat(cobrosResult.rows[0].cobrado) || 0;
      const saldo = total - cobrado;

      const montoNum = parseFloat(monto);
      if (montoNum > saldo + 0.01) { await client.query('ROLLBACK'); return res.status(400).json({ error: `El monto excede el saldo pendiente (MX $ ${saldo.toFixed(2)})` }); }

      const cobroResult = await client.query(
        `INSERT INTO cobros_venta (venta_id, fecha_cobro, monto, referencia, observaciones) VALUES ($1, NOW(), $2, $3, $4) RETURNING *`,
        [req.params.id, montoNum, referencia || null, observaciones || null]
      );

      const usuario = getUserName(req);
      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [req.params.id, `Cobro registrado: MX $ ${montoNum.toFixed(2)}`, usuario, 'cash', 'green']
      );

      await client.query('COMMIT');
      res.json(cobroResult.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error POST cobro:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/:id/cobros/:cobroId', authMiddleware, async (req, res) => {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let ventaQ = 'SELECT id FROM ventas_cliente WHERE id = $1';
      let ventaP = [req.params.id];
      const empresaId = req.user.empresa_id;
      if (empresaId) { ventaQ += ' AND empresa_id = $2'; ventaP.push(empresaId); }
      const ventaCheck = await client.query(ventaQ, ventaP);
      if (ventaCheck.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Venta no encontrada' }); }

      const cobroCheck = await client.query(
        `SELECT cv.* FROM cobros_venta cv WHERE cv.id = $1 AND cv.venta_id = $2 AND cv.fecha_eliminacion IS NULL`,
        [req.params.cobroId, req.params.id]
      );
      if (cobroCheck.rows.length === 0) { await client.query('ROLLBACK'); return res.status(404).json({ error: 'Cobro no encontrado' }); }

      await client.query(
        `UPDATE cobros_venta SET fecha_eliminacion = NOW() WHERE id = $1`,
        [req.params.cobroId]
      );

      const usuario = getUserName(req);
      const montoEliminado = parseFloat(cobroCheck.rows[0].monto) || 0;
      await client.query(
        `INSERT INTO venta_cliente_movimientos (venta_id, titulo, usuario, icono, color) VALUES ($1, $2, $3, $4, $5)`,
        [req.params.id, `Cobro eliminado: MX $ ${montoEliminado.toFixed(2)}`, usuario, 'trash', 'red']
      );

      await client.query('COMMIT');
      res.json({ message: 'Cobro eliminado' });
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error DELETE cobro:', err);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  return router;
};
