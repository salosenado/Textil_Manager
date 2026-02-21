import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import Card from '../components/Card';
import Button from '../components/Button';
import ListRow from '../components/ListRow';
import SectionHeader from '../components/SectionHeader';

export default function UsuarioDetalleScreen({ route, navigation }) {
  const { usuario, onRefresh } = route.params;
  const { user: currentUser } = useAuth();
  const [roles, setRoles] = useState([]);
  const [selectedRol, setSelectedRol] = useState(usuario.rol_id);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadRoles();
  }, []);

  async function loadRoles() {
    try {
      const data = await api.getRoles();
      setRoles(data);
    } catch (err) {
      // ignore
    }
  }

  async function handleToggleActivo() {
    if (usuario.id === currentUser?.id) {
      Alert.alert('Error', 'No puedes desactivarte a ti mismo');
      return;
    }
    try {
      setLoading(true);
      await api.toggleActivoUsuario(usuario.id);
      if (onRefresh) onRefresh();
      navigation.goBack();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleAprobar() {
    try {
      setLoading(true);
      await api.aprobarUsuario(usuario.id);
      if (onRefresh) onRefresh();
      navigation.goBack();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleAsignarRol(rolId) {
    try {
      await api.asignarRol(usuario.id, rolId);
      setSelectedRol(rolId);
      Alert.alert('Listo', 'Rol asignado correctamente');
      if (onRefresh) onRefresh();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  const isCurrentUser = usuario.id === currentUser?.id;

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={[styles.avatar, !usuario.activo && styles.avatarInactive]}>
          <Text style={styles.avatarText}>
            {usuario.nombre?.charAt(0)?.toUpperCase() || '?'}
          </Text>
        </View>
        <Text style={styles.name}>{usuario.nombre}</Text>
        <Text style={styles.email}>{usuario.email}</Text>
        <View style={styles.badges}>
          <View style={[styles.badge, { backgroundColor: usuario.activo ? Colors.success : Colors.destructive }]}>
            <Text style={styles.badgeText}>{usuario.activo ? 'Activo' : 'Inactivo'}</Text>
          </View>
          {!usuario.aprobado && (
            <View style={[styles.badge, { backgroundColor: Colors.warning }]}>
              <Text style={styles.badgeText}>Pendiente</Text>
            </View>
          )}
        </View>
      </View>

      <SectionHeader title="Información" />
      <Card>
        <ListRow title="Correo" rightText={usuario.email} showChevron={false} />
        <View style={styles.separator} />
        <ListRow title="Empresa" rightText={usuario.empresa_nombre || 'Root'} showChevron={false} />
        <View style={styles.separator} />
        <ListRow title="Rol" rightText={usuario.rol_nombre || 'Sin rol'} showChevron={false} />
      </Card>

      {!isCurrentUser && (
        <>
          <SectionHeader title="Asignar Rol" />
          <Card style={styles.rolesCard}>
            {roles.map(rol => (
              <ListRow
                key={rol.id}
                title={rol.nombre}
                subtitle={rol.descripcion}
                icon={selectedRol === rol.id ? 'checkmark-circle' : 'ellipse-outline'}
                iconColor={selectedRol === rol.id ? Colors.primary : Colors.textTertiary}
                onPress={() => handleAsignarRol(rol.id)}
                showChevron={false}
              />
            ))}
            {roles.length === 0 && (
              <Text style={styles.noRoles}>No hay roles disponibles</Text>
            )}
          </Card>

          <SectionHeader title="Acciones" />
          <View style={styles.actions}>
            {!usuario.aprobado && (
              <Button
                title="Aprobar Usuario"
                onPress={handleAprobar}
                loading={loading}
                style={styles.actionBtn}
              />
            )}
            <Button
              title={usuario.activo ? 'Desactivar Usuario' : 'Activar Usuario'}
              onPress={handleToggleActivo}
              variant={usuario.activo ? 'destructive' : 'primary'}
              loading={loading}
              style={styles.actionBtn}
            />
          </View>
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    alignItems: 'center',
    paddingVertical: Spacing.xxl,
  },
  avatar: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.md,
  },
  avatarInactive: {
    backgroundColor: Colors.textTertiary,
  },
  avatarText: {
    color: Colors.white,
    fontSize: FontSize.title,
    fontWeight: '700',
  },
  name: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
  },
  email: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  badges: {
    flexDirection: 'row',
    gap: 8,
    marginTop: Spacing.md,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 10,
  },
  badgeText: {
    color: Colors.white,
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
  separator: {
    height: 1,
    backgroundColor: Colors.separator,
    marginLeft: Spacing.lg,
  },
  rolesCard: {
    paddingVertical: Spacing.sm,
    paddingHorizontal: 0,
  },
  noRoles: {
    textAlign: 'center',
    color: Colors.textSecondary,
    padding: Spacing.lg,
  },
  actions: {
    padding: Spacing.lg,
    gap: Spacing.md,
  },
  actionBtn: {
    marginBottom: 0,
  },
});
