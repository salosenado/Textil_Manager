import React, { useState, useEffect, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Alert, RefreshControl } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

export default function RolesScreen({ navigation }) {
  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadRoles = useCallback(async () => {
    try {
      const data = await api.getRoles();
      setRoles(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => { loadRoles(); }, [loadRoles]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', loadRoles);
    return unsubscribe;
  }, [navigation, loadRoles]);

  async function handleDelete(rol) {
    Alert.alert(
      'Eliminar Rol',
      `¿Estás seguro de eliminar "${rol.nombre}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteRol(rol.id);
              loadRoles();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  }

  function renderRol({ item }) {
    const permCount = item.permisos?.length || 0;

    return (
      <TouchableOpacity
        style={styles.rolCard}
        activeOpacity={0.7}
        onPress={() => navigation.navigate('RolForm', { rol: item, onRefresh: loadRoles })}
      >
        <View style={styles.rolRow}>
          <View style={styles.rolIcon}>
            <Ionicons name="shield-outline" size={24} color={Colors.primary} />
          </View>
          <View style={styles.rolInfo}>
            <Text style={styles.rolName}>{item.nombre}</Text>
            {item.descripcion && (
              <Text style={styles.rolDesc} numberOfLines={1}>{item.descripcion}</Text>
            )}
            <Text style={styles.rolPerms}>{permCount} permiso{permCount !== 1 ? 's' : ''}</Text>
          </View>
          <TouchableOpacity onPress={() => handleDelete(item)} style={styles.deleteBtn}>
            <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
          </TouchableOpacity>
        </View>
      </TouchableOpacity>
    );
  }

  return (
    <View style={styles.container}>
      <FlatList
        data={roles}
        keyExtractor={item => item.id}
        renderItem={renderRol}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadRoles(); }} />
        }
        ListEmptyComponent={
          !loading && (
            <View style={styles.empty}>
              <Ionicons name="shield-outline" size={48} color={Colors.textTertiary} />
              <Text style={styles.emptyText}>No hay roles creados</Text>
            </View>
          )
        }
      />
      <TouchableOpacity
        style={styles.fab}
        onPress={() => navigation.navigate('RolForm', { onRefresh: loadRoles })}
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
  rolCard: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
    marginBottom: Spacing.md,
  },
  rolRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  rolIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.primary + '15',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  rolInfo: {
    flex: 1,
  },
  rolName: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
  },
  rolDesc: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  rolPerms: {
    fontSize: FontSize.xs,
    color: Colors.primary,
    marginTop: 2,
    fontWeight: '500',
  },
  deleteBtn: {
    padding: Spacing.sm,
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
