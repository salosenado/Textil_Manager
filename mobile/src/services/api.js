import AsyncStorage from '@react-native-async-storage/async-storage';
import { Platform } from 'react-native';
import Constants from 'expo-constants';

function getApiUrl() {
  const configured = Constants.expoConfig?.extra?.apiUrl;
  if (configured) return configured + '/api';
  if (Platform.OS === 'web' && typeof window !== 'undefined') {
    return 'https://4098a82a-8af8-4fd7-b3b7-1bfe9f61eb41-00-2zywlsll98xbx.picard.replit.dev/api';
  }
  return 'http://localhost:5000/api';
}

const API_URL = getApiUrl();

async function getToken() {
  return await AsyncStorage.getItem('token');
}

async function request(endpoint, options = {}) {
  const token = await getToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers,
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || 'Error del servidor');
  }

  return data;
}

export const api = {
  login: (email, password) =>
    request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  getMe: () => request('/auth/me'),

  changePassword: (currentPassword, newPassword) =>
    request('/auth/cambiar-password', {
      method: 'PUT',
      body: JSON.stringify({ password_actual: currentPassword, password_nueva: newPassword }),
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
};
