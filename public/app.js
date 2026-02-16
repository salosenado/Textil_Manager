let selectedTable = null;
let tables = [];

async function init() {
    await Promise.all([
        cargarEmpresas(),
        cargarTablas(),
        cargarStats()
    ]);
}

async function cargarEmpresas() {
    try {
        const res = await fetch('/api/empresas');
        const empresas = await res.json();
        const select = document.getElementById('empresaSelect');
        select.innerHTML = '<option value="">-- Selecciona empresa --</option>';
        empresas.forEach(e => {
            select.innerHTML += `<option value="${e.id}">${e.nombre}</option>`;
        });
    } catch (err) {
        showToast('Error cargando empresas');
    }
}

async function crearEmpresa() {
    const input = document.getElementById('nuevaEmpresa');
    const nombre = input.value.trim();
    if (!nombre) return showToast('Escribe el nombre de la empresa');

    try {
        const res = await fetch('/api/empresas', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ nombre })
        });
        const data = await res.json();
        if (res.ok) {
            input.value = '';
            await cargarEmpresas();
            document.getElementById('empresaSelect').value = data.id;
            showToast(`Empresa "${nombre}" creada`);
            cargarStats();
        } else {
            showToast(data.error);
        }
    } catch (err) {
        showToast('Error creando empresa');
    }
}

async function cargarTablas() {
    try {
        const res = await fetch('/api/tables');
        tables = await res.json();
        const grid = document.getElementById('catalogoGrid');
        const previewSelect = document.getElementById('previewSelect');

        grid.innerHTML = '';
        tables.forEach(t => {
            const card = document.createElement('div');
            card.className = 'catalogo-card';
            card.textContent = t.label;
            card.onclick = () => seleccionarCatalogo(t);
            card.id = `card-${t.key}`;
            grid.appendChild(card);

            previewSelect.innerHTML += `<option value="${t.key}">${t.label}</option>`;
        });
    } catch (err) {
        showToast('Error cargando catálogos');
    }
}

function seleccionarCatalogo(table) {
    document.querySelectorAll('.catalogo-card').forEach(c => c.classList.remove('active'));
    document.getElementById(`card-${table.key}`).classList.add('active');

    selectedTable = table;

    document.getElementById('uploadSection').style.display = 'block';
    document.getElementById('catalogoNombre').textContent = table.label;

    const colsHtml = table.columns.map(c => {
        const isReq = table.required.includes(c);
        return isReq ? `<span class="col-required">${c}</span>` : c;
    }).join(', ');
    document.getElementById('columnasEsperadas').innerHTML = colsHtml;

    document.getElementById('fileInput').value = '';
    document.getElementById('fileName').textContent = '';
    document.getElementById('uploadBtn').disabled = true;
    document.getElementById('resultSection').style.display = 'none';
}

function handleFileSelect() {
    const file = document.getElementById('fileInput').files[0];
    if (file) {
        document.getElementById('fileName').textContent = file.name;
        document.getElementById('uploadBtn').disabled = false;
    }
}

async function subirArchivo() {
    const empresaId = document.getElementById('empresaSelect').value;
    if (!empresaId) return showToast('Selecciona una empresa primero');
    if (!selectedTable) return showToast('Selecciona un catálogo');

    const file = document.getElementById('fileInput').files[0];
    if (!file) return showToast('Selecciona un archivo');

    const btn = document.getElementById('uploadBtn');
    btn.disabled = true;
    btn.textContent = 'Cargando...';

    const formData = new FormData();
    formData.append('file', file);
    formData.append('empresa_id', empresaId);

    try {
        const res = await fetch(`/api/upload/${selectedTable.key}`, {
            method: 'POST',
            body: formData
        });
        const data = await res.json();

        const resultDiv = document.getElementById('resultContent');
        document.getElementById('resultSection').style.display = 'block';

        if (res.ok) {
            let html = `<div class="result-success">${data.message}</div>`;
            if (data.errors && data.errors.length > 0) {
                html += `<div class="result-warning">`;
                html += `<strong>${data.errors.length} errores:</strong><br>`;
                data.errors.slice(0, 10).forEach(e => {
                    html += `Fila ${e.row}: ${e.error}<br>`;
                });
                if (data.errors.length > 10) {
                    html += `... y ${data.errors.length - 10} más`;
                }
                html += `</div>`;
            }
            resultDiv.innerHTML = html;
            cargarStats();
        } else {
            let html = `<div class="result-error">${data.error}</div>`;
            if (data.expected) {
                html += `<div class="result-warning">Columnas esperadas: ${data.expected.join(', ')}</div>`;
            }
            if (data.found) {
                html += `<div class="result-warning">Columnas encontradas: ${data.found.join(', ')}</div>`;
            }
            resultDiv.innerHTML = html;
        }
    } catch (err) {
        showToast('Error subiendo archivo');
    } finally {
        btn.disabled = false;
        btn.textContent = 'Subir y Cargar';
    }
}

