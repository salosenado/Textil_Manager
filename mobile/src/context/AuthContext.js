import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api } from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [permisos, setPermisos] = useState([]);

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
    return data;
  }

  async function logout() {
    await AsyncStorage.removeItem('token');
    setUser(null);
    setPermisos([]);
  }

  function tienePermiso(permiso) {
    if (!user) return false;
    if (user.es_root) return true;
    return permisos.includes(permiso);
  }

  async function refreshUser() {
    try {
      const data = await api.getMe();
      setUser(data.user);
      setPermisos(data.permisos || []);
    } catch (err) {
      // ignore
    }
  }

  return (
    <AuthContext.Provider value={{
      user,
      permisos,
      loading,
      login,
      logout,
      tienePermiso,
      refreshUser,
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
