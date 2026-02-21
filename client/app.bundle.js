const API = '/api';
let currentUser = null;
let currentScreen = 'login';
let allPermisos = [];
let empresaRoles = [];
let empresaUsuarios = [];

function getToken() { return localStorage.getItem('textil_token'); }
function setToken(t) { localStorage.setItem('textil_token', t); }
function removeToken() { localStorage.removeItem('textil_token'); }

async function apiFetch(url, opts = {}) {
  const token = getToken();
  const headers = { ...opts.headers };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (opts.body && typeof opts.body === 'object' && !(opts.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(opts.body);
  }
  const res = await fetch(API + url, { ...opts, headers });
  const data = await res.json();
  if (res.status === 401) { removeToken(); currentUser = null; showScreen('login'); throw new Error(data.error); }
  if (!res.ok) throw new Error(data.error || data.message || 'Error');
  return data;
}

async function init() {
  renderApp();
  const token = getToken();
  if (token) {
    try {
      currentUser = await apiFetch('/auth/me');
      if (!currentUser.activo) { showScreen('blocked'); return; }
      if (!currentUser.aprobado) { showScreen('pending'); return; }
      showScreen('home');
    } catch { showScreen('login'); }
  } else {
    showScreen('login');
  }
}

function showScreen(name, data) {
  currentScreen = name;
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const el = document.getElementById(`screen-${name}`);
  if (el) el.classList.add('active');

  const tabBar = document.getElementById('tab-bar');
  const mainScreens = ['home', 'operations', 'purchases', 'sales', 'admin'];
  tabBar.style.display = mainScreens.includes(name) ? 'flex' : 'none';

  document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
  const activeTab = document.querySelector(`[data-tab="${name}"]`);
  if (activeTab) activeTab.classList.add('active');

  const renderers = {
    login: renderLogin,
    blocked: renderBlocked,
    pending: renderPending,
    home: renderHome,
    operations: renderOperations,
    purchases: renderPurchases,
    sales: renderSales,
    admin: renderAdmin,
    profile: renderProfile,
    users: renderUsers,
    'user-detail': () => renderUserDetail(data),
    roles: renderRoles,
    'role-form': () => renderRoleForm(data),
    'change-password': renderChangePassword
  };
  if (renderers[name]) renderers[name]();
}

function hasPermiso(clave) {
  if (!currentUser) return false;
  if (currentUser.es_root) return true;
  return currentUser.permisos && currentUser.permisos.includes(clave);
}

function showToast(msg) {
  const toast = document.getElementById('toast');
  toast.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 3000);
}

function renderApp() {
  document.getElementById('app').innerHTML = `
    <div id="screen-login" class="screen login-screen"></div>
    <div id="screen-blocked" class="screen status-screen"></div>
    <div id="screen-pending" class="screen status-screen"></div>
    <div id="screen-home" class="screen"></div>
    <div id="screen-operations" class="screen"></div>
    <div id="screen-purchases" class="screen"></div>
    <div id="screen-sales" class="screen"></div>
    <div id="screen-admin" class="screen"></div>
    <div id="screen-profile" class="screen"></div>
    <div id="screen-users" class="screen"></div>
    <div id="screen-user-detail" class="screen"></div>
    <div id="screen-roles" class="screen"></div>
    <div id="screen-role-form" class="screen"></div>
    <div id="screen-change-password" class="screen"></div>
    <div id="tab-bar" class="tab-bar" style="display:none">
      <button class="tab-item" data-tab="home" onclick="showScreen('home')">
        <span class="material-icons-outlined">home</span>
        Inicio
      </button>
      <button class="tab-item" data-tab="operations" onclick="showScreen('operations')">
        <span class="material-icons-outlined">settings</span>
        Operación
      </button>
      <button class="tab-item" data-tab="purchases" onclick="showScreen('purchases')">
        <span class="material-icons-outlined">shopping_cart</span>
        Compras
      </button>
      <button class="tab-item" data-tab="sales" onclick="showScreen('sales')">
        <span class="material-icons-outlined">point_of_sale</span>
        Ventas
      </button>
      <button class="tab-item" data-tab="admin" onclick="showScreen('admin')">
        <span class="material-icons-outlined">business</span>
        Admin
      </button>
    </div>
    <div id="toast" class="toast"></div>
    <div id="modal-container"></div>
  `;
}

