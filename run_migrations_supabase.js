const dns = require('dns');
dns.setDefaultResultOrder('ipv4first');

const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

async function run() {
  const connString = process.env.SUPABASE_DATABASE_URL;
  if (!connString) {
    console.error('SUPABASE_DATABASE_URL no está configurada');
    process.exit(1);
  }

  const match = connString.match(/^postgres(?:ql)?:\/\/([^:]+):(.+)@([^:\/]+):?(\d+)?\/(.+)$/);
  if (!match) {
    console.error('No se pudo parsear la URL. Formato esperado: postgresql://user:pass@host:port/db');
    process.exit(1);
  }

  const [, user, password, host, port, database] = match;

  let resolvedHost = host;
  try {
    const dns = require('dns').promises;
    const result = await dns.resolve6(host);
    if (result && result.length > 0) {
      resolvedHost = result[0];
      console.log(`Resolviendo ${host} -> [${resolvedHost}]`);
    }
  } catch (e) {}

  const client = new Client({
    host: resolvedHost,
    port: parseInt(port || '5432'),
    database,
    user,
    password,
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    console.log('Conectado a Supabase exitosamente\n');

    const migrationsDir = path.join(__dirname, 'migrations');
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    for (const file of files) {
      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
      try {
        await client.query(sql);
        console.log(`✓ ${file}`);
      } catch (err) {
        console.error(`✗ ${file}: ${err.message}`);
      }
    }

    console.log('\nMigraciones completadas');
  } catch (err) {
    console.error('Error de conexión:', err.message);
  } finally {
    await client.end();
  }
}

run();
