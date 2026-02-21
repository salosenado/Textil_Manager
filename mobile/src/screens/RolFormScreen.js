import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Card from '../components/Card';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

const CATEGORIAS_PERMISOS = {
  'Catálogos': ['catalogos.ver', 'catalogos.editar'],
  'Órdenes': ['ordenes.ver', 'ordenes.editar'],
  'Compras': ['compras.ver', 'compras.editar'],
  'Producción': ['produccion.ver', 'produccion.editar'],
  'Ventas': ['ventas.ver', 'ventas.editar'],
  'Inventarios': ['inventarios.ver', 'inventarios.editar'],
  'Reingresos': ['reingresos.ver', 'reingresos.editar'],
  'Costos': ['costos.ver', 'costos.editar'],
  'Financiero': ['financiero.ver', 'financiero.editar'],
  'Servicios': ['servicios.ver', 'servicios.editar'],
  'Usuarios': ['usuarios.ver', 'usuarios.editar'],
  'Roles': ['roles.ver', 'roles.editar'],
  'Reportes': ['reportes.ver'],
};

export default function RolFormScreen({ route, navigation }) {
  const { rol, onRefresh } = route.params || {};
  const isEditing = !!rol;

  const [nombre, setNombre] = useState(rol?.nombre || '');
  const [descripcion, setDescripcion] = useState(rol?.descripcion || '');
  const [selectedPermisos, setSelectedPermisos] = useState([]);
  const [allPermisos, setAllPermisos] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadPermisos();
  }, []);

  async function loadPermisos() {
    try {
      const data = await api.getPermisos();
      setAllPermisos(data);
      if (rol?.permisos) {
        setSelectedPermisos(rol.permisos.map(p => p.id));
      }
    } catch (err) {
      // ignore
    }
  }

  function togglePermiso(permisoId) {
    setSelectedPermisos(prev =>
      prev.includes(permisoId)
        ? prev.filter(id => id !== permisoId)
        : [...prev, permisoId]
    );
  }

  function toggleCategoria(claves) {
    const permisoIds = allPermisos.filter(p => claves.includes(p.clave)).map(p => p.id);
    const allSelected = permisoIds.every(id => selectedPermisos.includes(id));
    if (allSelected) {
      setSelectedPermisos(prev => prev.filter(id => !permisoIds.includes(id)));
    } else {
      setSelectedPermisos(prev => [...new Set([...prev, ...permisoIds])]);
    }
  }

  async function handleSave() {
    if (!nombre.trim()) {
      Alert.alert('Error', 'El nombre del rol es requerido');
      return;
    }

    setLoading(true);
    try {
      const data = {
        nombre: nombre.trim(),
        descripcion: descripcion.trim() || null,
        permisos: selectedPermisos,
      };

      if (isEditing) {
        await api.updateRol(rol.id, data);
      } else {
        await api.createRol(data);
      }

      Alert.alert('Listo', isEditing ? 'Rol actualizado' : 'Rol creado');
      if (onRefresh) onRefresh();
      navigation.goBack();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      <SectionHeader title="Datos del rol" />
      <Card>
        <Input
          label="Nombre"
          value={nombre}
          onChangeText={setNombre}
          placeholder="Ej: Administrador, Vendedor"
        />
        <Input
          label="Descripción (opcional)"
          value={descripcion}
          onChangeText={setDescripcion}
          placeholder="Descripción del rol"
          multiline
        />
      </Card>

      <SectionHeader title={`Permisos (${selectedPermisos.length} seleccionados)`} />
      {Object.entries(CATEGORIAS_PERMISOS).map(([categoria, claves]) => {
        const permisosCategoria = allPermisos.filter(p => claves.includes(p.clave));
        if (permisosCategoria.length === 0) return null;

        const allSelected = permisosCategoria.every(p => selectedPermisos.includes(p.id));

        return (
          <Card key={categoria} style={styles.categoriaCard}>
            <TouchableOpacity style={styles.categoriaHeader} onPress={() => toggleCategoria(claves)}>
              <Ionicons
                name={allSelected ? 'checkbox' : 'square-outline'}
                size={22}
                color={allSelected ? Colors.primary : Colors.textTertiary}
              />
              <Text style={styles.categoriaTitle}>{categoria}</Text>
            </TouchableOpacity>
            {permisosCategoria.map(permiso => {
              const isSelected = selectedPermisos.includes(permiso.id);
              return (
                <TouchableOpacity
                  key={permiso.id}
                  style={styles.permisoRow}
                  onPress={() => togglePermiso(permiso.id)}
                >
                  <Ionicons
                    name={isSelected ? 'checkmark-circle' : 'ellipse-outline'}
                    size={22}
                    color={isSelected ? Colors.primary : Colors.textTertiary}
                  />
                  <View style={styles.permisoInfo}>
                    <Text style={styles.permisoNombre}>{permiso.nombre}</Text>
                    <Text style={styles.permisoClave}>{permiso.clave}</Text>
                  </View>
                </TouchableOpacity>
              );
            })}
          </Card>
        );
      })}

      <View style={styles.saveSection}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Rol'}
          onPress={handleSave}
          loading={loading}
        />
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  categoriaCard: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
  },
  categoriaHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    gap: Spacing.sm,
  },
  categoriaTitle: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
  },
  permisoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    paddingLeft: Spacing.xxl,
    gap: Spacing.sm,
  },
  permisoInfo: {
    flex: 1,
  },
  permisoNombre: {
    fontSize: FontSize.md,
    color: Colors.text,
  },
  permisoClave: {
    fontSize: FontSize.xs,
    color: Colors.textSecondary,
  },
  saveSection: {
    padding: Spacing.lg,
    paddingBottom: Spacing.xxxl,
  },
});