function renderLogin() {
  document.getElementById('screen-login').innerHTML = `
    <div class="login-logo">
      <span class="material-icons-outlined icon">checkroom</span>
      <div class="large-title">Textil</div>
      <div class="subheadline">Sistema de gestión textil</div>
    </div>
    <form id="loginForm" onsubmit="handleLogin(event)">
      <input type="email" class="input-full" id="loginEmail" placeholder="Correo electrónico" autocomplete="email" required>
      <input type="password" class="input-full" id="loginPassword" placeholder="Contraseña" autocomplete="current-password" required>
      <div id="loginError" class="error-message" style="display:none"></div>
      <button type="submit" class="btn-primary" id="loginBtn">Iniciar sesión</button>
    </form>
    <div style="text-align:center; margin-top:24px">
      <div class="footnote">Credenciales de prueba:</div>
      <div class="caption" style="margin-top:4px">root@textil.app / Admin123!</div>
    </div>
  `;
}

async function handleLogin(e) {
  e.preventDefault();
  const btn = document.getElementById('loginBtn');
  const errorEl = document.getElementById('loginError');
  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;

  btn.disabled = true;
  btn.textContent = 'Iniciando sesión...';
  errorEl.style.display = 'none';

  try {
    const data = await apiFetch('/auth/login', {
      method: 'POST',
      body: { email, password }
    });
    setToken(data.token);
    currentUser = data.user;

    if (!currentUser.activo) { showScreen('blocked'); return; }
    if (!currentUser.aprobado) { showScreen('pending'); return; }
    showScreen('home');
  } catch (err) {
    if (err.message === 'blocked') { showScreen('blocked'); return; }
    if (err.message === 'pending') { showScreen('pending'); return; }
    errorEl.textContent = err.message;
    errorEl.style.display = 'block';
  } finally {
    btn.disabled = false;
    btn.textContent = 'Iniciar sesión';
  }
}

function renderBlocked() {
  document.getElementById('screen-blocked').innerHTML = `
    <span class="material-icons-outlined status-icon" style="color:var(--text-error)">block</span>
    <div class="large-title">Cuenta desactivada</div>
    <div class="subheadline" style="margin-top:8px; max-width:300px">
      Tu cuenta ha sido desactivada. Contacta al administrador de tu empresa para más información.
    </div>
    <button class="btn-secondary" style="margin-top:32px" onclick="handleLogout()">Cerrar sesión</button>
  `;
}

function renderPending() {
  document.getElementById('screen-pending').innerHTML = `
    <span class="material-icons-outlined status-icon" style="color:#F57C00">hourglass_empty</span>
    <div class="large-title">Pendiente de aprobación</div>
    <div class="subheadline" style="margin-top:8px; max-width:300px">
      Tu cuenta está pendiente de aprobación. El administrador de tu empresa revisará tu solicitud pronto.
    </div>
    <button class="btn-secondary" style="margin-top:32px" onclick="handleLogout()">Cerrar sesión</button>
  `;
}

