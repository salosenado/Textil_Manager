import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [permisos, setPermisos] = useState([]);
  const [empresaActiva, setEmpresaActivaState] = useState(null);

  useEffect(() => {
    checkAuth();
  }, []);

  async function checkAuth() {
    try {
      const token = await AsyncStorage.getItem('token');
      if (token) {
        const data = await api.getMe();
        const userData = data.user || data;
        setUser(userData);
        setPermisos(data.permisos || userData.permisos || []);

        if (userData.es_root) {
          const saved = await AsyncStorage.getItem('empresaActiva');
          if (saved) {
            try {
              const parsed = JSON.parse(saved);
              setEmpresaActivaState(parsed);
              api.setEmpresaActiva(parsed.id);
            } catch (e) {}
          }
        }
      }
    } catch (err) {
      await AsyncStorage.removeItem('token');
    } finally {
      setLoading(false);
    }
  }

  async function login(email, password) {
    const data = await api.login(email, password);
    await AsyncStorage.setItem('token', data.token);
    const userData = data.user || data;
    setUser(userData);
    setPermisos(userData.permisos || []);
    if (!userData.es_root) {
      setEmpresaActivaState(null);
      await AsyncStorage.removeItem('empresaActiva');
      api.setEmpresaActiva(null);
    }
    return data;
  }

  async function register(nombre, email, password) {
    const data = await api.registro(nombre, email, password);
    await AsyncStorage.setItem('token', data.token);
    const userData = data.user || data;
    setUser(userData);
    setPermisos(userData.permisos || []);
    setEmpresaActivaState(null);
    await AsyncStorage.removeItem('empresaActiva');
    api.setEmpresaActiva(null);
    return data;
  }

  async function logout() {
    await AsyncStorage.removeItem('token');
    await AsyncStorage.removeItem('empresaActiva');
    setUser(null);
    setPermisos([]);
    setEmpresaActivaState(null);
    api.setEmpresaActiva(null);
  }

  function tienePermiso(permiso) {
    if (!user) return false;
    if (user.es_root) return true;
    return permisos.includes(permiso);
  }

  async function refreshUser() {
    try {
      const data = await api.getMe();
      const userData = data.user || data;
      setUser(userData);
      setPermisos(data.permisos || userData.permisos || []);
    } catch (err) {
    }
  }

  async function setEmpresaActiva(empresa) {
    setEmpresaActivaState(empresa);
    if (empresa) {
      await AsyncStorage.setItem('empresaActiva', JSON.stringify(empresa));
      api.setEmpresaActiva(empresa.id);
    } else {
      await AsyncStorage.removeItem('empresaActiva');
      api.setEmpresaActiva(null);
    }
  }

  return (
    <AuthContext.Provider value={{
      user,
      permisos,
      loading,
      login,
      register,
      logout,
      tienePermiso,
      refreshUser,
      empresaActiva,
      setEmpresaActiva,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
