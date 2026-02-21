const dns = require('dns');
const express = require('express');
const multer = require('multer');
const { parse } = require('csv-parse/sync');
const XLSX = require('xlsx');
const { Pool } = require('pg');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5000;

function parseSupabaseUrl(connString) {
  const match = connString.match(/^postgres(?:ql)?:\/\/([^:]+):(.+)@([^:\/]+):?(\d+)?\/(.+)$/);
  if (!match) return { connectionString: connString };
  const [, user, password, host, port, database] = match;
  return {
    host,
    port: parseInt(port || '5432'),
    database,
    user,
    password,
    ssl: { rejectUnauthorized: false }
  };
}

const pool = new Pool(parseSupabaseUrl(process.env.SUPABASE_DATABASE_URL));

const upload = multer({ dest: 'uploads/' });

app.use(express.json());
app.use(express.static('public'));

const CATALOG_TABLES = {
  empresas: {
    label: 'Empresas',
    columns: ['nombre', 'rfc', 'direccion', 'telefono', 'logo_url'],
    required: ['nombre'],
    selfTable: true
  },
  agentes: {
    label: 'Agentes',
    columns: ['nombre', 'apellido', 'comision', 'telefono', 'email'],
    required: ['nombre']
  },
  clientes: {
    label: 'Clientes',
    columns: ['nombre_comercial', 'razon_social', 'rfc', 'plazo_dias', 'limite_credito', 'contacto', 'telefono', 'email', 'calle', 'numero', 'colonia', 'ciudad', 'estado', 'pais', 'codigo_postal', 'observaciones'],
    required: ['nombre_comercial']
  },
  proveedores: {
    label: 'Proveedores',
    columns: ['nombre', 'contacto', 'rfc', 'plazo_pago_dias', 'calle', 'numero_exterior', 'numero_interior', 'colonia', 'ciudad', 'estado', 'codigo_postal', 'telefono_principal', 'telefono_secundario', 'email'],
    required: ['nombre']
  },
  departamentos: {
    label: 'Departamentos',
    columns: ['nombre'],
    required: ['nombre']
  },
  lineas: {
    label: 'Líneas',
    columns: ['nombre'],
    required: ['nombre']
  },
  marcas: {
    label: 'Marcas',
    columns: ['nombre', 'descripcion', 'dueno', 'regalia_porcentaje'],
    required: ['nombre']
  },
  colores: {
    label: 'Colores',
    columns: ['nombre'],
    required: ['nombre']
  },
  tallas: {
    label: 'Tallas',
    columns: ['nombre'],
    required: ['nombre']
  },
  unidades: {
    label: 'Unidades',
    columns: ['nombre', 'abreviatura', 'factor'],
    required: ['nombre']
  },
  modelos: {
    label: 'Modelos',
    columns: ['nombre', 'codigo', 'descripcion'],
    required: ['nombre']
  },
  articulos: {
    label: 'Artículos',
    columns: ['nombre', 'sku', 'descripcion'],
    required: ['nombre']
  },
  tipos_tela: {
    label: 'Tipos de Tela',
    columns: ['nombre'],
    required: ['nombre']
  },
  telas: {
    label: 'Telas',
    columns: ['nombre', 'composicion', 'peso', 'descripcion'],
    required: ['nombre']
  },
  maquileros: {
    label: 'Maquileros',
    columns: ['nombre', 'contacto', 'email', 'calle', 'numero_exterior', 'numero_interior', 'colonia', 'ciudad', 'estado', 'codigo_postal', 'telefono_principal', 'telefono_secundario'],
    required: ['nombre']
  },
  servicios: {
    label: 'Servicios',
    columns: ['nombre', 'descripcion', 'costo', 'plazo_pago_dias'],
    required: ['nombre']
  }
};

function parseFile(filePath, originalName) {
  const ext = path.extname(originalName).toLowerCase();

  if (ext === '.csv') {
    const content = fs.readFileSync(filePath, 'utf-8');
    return parse(content, { columns: true, skip_empty_lines: true, trim: true, bom: true });
  } else if (ext === '.xlsx' || ext === '.xls') {
    const workbook = XLSX.readFile(filePath);
    const sheetName = workbook.SheetNames[0];
    return XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { defval: '' });
  }

  throw new Error('Formato no soportado. Usa CSV o Excel (.xlsx/.xls)');
}

function normalizeColumnName(col) {
  return col
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9_]/g, '');
}

app.get('/api/tables', (req, res) => {
  const tables = Object.entries(CATALOG_TABLES).map(([key, val]) => ({
    key,
    label: val.label,
    columns: val.columns,
    required: val.required
  }));
  res.json(tables);
});