function renderHome() {
  const greeting = currentUser.es_root ? 'Administrador del Sistema' : (currentUser.empresa ? currentUser.empresa.nombre : '');
  const rolName = currentUser.es_root ? 'Root' : (currentUser.rol ? currentUser.rol.nombre : 'Sin rol');

  const quickLinks = [];
  if (hasPermiso('catalogos.ver')) quickLinks.push({ icon: 'inventory_2', label: 'Catálogos', screen: 'admin' });
  if (hasPermiso('produccion.ver')) quickLinks.push({ icon: 'precision_manufacturing', label: 'Producción', screen: 'operations' });
  if (hasPermiso('ordenes.ver')) quickLinks.push({ icon: 'receipt_long', label: 'Órdenes', screen: 'sales' });
  if (hasPermiso('ventas.ver')) quickLinks.push({ icon: 'point_of_sale', label: 'Ventas', screen: 'sales' });
  if (hasPermiso('compras.ver')) quickLinks.push({ icon: 'shopping_cart', label: 'Compras', screen: 'purchases' });
  if (hasPermiso('costos.ver')) quickLinks.push({ icon: 'calculate', label: 'Costos', screen: 'operations' });
  if (hasPermiso('inventarios.ver')) quickLinks.push({ icon: 'warehouse', label: 'Inventarios', screen: 'operations' });
  if (hasPermiso('reportes.ver')) quickLinks.push({ icon: 'assessment', label: 'Reportes', screen: 'admin' });

  if (quickLinks.length === 0) {
    quickLinks.push(
      { icon: 'person', label: 'Mi Perfil', screen: 'profile' },
      { icon: 'settings', label: 'Ajustes', screen: 'admin' }
    );
  }

  document.getElementById('screen-home').innerHTML = `
    <div class="header-bar">
      <div class="subheadline">Bienvenido a</div>
      <div class="large-title">Textil</div>
      <div class="subheadline">${currentUser.nombre} · ${rolName}</div>
    </div>
    <div class="screen-content">
      ${greeting ? `<div class="headline" style="margin-bottom:4px">${greeting}</div>` : ''}
      <div class="title3" style="margin: 24px 0 16px">Accesos rápidos</div>
      <div class="quick-grid">
        ${quickLinks.map(q => `
          <div class="quick-card" onclick="showScreen('${q.screen}')">
            <span class="material-icons-outlined">${q.icon}</span>
            <span>${q.label}</span>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

function renderModuleList(screenId, title, items) {
  document.getElementById(`screen-${screenId}`).innerHTML = `
    <div class="header-bar">
      <div class="large-title">${title}</div>
      ${currentUser.empresa ? `<div class="caption">${currentUser.empresa.nombre}</div>` : ''}
    </div>
    <div class="screen-content">
      ${items.length === 0 ? `
        <div class="empty-state">
          <span class="material-icons-outlined">lock</span>
          <div class="headline" style="margin-top:8px">Sin acceso</div>
          <div class="subheadline">No tienes permisos para ver este módulo</div>
        </div>
      ` : items.map(item => `
        <div class="card" onclick="${item.action || ''}">
          <div class="card-content">
            <div style="display:flex;align-items:center;gap:8px">
              <span class="material-icons-outlined" style="color:var(--accent);font-size:22px">${item.icon}</span>
              <div class="card-title">${item.label}</div>
            </div>
            ${item.subtitle ? `<div class="card-subtitle" style="margin-left:30px">${item.subtitle}</div>` : ''}
          </div>
          <span class="material-icons-outlined card-chevron">chevron_right</span>
        </div>
      `).join('')}
    </div>
  `;
}

function renderOperations() {
  const items = [];
  if (hasPermiso('costos.ver')) items.push({ icon: 'calculate', label: 'Costos', subtitle: 'Costos generales y de mezclilla' });
  if (hasPermiso('produccion.ver')) items.push({ icon: 'precision_manufacturing', label: 'Producción', subtitle: 'Control de producción y maquileros' });
  if (hasPermiso('produccion.ver')) items.push({ icon: 'fact_check', label: 'Recibos', subtitle: 'Recibos de producción y compras' });
  if (hasPermiso('inventarios.ver')) items.push({ icon: 'warehouse', label: 'Inventarios', subtitle: 'Existencias y movimientos' });
  renderModuleList('operations', 'Operación', items);
}

function renderPurchases() {
  const items = [];
  if (hasPermiso('compras.ver')) items.push({ icon: 'shopping_bag', label: 'Compras Clientes', subtitle: 'Compras especiales por pedido' });
  if (hasPermiso('compras.ver')) items.push({ icon: 'local_shipping', label: 'Compras Insumos', subtitle: 'Compras a proveedores' });
  if (hasPermiso('servicios.ver')) items.push({ icon: 'build', label: 'Servicios', subtitle: 'Solicitudes y recibos' });
  renderModuleList('purchases', 'Compras', items);
}

function renderSales() {
  const items = [];
  if (hasPermiso('ordenes.ver')) items.push({ icon: 'receipt_long', label: 'Órdenes', subtitle: 'Órdenes de clientes' });
  if (hasPermiso('ventas.ver')) items.push({ icon: 'point_of_sale', label: 'Ventas', subtitle: 'Ventas y cobros' });
  if (hasPermiso('inventarios.ver')) items.push({ icon: 'logout', label: 'Salidas', subtitle: 'Salidas de insumos' });
  if (hasPermiso('reingresos.ver')) items.push({ icon: 'login', label: 'Reingresos', subtitle: 'Devoluciones y reingresos' });
  renderModuleList('sales', 'Ventas', items);
}

function renderAdmin() {
  const items = [];
  if (hasPermiso('catalogos.ver')) items.push({ icon: 'inventory_2', label: 'Catálogos', subtitle: 'Agentes, clientes, proveedores...' });
  if (hasPermiso('reportes.ver')) items.push({ icon: 'assessment', label: 'Reportes', subtitle: 'Resúmenes y estadísticas' });
  if (hasPermiso('usuarios.ver') || currentUser.es_root) items.push({ icon: 'people', label: 'Usuarios', subtitle: 'Gestión de usuarios', action: "showScreen('users')" });
  if (hasPermiso('roles.ver') || currentUser.es_root) items.push({ icon: 'admin_panel_settings', label: 'Roles y Permisos', subtitle: 'Gestión de roles', action: "showScreen('roles')" });
  items.push({ icon: 'person', label: 'Mi Perfil', subtitle: 'Datos personales y sesión', action: "showScreen('profile')" });
  renderModuleList('admin', 'Administración', items);
}

function renderProfile() {
  const rolName = currentUser.es_root ? 'Administrador Root' : (currentUser.rol ? currentUser.rol.nombre : 'Sin rol asignado');
  const empresaName = currentUser.empresa ? currentUser.empresa.nombre : 'Sistema';

  document.getElementById('screen-profile').innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('admin')">← Atrás</button>
      <div class="toolbar-title">Mi Perfil</div>
      <div style="width:50px"></div>
    </div>
    <div class="screen-content">
      <div style="text-align:center; padding:24px 0">
        <span class="material-icons-outlined" style="font-size:80px;color:var(--accent)">account_circle</span>
        <div class="title3" style="margin-top:8px">${currentUser.nombre}</div>
        <div class="subheadline">${currentUser.email}</div>
      </div>

      <div class="form-section">
        <div class="form-section-title">Información</div>
        <div class="form-group">
          <div class="form-row">
            <label>Empresa</label>
            <span class="body" style="color:var(--text-secondary)">${empresaName}</span>
          </div>
          <div class="form-row">
            <label>Rol</label>
            <span class="body" style="color:var(--text-secondary)">${rolName}</span>
          </div>
          <div class="form-row">
            <label>Estado</label>
            <span class="badge badge-green">Activo</span>
          </div>
        </div>
      </div>

      <div class="form-section">
        <div class="form-section-title">Cuenta</div>
        <div class="form-group">
          <div class="form-row card" onclick="showScreen('change-password')" style="margin-bottom:0;border-radius:var(--radius) var(--radius) 0 0">
            <div class="card-content">
              <div style="display:flex;align-items:center;gap:8px">
                <span class="material-icons-outlined" style="color:var(--accent)">lock</span>
                <span>Cambiar contraseña</span>
              </div>
            </div>
            <span class="material-icons-outlined card-chevron">chevron_right</span>
          </div>
        </div>
      </div>

      <button class="btn-danger" onclick="handleLogout()" style="margin-top:16px">
        Cerrar sesión
      </button>
    </div>
  `;
}

function renderChangePassword() {
  document.getElementById('screen-change-password').innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('profile')">Cancelar</button>
      <div class="toolbar-title">Cambiar Contraseña</div>
      <button class="toolbar-btn semibold" onclick="handleChangePassword()">Guardar</button>
    </div>
    <div class="screen-content">
      <div class="form-section">
        <div class="form-section-title">Contraseña actual</div>
        <div class="form-group">
          <div class="form-row">
            <input type="password" id="currentPass" placeholder="Ingresa tu contraseña actual" style="text-align:left">
          </div>
        </div>
      </div>
      <div class="form-section">
        <div class="form-section-title">Nueva contraseña</div>
        <div class="form-group">
          <div class="form-row">
            <input type="password" id="newPass" placeholder="Mínimo 6 caracteres" style="text-align:left">
          </div>
          <div class="form-row">
            <input type="password" id="confirmPass" placeholder="Confirmar nueva contraseña" style="text-align:left">
          </div>
        </div>
      </div>
      <div id="changePassError" class="error-message" style="display:none"></div>
    </div>
  `;
}

async function handleChangePassword() {
  const current = document.getElementById('currentPass').value;
  const newPass = document.getElementById('newPass').value;
  const confirm = document.getElementById('confirmPass').value;
  const errorEl = document.getElementById('changePassError');

  if (!current || !newPass) { errorEl.textContent = 'Llena todos los campos'; errorEl.style.display = 'block'; return; }
  if (newPass !== confirm) { errorEl.textContent = 'Las contraseñas no coinciden'; errorEl.style.display = 'block'; return; }

  try {
    await apiFetch('/auth/cambiar-password', {
      method: 'PUT',
      body: { password_actual: current, password_nueva: newPass }
    });
    showToast('Contraseña actualizada');
    showScreen('profile');
  } catch (err) {
    errorEl.textContent = err.message;
    errorEl.style.display = 'block';
  }
}

function handleLogout() {
  removeToken();
  currentUser = null;
  showScreen('login');
}

async function renderUsers() {
  const screen = document.getElementById('screen-users');
  screen.innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('admin')">← Atrás</button>
      <div class="toolbar-title">Usuarios</div>
      <button class="toolbar-btn" onclick="showNewUserModal()">
        <span class="material-icons-outlined" style="font-size:24px">add</span>
      </button>
    </div>
    <div class="loading-spinner"><div class="spinner"></div></div>
  `;

  try {
    empresaUsuarios = await apiFetch('/usuarios');
    const content = empresaUsuarios.length === 0 ? `
      <div class="empty-state">
        <span class="material-icons-outlined">people</span>
        <div class="headline">Sin usuarios</div>
        <div class="subheadline">Agrega usuarios con el botón +</div>
      </div>
    ` : empresaUsuarios.map(u => `
      <div class="card" onclick="showScreen('user-detail', ${JSON.stringify(u).replace(/"/g, '&quot;')})">
        <div class="card-content">
          <div class="card-title">
            ${u.nombre}
            ${u.es_root ? '<span class="badge badge-blue">Root</span>' : ''}
            ${!u.activo ? '<span class="badge badge-red">Inactivo</span>' : ''}
            ${!u.aprobado ? '<span class="badge badge-yellow">Pendiente</span>' : ''}
          </div>
          <div class="card-subtitle">${u.email}${u.rol_nombre ? ` · ${u.rol_nombre}` : ''}${u.empresa_nombre ? ` · ${u.empresa_nombre}` : ''}</div>
        </div>
        <span class="material-icons-outlined card-chevron">chevron_right</span>
      </div>
    `).join('');

    screen.innerHTML = `
      <div class="toolbar">
        <button class="toolbar-btn" onclick="showScreen('admin')">← Atrás</button>
        <div class="toolbar-title">Usuarios (${empresaUsuarios.length})</div>
        <button class="toolbar-btn" onclick="showNewUserModal()">
          <span class="material-icons-outlined" style="font-size:24px">add</span>
        </button>
      </div>
      <div class="screen-content">${content}</div>
    `;
  } catch (err) {
    showToast(err.message);
  }
}

function renderUserDetail(user) {
  const u = typeof user === 'string' ? JSON.parse(user) : user;

  document.getElementById('screen-user-detail').innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('users')">← Atrás</button>
      <div class="toolbar-title">Detalle de Usuario</div>
      <div style="width:50px"></div>
    </div>
    <div class="screen-content">
      <div style="text-align:center; padding:16px 0">
        <span class="material-icons-outlined" style="font-size:64px;color:var(--accent)">person</span>
        <div class="title3" style="margin-top:8px">${u.nombre}</div>
        <div class="subheadline">${u.email}</div>
      </div>

      <div class="form-section">
        <div class="form-section-title">Estado</div>
        <div class="form-group">
          <div class="form-row">
            <label>Activo</label>
            <span class="badge ${u.activo ? 'badge-green' : 'badge-red'}">${u.activo ? 'Sí' : 'No'}</span>
          </div>
          <div class="form-row">
            <label>Aprobado</label>
            <span class="badge ${u.aprobado ? 'badge-green' : 'badge-yellow'}">${u.aprobado ? 'Sí' : 'Pendiente'}</span>
          </div>
          <div class="form-row">
            <label>Rol</label>
            <span style="color:var(--text-secondary)">${u.rol_nombre || 'Sin rol'}</span>
          </div>
        </div>
      </div>

      ${!u.es_root ? `
      <div class="form-section">
        <div class="form-section-title">Acciones</div>
        <div class="form-group">
          ${!u.aprobado ? `
            <div class="form-row">
              <label>Aprobar usuario</label>
              <button class="action-btn success" onclick="aprobarUsuario('${u.id}')">Aprobar</button>
            </div>
          ` : ''}
          <div class="form-row">
            <label>${u.activo ? 'Desactivar' : 'Activar'}</label>
            <button class="action-btn ${u.activo ? 'danger' : 'success'}" onclick="toggleActivoUsuario('${u.id}')">${u.activo ? 'Desactivar' : 'Activar'}</button>
          </div>
          <div class="form-row">
            <label>Asignar Rol</label>
            <select id="rolSelect-${u.id}" onchange="asignarRol('${u.id}', this.value)" style="text-align:right;cursor:pointer">
              <option value="">Sin rol</option>
            </select>
          </div>
        </div>
      </div>
      ` : ''}
    </div>
  `;

  if (!u.es_root) loadRolesForSelect(u);
}

