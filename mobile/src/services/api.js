import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import Constants from 'expo-constants';

function getApiUrl() {
  const configured = Constants.expoConfig?.extra?.apiUrl;
  if (configured) {
    return configured + '/api';
  }
  if (Platform.OS === 'web' && typeof window !== 'undefined') {
    const origin = window.location.origin;
    if (origin.includes(':8080')) {
      return origin.replace(':8080', ':5000') + '/api';
    }
    return origin + '/api';
  }
  return 'http://localhost:5000/api';
}

const API_URL = getApiUrl();

let _empresaActivaId = null;

async function getToken() {
  return await AsyncStorage.getItem('token');
}

async function request(endpoint, options = {}) {
  const token = await getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    ...(_empresaActivaId ? { 'X-Empresa-Id': _empresaActivaId } : {}),
    ...options.headers,
  };

  let response;
  try {
    response = await fetch(`${API_URL}${endpoint}`, {
      ...options,
      headers,
    });
  } catch (networkError) {
    throw new Error('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
  }

  let data;
  try {
    data = await response.json();
  } catch (parseError) {
    throw new Error('Error de comunicación con el servidor');
  }

  if (!response.ok) {
    throw new Error(data.error || 'Error del servidor');
  }

  return data;
}

export const api = {
  setEmpresaActiva: (id) => { _empresaActivaId = id; },

  login: (email, password) =>
    request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  registro: (nombre, email, password) =>
    request('/auth/registro', {
      method: 'POST',
      body: JSON.stringify({ nombre, email, password }),
    }),

  recuperarPassword: (email) =>
    request('/auth/recuperar-password', {
      method: 'POST',
      body: JSON.stringify({ email }),
    }),

  getMe: () => request('/auth/me'),

  changePassword: (currentPassword, newPassword) =>
    request('/auth/cambiar-password', {
      method: 'PUT',
      body: JSON.stringify({ password_actual: currentPassword, password_nueva: newPassword }),
    }),

  deleteAccount: (password) =>
    request('/auth/eliminar-cuenta', {
      method: 'POST',
      body: JSON.stringify({ password }),
    }),

  getUsuarios: () => request('/usuarios'),

  createUsuario: (data) =>
    request('/usuarios', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  aprobarUsuario: (id) =>
    request(`/usuarios/${id}/aprobar`, { method: 'PUT' }),

  toggleActivoUsuario: (id) =>
    request(`/usuarios/${id}/toggle-activo`, { method: 'PUT' }),

  asignarRol: (id, rolId) =>
    request(`/usuarios/${id}/asignar-rol`, {
      method: 'PUT',
      body: JSON.stringify({ rol_id: rolId }),
    }),

  toggleRootUsuario: (id) =>
    request(`/usuarios/${id}/toggle-root`, { method: 'PUT' }),

  getRoles: () => request('/roles'),

  getPermisos: () => request('/roles/permisos'),

  createRol: (data) =>
    request('/roles', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateRol: (id, data) =>
    request(`/roles/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteRol: (id) =>
    request(`/roles/${id}`, { method: 'DELETE' }),

  getEmpresas: () => request('/empresas-admin'),

  getEmpresasStats: () => request('/empresas-admin/stats'),

  getEmpresa: (id) => request(`/empresas-admin/${id}`),

  createEmpresa: (data) =>
    request('/empresas-admin', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateEmpresa: (id, data) =>
    request(`/empresas-admin/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  toggleActivoEmpresa: (id) =>
    request(`/empresas-admin/${id}/toggle-activo`, { method: 'PUT' }),

  getEmpresaReportes: (id) => request(`/empresas-admin/${id}/reportes`),

  deleteEmpresa: (id) =>
    request(`/empresas-admin/${id}`, { method: 'DELETE' }),

  asignarEmpresa: (userId, empresaId) =>
    request(`/usuarios/${userId}/asignar-empresa`, {
      method: 'PUT',
      body: JSON.stringify({ empresa_id: empresaId }),
    }),

  getCatalogItems: (catalogo, search) => {
    const params = search ? `?search=${encodeURIComponent(search)}` : '';
    return request(`/catalogos/${catalogo}${params}`);
  },

  getCatalogItem: (catalogo, id) =>
    request(`/catalogos/${catalogo}/${id}`),

  createCatalogItem: (catalogo, data) =>
    request(`/catalogos/${catalogo}`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateCatalogItem: (catalogo, id, data) =>
    request(`/catalogos/${catalogo}/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteCatalogItem: (catalogo, id) =>
    request(`/catalogos/${catalogo}/${id}`, { method: 'DELETE' }),

  getTelaPrecios: (telaId) =>
    request(`/catalogos/telas/${telaId}/precios`),

  saveTelaPrecios: (telaId, precios) =>
    request(`/catalogos/telas/${telaId}/precios`, {
      method: 'POST',
      body: JSON.stringify({ precios }),
    }),

  getOrdenesCliente: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    if (params.periodo) query.append('periodo', params.periodo);
    const qs = query.toString();
    return request(`/ordenes-cliente${qs ? '?' + qs : ''}`);
  },

  getOrdenCliente: (id) => request(`/ordenes-cliente/${id}`),

  createOrdenCliente: (data) =>
    request('/ordenes-cliente', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateOrdenCliente: (id, data) =>
    request(`/ordenes-cliente/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  cancelarOrdenCliente: (id) =>
    request(`/ordenes-cliente/${id}/cancelar`, { method: 'PUT' }),

  deleteOrdenCliente: (id) =>
    request(`/ordenes-cliente/${id}`, { method: 'DELETE' }),

  getOrdenesCompra: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    if (params.periodo) query.append('periodo', params.periodo);
    const qs = query.toString();
    return request(`/ordenes-compra${qs ? '?' + qs : ''}`);
  },

  getOrdenCompra: (id) => request(`/ordenes-compra/${id}`),

  createOrdenCompra: (data) =>
    request('/ordenes-compra', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateOrdenCompra: (id, data) =>
    request(`/ordenes-compra/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  cancelarOrdenCompra: (id) =>
    request(`/ordenes-compra/${id}/cancelar`, { method: 'PUT' }),

  deleteOrdenCompra: (id) =>
    request(`/ordenes-compra/${id}`, { method: 'DELETE' }),

  getComprasInsumo: (search, periodo) => {
    const params = new URLSearchParams();
    if (search) params.append('search', search);
    if (periodo) params.append('periodo', periodo);
    const qs = params.toString();
    return request(`/compras-insumo${qs ? '?' + qs : ''}`);
  },

  getCompraInsumo: (id) =>
    request(`/compras-insumo/${id}`),

  createCompraInsumo: (data) =>
    request('/compras-insumo', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateCompraInsumo: (id, data) =>
    request(`/compras-insumo/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteCompraInsumo: (id) =>
    request(`/compras-insumo/${id}`, { method: 'DELETE' }),

  getProducciones: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    const qs = query.toString();
    return request(`/producciones${qs ? '?' + qs : ''}`);
  },

  getProduccion: (id) => request(`/producciones/${id}`),

  createProduccion: (data) =>
    request('/producciones', { method: 'POST', body: JSON.stringify(data) }),

  updateProduccion: (id, data) =>
    request(`/producciones/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  cancelarProduccion: (id) =>
    request(`/producciones/${id}/cancelar`, { method: 'PUT' }),

  deleteProduccion: (id) =>
    request(`/producciones/${id}`, { method: 'DELETE' }),

  createReciboProduccion: (produccionId, data) =>
    request(`/producciones/${produccionId}/recibos`, { method: 'POST', body: JSON.stringify(data) }),

  deleteReciboProduccion: (reciboId) =>
    request(`/producciones/recibos/${reciboId}`, { method: 'DELETE' }),

  createPagoRecibo: (reciboId, data) =>
    request(`/producciones/recibos/${reciboId}/pagos`, { method: 'POST', body: JSON.stringify(data) }),

  deletePagoRecibo: (pagoId) =>
    request(`/producciones/pagos/${pagoId}`, { method: 'DELETE' }),

  getCostosGenerales: (search) => {
    const params = new URLSearchParams();
    if (search) params.append('search', search);
    const qs = params.toString();
    return request(`/costos/generales${qs ? '?' + qs : ''}`);
  },

  getCostoGeneral: (id) => request(`/costos/generales/${id}`),

  createCostoGeneral: (data) =>
    request('/costos/generales', { method: 'POST', body: JSON.stringify(data) }),

  updateCostoGeneral: (id, data) =>
    request(`/costos/generales/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  deleteCostoGeneral: (id) =>
    request(`/costos/generales/${id}`, { method: 'DELETE' }),

  getCostosMezclilla: (search) => {
    const params = new URLSearchParams();
    if (search) params.append('search', search);
    const qs = params.toString();
    return request(`/costos/mezclilla${qs ? '?' + qs : ''}`);
  },

  getCostoMezclilla: (id) => request(`/costos/mezclilla/${id}`),

  createCostoMezclilla: (data) =>
    request('/costos/mezclilla', { method: 'POST', body: JSON.stringify(data) }),

  updateCostoMezclilla: (id, data) =>
    request(`/costos/mezclilla/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  deleteCostoMezclilla: (id) =>
    request(`/costos/mezclilla/${id}`, { method: 'DELETE' }),

  getSalidasInsumo: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    const qs = query.toString();
    return request(`/salidas${qs ? '?' + qs : ''}`);
  },

  getSalidaInsumo: (id) => request(`/salidas/${id}`),

  createSalidaInsumo: (data) =>
    request('/salidas', { method: 'POST', body: JSON.stringify(data) }),

  updateSalidaInsumo: (id, data) =>
    request(`/salidas/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  cancelarSalidaInsumo: (id) =>
    request(`/salidas/${id}/cancelar`, { method: 'PUT' }),

  deleteSalidaInsumo: (id) =>
    request(`/salidas/${id}`, { method: 'DELETE' }),

  getReingresos: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    const qs = query.toString();
    return request(`/reingresos${qs ? '?' + qs : ''}`);
  },

  getReingreso: (id) => request(`/reingresos/${id}`),

  createReingreso: (data) =>
    request('/reingresos', { method: 'POST', body: JSON.stringify(data) }),

  updateReingreso: (id, data) =>
    request(`/reingresos/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  cancelarReingreso: (id) =>
    request(`/reingresos/${id}/cancelar`, { method: 'PUT' }),

  deleteReingreso: (id) =>
    request(`/reingresos/${id}`, { method: 'DELETE' }),

  getVentasCliente: (params = {}) => {
    const query = new URLSearchParams();
    if (params.search) query.append('search', params.search);
    if (params.estado) query.append('estado', params.estado);
    const qs = query.toString();
    return request(`/ventas${qs ? '?' + qs : ''}`);
  },

  getVentaCliente: (id) => request(`/ventas/${id}`),

  createVentaCliente: (data) =>
    request('/ventas', { method: 'POST', body: JSON.stringify(data) }),

  updateVentaCliente: (id, data) =>
    request(`/ventas/${id}`, { method: 'PUT', body: JSON.stringify(data) }),

  cancelarVentaCliente: (id) =>
    request(`/ventas/${id}/cancelar`, { method: 'PUT' }),

  enviarVentaCliente: (id) =>
    request(`/ventas/${id}/enviar`, { method: 'PUT' }),

  deleteVentaCliente: (id) =>
    request(`/ventas/${id}`, { method: 'DELETE' }),

  createCobroVenta: (ventaId, data) =>
    request(`/ventas/${ventaId}/cobros`, { method: 'POST', body: JSON.stringify(data) }),

  deleteCobroVenta: (ventaId, cobroId) =>
    request(`/ventas/${ventaId}/cobros/${cobroId}`, { method: 'DELETE' }),
};