async function cargarStats() {
    try {
        const res = await fetch('/api/stats');
        const stats = await res.json();
        const grid = document.getElementById('statsGrid');

        const entries = Object.entries(stats);
        if (entries.every(([, v]) => v === 0)) {
            grid.innerHTML = '<p class="loading">No hay datos todavía. Sube un archivo para comenzar.</p>';
            return;
        }

        grid.innerHTML = '';
        entries.forEach(([key, count]) => {
            const tableInfo = tables.find(t => t.key === key);
            const label = tableInfo ? tableInfo.label : key;
            grid.innerHTML += `
                <div class="stat-card">
                    <div class="count">${count}</div>
                    <div class="label">${label}</div>
                </div>
            `;
        });
    } catch (err) {
        document.getElementById('statsGrid').innerHTML = '<p class="loading">Error cargando datos</p>';
    }
}

async function cargarPreview() {
    const table = document.getElementById('previewSelect').value;
    const container = document.getElementById('previewTable');
    if (!table) {
        container.innerHTML = '';
        return;
    }

    const empresaId = document.getElementById('empresaSelect').value;

    try {
        let url = `/api/data/${table}`;
        if (empresaId) url += `?empresa_id=${empresaId}`;

        const res = await fetch(url);
        const rows = await res.json();

        if (rows.length === 0) {
            container.innerHTML = '<p class="loading">No hay datos en este catálogo</p>';
            return;
        }

        const excludeCols = ['id', 'empresa_id', 'created_at', 'updated_at', 'password_hash'];
        const cols = Object.keys(rows[0]).filter(c => !excludeCols.includes(c));

        let html = '<table><thead><tr>';
        cols.forEach(c => { html += `<th>${c}</th>`; });
        html += '</tr></thead><tbody>';

        rows.forEach(row => {
            html += '<tr>';
            cols.forEach(c => {
                let val = row[c];
                if (val === null || val === undefined) val = '';
                if (typeof val === 'boolean') val = val ? 'Sí' : 'No';
                if (val instanceof Object) val = JSON.stringify(val);
                const str = String(val);
                html += `<td>${str.length > 50 ? str.substring(0, 50) + '...' : str}</td>`;
            });
            html += '</tr>';
        });

        html += '</tbody></table>';
        container.innerHTML = html;
    } catch (err) {
        container.innerHTML = '<p class="loading">Error cargando datos</p>';
    }
}

async function ejecutarMigraciones() {
    const resultDiv = document.getElementById('migrationResult');
    resultDiv.innerHTML = '<p class="loading">Ejecutando migraciones...</p>';

    try {
        const res = await fetch('/api/migrations/run', { method: 'POST' });
        const data = await res.json();

        let html = '';
        data.results.forEach(r => {
            const icon = r.status === 'ok' ? '✓' : '✗';
            const cls = r.status === 'ok' ? 'color:#155724' : 'color:#721c24';
            html += `<p style="${cls}">${icon} ${r.file}${r.error ? ': ' + r.error : ''}</p>`;
        });

        resultDiv.innerHTML = html;
        showToast('Migraciones completadas');
        cargarStats();
    } catch (err) {
        resultDiv.innerHTML = '<p style="color:#721c24">Error ejecutando migraciones</p>';
    }
}

function showToast(msg) {
    const toast = document.getElementById('toast');
    toast.textContent = msg;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 3000);
}

document.addEventListener('DOMContentLoaded', init);