async function loadRolesForSelect(user) {
  try {
    const empresaId = currentUser.es_root ? user.empresa_id : currentUser.empresa_id;
    if (!empresaId) return;
    const roles = await apiFetch(`/roles?empresa_id=${empresaId}`);
    const select = document.getElementById(`rolSelect-${user.id}`);
    if (!select) return;
    roles.forEach(r => {
      const opt = document.createElement('option');
      opt.value = r.id;
      opt.textContent = r.nombre;
      if (user.rol_id === r.id) opt.selected = true;
      select.appendChild(opt);
    });
  } catch {}
}

async function aprobarUsuario(id) {
  try {
    await apiFetch(`/usuarios/${id}/aprobar`, { method: 'PUT' });
    showToast('Usuario aprobado');
    showScreen('users');
  } catch (err) { showToast(err.message); }
}

async function toggleActivoUsuario(id) {
  try {
    const data = await apiFetch(`/usuarios/${id}/toggle-activo`, { method: 'PUT' });
    showToast(data.message);
    showScreen('users');
  } catch (err) { showToast(err.message); }
}

async function asignarRol(userId, rolId) {
  try {
    await apiFetch(`/usuarios/${userId}/asignar-rol`, { method: 'PUT', body: { rol_id: rolId || null } });
    showToast('Rol asignado');
  } catch (err) { showToast(err.message); }
}

