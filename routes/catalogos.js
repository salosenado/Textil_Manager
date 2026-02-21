const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');

const CATALOGS = {
  agentes: {
    table: 'agentes',
    label: 'Agentes',
    columns: ['nombre', 'apellido', 'comision', 'telefono', 'email', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'apellido', 'email'],
  },
  clientes: {
    table: 'clientes',
    label: 'Clientes',
    columns: ['nombre_comercial', 'razon_social', 'rfc', 'plazo_dias', 'limite_credito', 'contacto', 'telefono', 'email', 'calle', 'numero', 'colonia', 'ciudad', 'estado', 'pais', 'codigo_postal', 'observaciones', 'activo'],
    required: ['nombre_comercial'],
    nameField: 'nombre_comercial',
    orderBy: 'nombre_comercial',
    searchFields: ['nombre_comercial', 'razon_social', 'contacto', 'email'],
  },
  proveedores: {
    table: 'proveedores',
    label: 'Proveedores',
    columns: ['nombre', 'contacto', 'rfc', 'plazo_pago_dias', 'calle', 'numero_exterior', 'numero_interior', 'colonia', 'ciudad', 'estado', 'codigo_postal', 'telefono_principal', 'telefono_secundario', 'email', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'contacto', 'rfc', 'email'],
  },
  articulos: {
    table: 'articulos',
    label: 'Artículos',
    columns: ['nombre', 'sku', 'descripcion', 'precio_venta', 'costo', 'existencia', 'marca_id', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'sku', 'descripcion'],
  },
  colores: {
    table: 'colores',
    label: 'Colores',
    columns: ['nombre', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre'],
  },
  tallas: {
    table: 'tallas',
    label: 'Tallas',
    columns: ['nombre', 'orden', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'orden, nombre',
    searchFields: ['nombre'],
  },
  modelos: {
    table: 'modelos',
    label: 'Modelos',
    columns: ['nombre', 'codigo', 'descripcion', 'existencia', 'marca_id', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'codigo'],
  },
  marcas: {
    table: 'marcas',
    label: 'Marcas',
    columns: ['nombre', 'descripcion', 'dueno', 'regalia_porcentaje', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre'],
  },
  lineas: {
    table: 'lineas',
    label: 'Líneas',
    columns: ['nombre', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre'],
  },
  departamentos: {
    table: 'departamentos',
    label: 'Departamentos',
    columns: ['nombre', 'descripcion', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'descripcion'],
  },
  unidades: {
    table: 'unidades',
    label: 'Unidades',
    columns: ['nombre', 'abreviatura', 'factor'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'abreviatura'],
  },
  tipos_tela: {
    table: 'tipos_tela',
    label: 'Tipos de Tela',
    columns: ['nombre', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre'],
  },
  telas: {
    table: 'telas',
    label: 'Telas',
    columns: ['nombre', 'composicion', 'proveedor_id', 'descripcion', 'activa'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'composicion'],
    activeField: 'activa',
  },
  maquileros: {
    table: 'maquileros',
    label: 'Maquileros',
    columns: ['nombre', 'contacto', 'calle', 'numero_exterior', 'numero_interior', 'colonia', 'ciudad', 'estado', 'codigo_postal', 'telefono_principal', 'telefono_secundario', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre', 'contacto'],
  },
  servicios: {
    table: 'servicios',
    label: 'Servicios',
    columns: ['nombre', 'descripcion', 'costo', 'activo'],
    required: ['nombre'],
    nameField: 'nombre',
    orderBy: 'nombre',
    searchFields: ['nombre'],
  },
};

module.exports = function(pool) {

  router.get('/config', authMiddleware, (req, res) => {
    const config = {};
    for (const [key, cat] of Object.entries(CATALOGS)) {
      config[key] = { label: cat.label, columns: cat.columns, required: cat.required };
    }
    res.json(config);
  });

  router.get('/telas/:telaId/precios', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const result = await pool.query(
        `SELECT pt.* FROM precios_tela pt
         JOIN telas t ON pt.tela_id = t.id
         WHERE pt.tela_id = $1 AND t.empresa_id = $2
         ORDER BY pt.tipo, pt.fecha DESC`,
        [req.params.telaId, empresaId]
      );
      res.json(result.rows);
    } catch (err) {
      console.error('Error listing precios_tela:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/telas/:telaId/precios', authMiddleware, async (req, res) => {
    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const telaCheck = await pool.query(
        'SELECT id FROM telas WHERE id = $1 AND empresa_id = $2',
        [req.params.telaId, empresaId]
      );
      if (telaCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Tela no encontrada' });
      }

      const { precios } = req.body;
      if (!precios || !Array.isArray(precios)) {
        return res.status(400).json({ error: 'Se requiere un array de precios' });
      }

      await pool.query('DELETE FROM precios_tela WHERE tela_id = $1', [req.params.telaId]);

      const inserted = [];
      for (const p of precios) {
        if (p.tipo && p.precio !== undefined && p.precio !== '' && p.precio !== null) {
          const result = await pool.query(
            'INSERT INTO precios_tela (tela_id, tipo, precio) VALUES ($1, $2, $3) RETURNING *',
            [req.params.telaId, p.tipo, p.precio]
          );
          inserted.push(result.rows[0]);
        }
      }

      res.json(inserted);
    } catch (err) {
      console.error('Error saving precios_tela:', err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:catalogo', authMiddleware, async (req, res) => {
    const catalog = CATALOGS[req.params.catalogo];
    if (!catalog) {
      return res.status(404).json({ error: 'Catálogo no encontrado' });
    }

    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const { search } = req.query;
      let query = `SELECT * FROM ${catalog.table} WHERE empresa_id = $1`;
      const params = [empresaId];

      if (search && search.trim()) {
        const searchConditions = catalog.searchFields.map((field, i) => {
          params.push(`%${search.trim().toLowerCase()}%`);
          return `LOWER(${field}) LIKE $${params.length}`;
        }).join(' OR ');
        query += ` AND (${searchConditions})`;
      }

      query += ` ORDER BY ${catalog.orderBy}`;

      const result = await pool.query(query, params);
      res.json(result.rows);
    } catch (err) {
      console.error(`Error listing ${catalog.table}:`, err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.get('/:catalogo/:id', authMiddleware, async (req, res) => {
    const catalog = CATALOGS[req.params.catalogo];
    if (!catalog) {
      return res.status(404).json({ error: 'Catálogo no encontrado' });
    }

    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const result = await pool.query(
        `SELECT * FROM ${catalog.table} WHERE id = $1 AND empresa_id = $2`,
        [req.params.id, empresaId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: `${catalog.label} no encontrado` });
      }
      res.json(result.rows[0]);
    } catch (err) {
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.post('/:catalogo', authMiddleware, async (req, res) => {
    const catalog = CATALOGS[req.params.catalogo];
    if (!catalog) {
      return res.status(404).json({ error: 'Catálogo no encontrado' });
    }

    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    for (const field of catalog.required) {
      if (!req.body[field] || !String(req.body[field]).trim()) {
        return res.status(400).json({ error: `El campo "${field}" es requerido` });
      }
    }

    try {
      const fields = ['empresa_id'];
      const values = [empresaId];
      const placeholders = ['$1'];
      let idx = 2;

      for (const col of catalog.columns) {
        if (req.body[col] !== undefined) {
          fields.push(col);
          values.push(req.body[col] === '' ? null : req.body[col]);
          placeholders.push(`$${idx++}`);
        }
      }

      const result = await pool.query(
        `INSERT INTO ${catalog.table} (${fields.join(', ')}) VALUES (${placeholders.join(', ')}) RETURNING *`,
        values
      );
      res.json(result.rows[0]);
    } catch (err) {
      if (err.code === '23505') {
        return res.status(400).json({ error: 'Ya existe un registro con esos datos' });
      }
      console.error(`Error creating ${catalog.table}:`, err.message);
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.put('/:catalogo/:id', authMiddleware, async (req, res) => {
    const catalog = CATALOGS[req.params.catalogo];
    if (!catalog) {
      return res.status(404).json({ error: 'Catálogo no encontrado' });
    }

    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    for (const field of catalog.required) {
      if (!req.body[field] || !String(req.body[field]).trim()) {
        return res.status(400).json({ error: `El campo "${field}" es requerido` });
      }
    }

    try {
      const setClauses = [];
      const values = [];
      let idx = 1;

      for (const col of catalog.columns) {
        if (req.body[col] !== undefined) {
          setClauses.push(`${col} = $${idx++}`);
          values.push(req.body[col] === '' ? null : req.body[col]);
        }
      }

      if (setClauses.length === 0) {
        return res.status(400).json({ error: 'No hay campos para actualizar' });
      }

      values.push(req.params.id);
      values.push(empresaId);

      const result = await pool.query(
        `UPDATE ${catalog.table} SET ${setClauses.join(', ')} WHERE id = $${idx++} AND empresa_id = $${idx} RETURNING *`,
        values
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: `${catalog.label} no encontrado` });
      }
      res.json(result.rows[0]);
    } catch (err) {
      if (err.code === '23505') {
        return res.status(400).json({ error: 'Ya existe un registro con esos datos' });
      }
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  router.delete('/:catalogo/:id', authMiddleware, async (req, res) => {
    const catalog = CATALOGS[req.params.catalogo];
    if (!catalog) {
      return res.status(404).json({ error: 'Catálogo no encontrado' });
    }

    const empresaId = req.user.empresa_id;
    if (!empresaId && !req.user.es_root) {
      return res.status(403).json({ error: 'No tienes empresa asignada' });
    }

    try {
      const result = await pool.query(
        `DELETE FROM ${catalog.table} WHERE id = $1 AND empresa_id = $2 RETURNING *`,
        [req.params.id, empresaId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: `${catalog.label} no encontrado` });
      }
      res.json({ message: `${catalog.label} eliminado correctamente` });
    } catch (err) {
      if (err.code === '23503') {
        return res.status(400).json({ error: `No se puede eliminar porque tiene datos asociados. Desactívalo en su lugar.` });
      }
      res.status(500).json({ error: 'Error del servidor' });
    }
  });

  return router;
};
