const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

module.exports = function(pool) {

  (async () => {
    try {
      await pool.query(`ALTER TABLE costos_generales ADD COLUMN IF NOT EXISTS usuario_creacion VARCHAR(255)`);
      await pool.query(`ALTER TABLE costos_mezclilla ADD COLUMN IF NOT EXISTS usuario_creacion VARCHAR(255)`);
    } catch (e) {}
  })();

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
  // COSTOS GENERALES
  // ============================================================

  router.get('/generales', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'cg', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search } = req.query;
      let query = `
        SELECT cg.*,
          d.nombre as departamento_nombre,
          l.nombre as linea_nombre,
          COALESCE(t.total_telas, 0) as total_telas,
          COALESCE(i.total_insumos, 0) as total_insumos
        FROM costos_generales cg
        LEFT JOIN departamentos d ON cg.departamento_id = d.id
        LEFT JOIN lineas l ON cg.linea_id = l.id
        LEFT JOIN LATERAL (
          SELECT SUM(consumo * precio_unitario) as total_telas
          FROM costo_general_telas WHERE costo_general_id = cg.id
        ) t ON true
        LEFT JOIN LATERAL (
          SELECT SUM(cantidad * costo_unitario) as total_insumos
          FROM costo_general_insumos WHERE costo_general_id = cg.id
        ) i ON true
        WHERE ${empresaFilter}
      `;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(cg.modelo,'')) LIKE $${idx} OR LOWER(COALESCE(cg.descripcion,'')) LIKE $${idx} OR LOWER(COALESCE(d.nombre,'')) LIKE $${idx})`;
        idx++;
      }

      query += ` ORDER BY cg.created_at DESC`;

      const result = await pool.query(query, params);

      const rows = result.rows.map(r => {
        const totalTelas = parseFloat(r.total_telas) || 0;
        const totalInsumos = parseFloat(r.total_insumos) || 0;
        const total = totalTelas + totalInsumos;
        const totalConGastos = total * 1.15;
        return { ...r, total_telas: totalTelas, total_insumos: totalInsumos, total, total_con_gastos: totalConGastos };
      });

      res.json(rows);
    } catch (err) {
      console.error('Error listing costos_generales:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/generales/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'cg', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const costo = await pool.query(
        `SELECT cg.*,
          d.nombre as departamento_nombre,
          l.nombre as linea_nombre
        FROM costos_generales cg
        LEFT JOIN departamentos d ON cg.departamento_id = d.id
        LEFT JOIN lineas l ON cg.linea_id = l.id
        WHERE cg.id = $1 AND ${empresaFilter}`,
        params
      );

      if (costo.rows.length === 0) {
        return res.status(404).json({ error: 'Costo general no encontrado' });
      }

      const telas = await pool.query(
        'SELECT * FROM costo_general_telas WHERE costo_general_id = $1 ORDER BY created_at',
        [req.params.id]
      );

      const insumos = await pool.query(
        'SELECT * FROM costo_general_insumos WHERE costo_general_id = $1 ORDER BY created_at',
        [req.params.id]
      );

      const totalTelas = telas.rows.reduce((sum, t) => sum + (parseFloat(t.consumo) * parseFloat(t.precio_unitario)), 0);
      const totalInsumos = insumos.rows.reduce((sum, i) => sum + (parseFloat(i.cantidad) * parseFloat(i.costo_unitario)), 0);
      const total = totalTelas + totalInsumos;
      const totalConGastos = total * 1.15;

      res.json({
        ...costo.rows[0],
        telas: telas.rows,
        insumos: insumos.rows,
        total_telas: totalTelas,
        total_insumos: totalInsumos,
        total,
        total_con_gastos: totalConGastos
      });
    } catch (err) {
      console.error('Error getting costo_general:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/generales', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { fecha, departamento_id, linea_id, modelo, tallas, descripcion, telas, insumos } = req.body;

    if (telas && Array.isArray(telas)) {
      for (const t of telas) {
        if (parseFloat(t.consumo) <= 0 || parseFloat(t.precio_unitario) <= 0) {
          return res.status(400).json({ error: 'El consumo y precio unitario de telas deben ser mayores a 0' });
        }
      }
    }

    if (insumos && Array.isArray(insumos)) {
      for (const i of insumos) {
        if (parseFloat(i.cantidad) <= 0 || parseFloat(i.costo_unitario) <= 0) {
          return res.status(400).json({ error: 'La cantidad y costo unitario de insumos deben ser mayores a 0' });
        }
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const usuarioNombre = req.user.nombre || req.user.email || 'usuario';
      const costoResult = await client.query(
        `INSERT INTO costos_generales (empresa_id, fecha, departamento_id, linea_id, modelo, tallas, descripcion, usuario_creacion)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [empresaId, fecha || new Date(), departamento_id || null, linea_id || null, modelo || null, tallas || null, descripcion || null, usuarioNombre]
      );
      const costo = costoResult.rows[0];

      if (telas && Array.isArray(telas)) {
        for (const t of telas) {
          await client.query(
            `INSERT INTO costo_general_telas (costo_general_id, nombre, consumo, precio_unitario)
             VALUES ($1, $2, $3, $4)`,
            [costo.id, t.nombre || null, parseFloat(t.consumo) || 0, parseFloat(t.precio_unitario) || 0]
          );
        }
      }

      if (insumos && Array.isArray(insumos)) {
        for (const i of insumos) {
          await client.query(
            `INSERT INTO costo_general_insumos (costo_general_id, nombre, cantidad, costo_unitario)
             VALUES ($1, $2, $3, $4)`,
            [costo.id, i.nombre || null, parseFloat(i.cantidad) || 0, parseFloat(i.costo_unitario) || 0]
          );
        }
      }

      await client.query('COMMIT');
      res.json(costo);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error creating costo_general:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.put('/generales/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { fecha, departamento_id, linea_id, modelo, tallas, descripcion, telas, insumos } = req.body;

    if (telas && Array.isArray(telas)) {
      for (const t of telas) {
        if (parseFloat(t.consumo) <= 0 || parseFloat(t.precio_unitario) <= 0) {
          return res.status(400).json({ error: 'El consumo y precio unitario de telas deben ser mayores a 0' });
        }
      }
    }

    if (insumos && Array.isArray(insumos)) {
      for (const i of insumos) {
        if (parseFloat(i.cantidad) <= 0 || parseFloat(i.costo_unitario) <= 0) {
          return res.status(400).json({ error: 'La cantidad y costo unitario de insumos deben ser mayores a 0' });
        }
      }
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      let existQ = 'SELECT * FROM costos_generales WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await client.query(existQ, existP);

      if (existing.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Costo general no encontrado' });
      }

      let upQ = `UPDATE costos_generales SET fecha = $1, departamento_id = $2, linea_id = $3, modelo = $4, tallas = $5, descripcion = $6 WHERE id = $7`;
      const upP = [fecha || new Date(), departamento_id || null, linea_id || null, modelo || null, tallas || null, descripcion || null, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $8`; upP.push(empresaId); }
      upQ += ' RETURNING *';
      const result = await client.query(upQ, upP);

      if (telas && Array.isArray(telas)) {
        await client.query('DELETE FROM costo_general_telas WHERE costo_general_id = $1', [req.params.id]);
        for (const t of telas) {
          await client.query(
            `INSERT INTO costo_general_telas (costo_general_id, nombre, consumo, precio_unitario)
             VALUES ($1, $2, $3, $4)`,
            [req.params.id, t.nombre || null, parseFloat(t.consumo) || 0, parseFloat(t.precio_unitario) || 0]
          );
        }
      }

      if (insumos && Array.isArray(insumos)) {
        await client.query('DELETE FROM costo_general_insumos WHERE costo_general_id = $1', [req.params.id]);
        for (const i of insumos) {
          await client.query(
            `INSERT INTO costo_general_insumos (costo_general_id, nombre, cantidad, costo_unitario)
             VALUES ($1, $2, $3, $4)`,
            [req.params.id, i.nombre || null, parseFloat(i.cantidad) || 0, parseFloat(i.costo_unitario) || 0]
          );
        }
      }

      await client.query('COMMIT');
      res.json(result.rows[0]);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error('Error updating costo_general:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    } finally {
      client.release();
    }
  });

  router.delete('/generales/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM costos_generales WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Costo general no encontrado' });
      }

      res.json({ message: 'Costo general eliminado correctamente' });
    } catch (err) {
      console.error('Error deleting costo_general:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  // ============================================================
  // COSTOS MEZCLILLA
  // ============================================================

  router.get('/mezclilla', authMiddleware, async (req, res) => {
    const params = [];
    const empresaFilter = getEmpresaFilter(req, 'cm', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search } = req.query;
      let query = `SELECT cm.* FROM costos_mezclilla cm WHERE ${empresaFilter}`;
      let idx = params.length + 1;

      if (search && search.trim()) {
        params.push(`%${search.trim().toLowerCase()}%`);
        query += ` AND (LOWER(COALESCE(cm.modelo,'')) LIKE $${idx} OR LOWER(COALESCE(cm.tela,'')) LIKE $${idx})`;
        idx++;
      }

      query += ` ORDER BY cm.created_at DESC`;

      const result = await pool.query(query, params);

      const rows = result.rows.map(r => {
        const totalTela = (parseFloat(r.costo_tela) || 0) * (parseFloat(r.consumo_tela) || 0);
        const totalPoquetin = (parseFloat(r.costo_poquetin) || 0) * (parseFloat(r.consumo_poquetin) || 0);
        const totalProcesos = (parseFloat(r.maquila) || 0) + (parseFloat(r.lavanderia) || 0) +
          (parseFloat(r.cierre) || 0) + (parseFloat(r.boton) || 0) + (parseFloat(r.remaches) || 0) +
          (parseFloat(r.etiquetas) || 0) + (parseFloat(r.flete_y_cajas) || 0);
        const total = totalTela + totalPoquetin + totalProcesos;
        const totalConGastos = total * 1.15;
        return { ...r, total_tela: totalTela, total_poquetin: totalPoquetin, total_procesos: totalProcesos, total, total_con_gastos: totalConGastos };
      });

      res.json(rows);
    } catch (err) {
      console.error('Error listing costos_mezclilla:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/mezclilla/:id', authMiddleware, async (req, res) => {
    const params = [req.params.id];
    const empresaFilter = getEmpresaFilter(req, 'cm', params);
    if (!empresaFilter) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const costo = await pool.query(
        `SELECT cm.* FROM costos_mezclilla cm WHERE cm.id = $1 AND ${empresaFilter}`,
        params
      );

      if (costo.rows.length === 0) {
        return res.status(404).json({ error: 'Costo mezclilla no encontrado' });
      }

      const r = costo.rows[0];
      const totalTela = (parseFloat(r.costo_tela) || 0) * (parseFloat(r.consumo_tela) || 0);
      const totalPoquetin = (parseFloat(r.costo_poquetin) || 0) * (parseFloat(r.consumo_poquetin) || 0);
      const totalProcesos = (parseFloat(r.maquila) || 0) + (parseFloat(r.lavanderia) || 0) +
        (parseFloat(r.cierre) || 0) + (parseFloat(r.boton) || 0) + (parseFloat(r.remaches) || 0) +
        (parseFloat(r.etiquetas) || 0) + (parseFloat(r.flete_y_cajas) || 0);
      const total = totalTela + totalPoquetin + totalProcesos;
      const totalConGastos = total * 1.15;

      res.json({
        ...r,
        total_tela: totalTela,
        total_poquetin: totalPoquetin,
        total_procesos: totalProcesos,
        total,
        total_con_gastos: totalConGastos
      });
    } catch (err) {
      console.error('Error getting costo_mezclilla:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/mezclilla', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { modelo, tela, fecha, costo_tela, consumo_tela, costo_poquetin, consumo_poquetin,
      maquila, lavanderia, cierre, boton, remaches, etiquetas, flete_y_cajas } = req.body;

    const numFields = { costo_tela, consumo_tela, costo_poquetin, consumo_poquetin,
      maquila, lavanderia, cierre, boton, remaches, etiquetas, flete_y_cajas };

    for (const [key, val] of Object.entries(numFields)) {
      if (val !== undefined && val !== null && parseFloat(val) < 0) {
        return res.status(400).json({ error: `El campo ${key} no puede ser negativo` });
      }
    }

    try {
      const usuarioNombre = req.user.nombre || req.user.email || 'usuario';
      const result = await pool.query(
        `INSERT INTO costos_mezclilla (empresa_id, modelo, tela, fecha, costo_tela, consumo_tela, costo_poquetin, consumo_poquetin,
          maquila, lavanderia, cierre, boton, remaches, etiquetas, flete_y_cajas, usuario_creacion)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
         RETURNING *`,
        [empresaId, modelo || null, tela || null, fecha || new Date(),
         parseFloat(costo_tela) || 0, parseFloat(consumo_tela) || 0,
         parseFloat(costo_poquetin) || 0, parseFloat(consumo_poquetin) || 0,
         parseFloat(maquila) || 0, parseFloat(lavanderia) || 0,
         parseFloat(cierre) || 0, parseFloat(boton) || 0,
         parseFloat(remaches) || 0, parseFloat(etiquetas) || 0,
         parseFloat(flete_y_cajas) || 0, usuarioNombre]
      );

      res.json(result.rows[0]);
    } catch (err) {
      console.error('Error creating costo_mezclilla:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/mezclilla/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    const { modelo, tela, fecha, costo_tela, consumo_tela, costo_poquetin, consumo_poquetin,
      maquila, lavanderia, cierre, boton, remaches, etiquetas, flete_y_cajas } = req.body;

    const numFields = { costo_tela, consumo_tela, costo_poquetin, consumo_poquetin,
      maquila, lavanderia, cierre, boton, remaches, etiquetas, flete_y_cajas };

    for (const [key, val] of Object.entries(numFields)) {
      if (val !== undefined && val !== null && parseFloat(val) < 0) {
        return res.status(400).json({ error: `El campo ${key} no puede ser negativo` });
      }
    }

    try {
      let existQ = 'SELECT * FROM costos_mezclilla WHERE id = $1';
      const existP = [req.params.id];
      if (empresaId) { existQ += ' AND empresa_id = $2'; existP.push(empresaId); }
      const existing = await pool.query(existQ, existP);

      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'Costo mezclilla no encontrado' });
      }

      let upQ = `UPDATE costos_mezclilla SET modelo = $1, tela = $2, fecha = $3,
        costo_tela = $4, consumo_tela = $5, costo_poquetin = $6, consumo_poquetin = $7,
        maquila = $8, lavanderia = $9, cierre = $10, boton = $11, remaches = $12,
        etiquetas = $13, flete_y_cajas = $14 WHERE id = $15`;
      const upP = [modelo || null, tela || null, fecha || new Date(),
        parseFloat(costo_tela) || 0, parseFloat(consumo_tela) || 0,
        parseFloat(costo_poquetin) || 0, parseFloat(consumo_poquetin) || 0,
        parseFloat(maquila) || 0, parseFloat(lavanderia) || 0,
        parseFloat(cierre) || 0, parseFloat(boton) || 0,
        parseFloat(remaches) || 0, parseFloat(etiquetas) || 0,
        parseFloat(flete_y_cajas) || 0, req.params.id];
      if (empresaId) { upQ += ` AND empresa_id = $16`; upP.push(empresaId); }
      upQ += ' RETURNING *';
      const result = await pool.query(upQ, upP);

      res.json(result.rows[0]);
    } catch (err) {
      console.error('Error updating costo_mezclilla:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.delete('/mezclilla/:id', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      let delQ = 'DELETE FROM costos_mezclilla WHERE id = $1';
      const delP = [req.params.id];
      if (empresaId) { delQ += ' AND empresa_id = $2'; delP.push(empresaId); }
      delQ += ' RETURNING *';
      const result = await pool.query(delQ, delP);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Costo mezclilla no encontrado' });
      }

      res.json({ message: 'Costo mezclilla eliminado correctamente' });
    } catch (err) {
      console.error('Error deleting costo_mezclilla:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