function showNewUserModal() {
  const container = document.getElementById('modal-container');
  container.innerHTML = `
    <div class="modal-overlay" onclick="if(event.target===this)closeModal()">
      <div class="modal-sheet">
        <div class="toolbar">
          <button class="toolbar-btn" onclick="closeModal()">Cancelar</button>
          <div class="toolbar-title">Nuevo Usuario</div>
          <button class="toolbar-btn semibold" onclick="handleCreateUser()">Guardar</button>
        </div>
        <div class="screen-content">
          <div class="form-section">
            <div class="form-section-title">Datos</div>
            <div class="form-group">
              <div class="form-row">
                <label>Nombre</label>
                <input type="text" id="newUserNombre" placeholder="Nombre completo">
              </div>
              <div class="form-row">
                <label>Email</label>
                <input type="email" id="newUserEmail" placeholder="correo@ejemplo.com">
              </div>
              <div class="form-row">
                <label>Contraseña</label>
                <input type="password" id="newUserPassword" placeholder="Mínimo 6 caracteres">
              </div>
            </div>
          </div>
          <div id="newUserError" class="error-message" style="display:none"></div>
        </div>
      </div>
    </div>
  `;
}

async function handleCreateUser() {
  const nombre = document.getElementById('newUserNombre').value;
  const email = document.getElementById('newUserEmail').value;
  const password = document.getElementById('newUserPassword').value;
  const errorEl = document.getElementById('newUserError');

  if (!nombre || !email || !password) { errorEl.textContent = 'Todos los campos son requeridos'; errorEl.style.display = 'block'; return; }

  try {
    await apiFetch('/usuarios', { method: 'POST', body: { nombre, email, password } });
    closeModal();
    showToast('Usuario creado');
    showScreen('users');
  } catch (err) {
    errorEl.textContent = err.message;
    errorEl.style.display = 'block';
  }
}