app.get('/api/empresas', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, nombre FROM empresas WHERE activo = true ORDER BY nombre');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/empresas', async (req, res) => {
  try {
    const { nombre, rfc, direccion, telefono, logo_url } = req.body;
    if (!nombre) return res.status(400).json({ error: 'El nombre es requerido' });
    const result = await pool.query(
      'INSERT INTO empresas (nombre, rfc, direccion, telefono, logo_url, activo, aprobado) VALUES ($1, $2, $3, $4, $5, true, true) RETURNING id, nombre',
      [nombre, rfc || null, direccion || null, telefono || null, logo_url || null]
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/upload/:table', upload.single('file'), async (req, res) => {
  const { table } = req.params;
  const empresaId = req.body.empresa_id;

  if (!CATALOG_TABLES[table]) {
    return res.status(400).json({ error: `Tabla "${table}" no es válida` });
  }

  const tableConfig = CATALOG_TABLES[table];

  if (!empresaId && !tableConfig.selfTable) {
    return res.status(400).json({ error: 'Selecciona una empresa' });
  }

  if (!req.file) {
    return res.status(400).json({ error: 'No se envió ningún archivo' });
  }

  try {
    const rows = parseFile(req.file.path, req.file.originalname);

    if (rows.length === 0) {
      return res.status(400).json({ error: 'El archivo está vacío' });
    }

    const fileColumns = Object.keys(rows[0]).map(normalizeColumnName);
    const validColumns = tableConfig.columns.filter(col => fileColumns.includes(col));

    if (validColumns.length === 0) {
      return res.status(400).json({
        error: 'No se encontraron columnas válidas',
        expected: tableConfig.columns,
        found: Object.keys(rows[0])
      });
    }

    const missingRequired = tableConfig.required.filter(r => !fileColumns.includes(r));
    if (missingRequired.length > 0) {
      return res.status(400).json({
        error: `Faltan columnas obligatorias: ${missingRequired.join(', ')}`,
        required: tableConfig.required
      });
    }

    let inserted = 0;
    let errors = [];

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const normalizedRow = {};
        Object.entries(row).forEach(([key, val]) => {
          normalizedRow[normalizeColumnName(key)] = val;
        });

        const cols = tableConfig.selfTable ? validColumns : ['empresa_id', ...validColumns];
        const vals = tableConfig.selfTable
          ? validColumns.map(c => normalizedRow[c] || '')
          : [empresaId, ...validColumns.map(c => normalizedRow[c] || '')];
        const placeholders = cols.map((_, idx) => `$${idx + 1}`);

        try {
          await client.query(
            `INSERT INTO ${table} (${cols.join(', ')}) VALUES (${placeholders.join(', ')})`,
            vals
          );
          inserted++;
        } catch (err) {
          errors.push({ row: i + 2, error: err.message });
        }
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

    res.json({
      message: `Se insertaron ${inserted} de ${rows.length} registros en "${tableConfig.label}"`,
      inserted,
      total: rows.length,
      errors: errors.length > 0 ? errors : undefined
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  } finally {
    fs.unlink(req.file.path, () => {});
  }
});

app.get('/api/data/:table', async (req, res) => {
  const { table } = req.params;
  const empresaId = req.query.empresa_id;

  if (!CATALOG_TABLES[table]) {
    return res.status(400).json({ error: `Tabla "${table}" no es válida` });
  }

  const tableConfig = CATALOG_TABLES[table];

  try {
    let query = `SELECT * FROM ${table}`;
    let params = [];

    if (empresaId && !tableConfig.selfTable) {
      query += ' WHERE empresa_id = $1';
      params.push(empresaId);
    }

    query += ' ORDER BY created_at DESC LIMIT 100';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const VALID_TABLE_NAMES = new Set(Object.keys(CATALOG_TABLES));

app.get('/api/stats', async (req, res) => {
  try {
    const stats = {};

    for (const table of VALID_TABLE_NAMES) {
      const result = await pool.query(`SELECT COUNT(*) as count FROM "${table}"`);
      stats[table] = parseInt(result.rows[0].count);
    }

    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/migrations', async (req, res) => {
  try {
    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/migrations/run', async (req, res) => {
  try {
    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    const results = [];

    for (const file of files) {
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
      try {
        await pool.query(sql);
        results.push({ file, status: 'ok' });
      } catch (err) {
        results.push({ file, status: 'error', error: err.message });
      }
    }

    res.json({ message: 'Migraciones ejecutadas', results });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Textil - Carga de Catálogos corriendo en puerto ${PORT}`);
});
