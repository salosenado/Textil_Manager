import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert, RefreshControl } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';

export default function UsuariosScreen({ navigation }) {
  const { user: currentUser } = useAuth();
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadUsuarios = useCallback(async () => {
    try {
      const data = await api.getUsuarios();
      setUsuarios(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadUsuarios();
  }, [loadUsuarios]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', loadUsuarios);
    return unsubscribe;
  }, [navigation, loadUsuarios]);

  async function handleAprobar(id) {
    try {
      await api.aprobarUsuario(id);
      loadUsuarios();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  }

  async function handleToggleActivo(id, nombre) {
    Alert.alert(
      'Confirmar',
      `¿Cambiar estado de ${nombre}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Confirmar',
          onPress: async () => {
            try {
              await api.toggleActivoUsuario(id);
              loadUsuarios();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  }

  function renderUsuario({ item }) {
    const isCurrentUser = item.id === currentUser?.id;

    return (
      <TouchableOpacity
        style={styles.userCard}
        activeOpacity={0.7}
        onPress={() => navigation.navigate('UsuarioDetalle', { usuario: item, onRefresh: loadUsuarios })}
      >
        <View style={styles.userRow}>
          <View style={[styles.avatar, !item.activo && styles.avatarInactive]}>
            <Text style={styles.avatarText}>
              {item.nombre?.charAt(0)?.toUpperCase() || '?'}
            </Text>
          </View>
          <View style={styles.userInfo}>
            <View style={styles.nameRow}>
              <Text style={styles.userName} numberOfLines={1}>{item.nombre}</Text>
              {item.es_root && (
                <View style={styles.rootBadge}>
                  <Text style={styles.badgeText}>Root</Text>
                </View>
              )}
            </View>
            <Text style={styles.userEmail} numberOfLines={1}>{item.email}</Text>
            {item.rol_nombre && (
              <Text style={styles.userRole}>{item.rol_nombre}</Text>
            )}
          </View>
          <View style={styles.statusCol}>
            {!item.aprobado && (
              <TouchableOpacity style={styles.approveBtn} onPress={() => handleAprobar(item.id)}>
                <Text style={styles.approveBtnText}>Aprobar</Text>
              </TouchableOpacity>
            )}
            <View style={[styles.statusDot, { backgroundColor: item.activo ? Colors.success : Colors.destructive }]} />
          </View>
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={usuarios}
        keyExtractor={item => item.id}
        renderItem={renderUsuario}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadUsuarios(); }} />
        }
        ListEmptyComponent={
          !loading && (
            <View style={styles.empty}>
              <Ionicons name="people-outline" size={48} color={Colors.textTertiary} />
              <Text style={styles.emptyText}>No hay usuarios</Text>
            </View>
          )
        }
      />
      <TouchableOpacity
        style={styles.fab}
        onPress={() => navigation.navigate('CrearUsuario', { onRefresh: loadUsuarios })}
      >
        <Ionicons name="add" size={28} color={Colors.white} />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  list: {
    padding: Spacing.lg,
  },
  userCard: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
  },
  userRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  avatarInactive: {
    backgroundColor: Colors.textTertiary,
  },
  avatarText: {
    color: Colors.white,
    fontSize: FontSize.lg,
    fontWeight: '600',
  },
  userInfo: {
    flex: 1,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  userName: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
  },
  rootBadge: {
    backgroundColor: Colors.primary,
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  badgeText: {
    color: Colors.white,
    fontSize: 10,
    fontWeight: '700',
  },
  userEmail: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  userRole: {
    fontSize: FontSize.xs,
    color: Colors.primary,
    marginTop: 2,
    fontWeight: '500',
  },
  statusCol: {
    alignItems: 'flex-end',
    gap: 6,
  },
  approveBtn: {
    backgroundColor: Colors.success,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
  },
  approveBtnText: {
    color: Colors.white,
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  empty: {
    alignItems: 'center',
    paddingTop: 80,
  },
  emptyText: {
    fontSize: FontSize.lg,
    color: Colors.textTertiary,
    marginTop: Spacing.md,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
});