function closeModal() {
  document.getElementById('modal-container').innerHTML = '';
}

async function renderRoles() {
  const screen = document.getElementById('screen-roles');
  screen.innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('admin')">← Atrás</button>
      <div class="toolbar-title">Roles</div>
      <button class="toolbar-btn" onclick="showScreen('role-form', null)">
        <span class="material-icons-outlined" style="font-size:24px">add</span>
      </button>
    </div>
    <div class="loading-spinner"><div class="spinner"></div></div>
  `;

  try {
    const empresaId = currentUser.es_root ? (currentUser.empresa_id || '') : currentUser.empresa_id;
    empresaRoles = await apiFetch(`/roles?empresa_id=${empresaId}`);
    allPermisos = await apiFetch('/roles/permisos');

    const content = empresaRoles.length === 0 ? `
      <div class="empty-state">
        <span class="material-icons-outlined">admin_panel_settings</span>
        <div class="headline">Sin roles</div>
        <div class="subheadline">Crea roles para asignar permisos a tus usuarios</div>
      </div>
    ` : empresaRoles.map(r => `
      <div class="card" onclick='showScreen("role-form", ${JSON.stringify(r).replace(/'/g, "\\'")})'>
        <div class="card-content">
          <div class="card-title">${r.nombre}</div>
          <div class="card-subtitle">${r.permisos.length} permisos · ${r.num_usuarios || 0} usuarios</div>
        </div>
        <span class="material-icons-outlined card-chevron">chevron_right</span>
      </div>
    `).join('');

    screen.innerHTML = `
      <div class="toolbar">
        <button class="toolbar-btn" onclick="showScreen('admin')">← Atrás</button>
        <div class="toolbar-title">Roles (${empresaRoles.length})</div>
        <button class="toolbar-btn" onclick="showScreen('role-form', null)">
          <span class="material-icons-outlined" style="font-size:24px">add</span>
        </button>
      </div>
      <div class="screen-content">${content}</div>
    `;
  } catch (err) {
    showToast(err.message);
  }
}

async function renderRoleForm(rol) {
  if (allPermisos.length === 0) {
    allPermisos = await apiFetch('/roles/permisos');
  }

  const isEdit = rol && rol.id;
  const selectedPermisos = isEdit ? rol.permisos.map(p => p.id) : [];

  const categorias = {};
  allPermisos.forEach(p => {
    if (!categorias[p.categoria]) categorias[p.categoria] = [];
    categorias[p.categoria].push(p);
  });

  document.getElementById('screen-role-form').innerHTML = `
    <div class="toolbar">
      <button class="toolbar-btn" onclick="showScreen('roles')">Cancelar</button>
      <div class="toolbar-title">${isEdit ? 'Editar Rol' : 'Nuevo Rol'}</div>
      <button class="toolbar-btn semibold" onclick="handleSaveRole('${isEdit ? rol.id : ''}')">Guardar</button>
    </div>
    <div class="screen-content">
      <div class="form-section">
        <div class="form-section-title">Información</div>
        <div class="form-group">
          <div class="form-row">
            <label>Nombre</label>
            <input type="text" id="rolNombre" value="${isEdit ? rol.nombre : ''}" placeholder="Ej: Vendedor">
          </div>
          <div class="form-row">
            <label>Descripción</label>
            <input type="text" id="rolDescripcion" value="${isEdit ? (rol.descripcion || '') : ''}" placeholder="Opcional">
          </div>
        </div>
      </div>

      <div class="form-section">
        <div class="form-section-title">Permisos</div>
        <div class="permission-grid">
          ${Object.entries(categorias).map(([cat, perms]) => `
            <div class="permission-category">
              <div class="permission-category-title">${cat}</div>
              <div class="permission-items">
                ${perms.map(p => `
                  <div class="permission-item">
                    <label for="perm-${p.id}">${p.nombre}</label>
                    <input type="checkbox" class="checkbox perm-check" id="perm-${p.id}" value="${p.id}" ${selectedPermisos.includes(p.id) ? 'checked' : ''}>
                  </div>
                `).join('')}
              </div>
            </div>
          `).join('')}
        </div>
      </div>

      ${isEdit ? `
        <button class="btn-danger" onclick="handleDeleteRole('${rol.id}')" style="margin-top:16px">
          Eliminar Rol
        </button>
      ` : ''}
    </div>
  `;
}

async function handleSaveRole(roleId) {
  const nombre = document.getElementById('rolNombre').value;
  const descripcion = document.getElementById('rolDescripcion').value;
  const permisos = [...document.querySelectorAll('.perm-check:checked')].map(c => c.value);

  if (!nombre) { showToast('El nombre del rol es requerido'); return; }

  try {
    if (roleId) {
      await apiFetch(`/roles/${roleId}`, { method: 'PUT', body: { nombre, descripcion, permisos } });
      showToast('Rol actualizado');
    } else {
      await apiFetch('/roles', { method: 'POST', body: { nombre, descripcion, permisos } });
      showToast('Rol creado');
    }
    showScreen('roles');
  } catch (err) { showToast(err.message); }
}

async function handleDeleteRole(roleId) {
  if (!confirm('¿Estás seguro de eliminar este rol?')) return;
  try {
    await apiFetch(`/roles/${roleId}`, { method: 'DELETE' });
    showToast('Rol eliminado');
    showScreen('roles');
  } catch (err) { showToast(err.message); }
}

document.addEventListener('DOMContentLoaded', init);
