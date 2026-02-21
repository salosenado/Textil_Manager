import AsyncStorage from '@react-native-async-storage/async-storage';
import Constants from 'expo-constants';

const API_URL = (Constants.expoConfig?.extra?.apiUrl || 'http://localhost:5000') + '/api';

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

  asignarEmpresa: (userId, empresaId) =>
    request(`/usuarios/${userId}/asignar-empresa`, {
      method: 'PUT',
      body: JSON.stringify({ empresa_id: empresaId }),
    }),
};
