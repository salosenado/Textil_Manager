import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, ActivityIndicator, Alert } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';
import { api } from '../services/api';
import Card from '../components/Card';
import Button from '../components/Button';

export default function AprobacionUsuariosScreen({ navigation }) {
  const [usuarios, setUsuarios] = useState([]);
  const [empresas, setEmpresas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    try {
      const [allUsers, allEmpresas] = await Promise.all([
        api.getUsuarios(),
        api.getEmpresas(),
      ]);
      setUsuarios(allUsers.filter(u => !u.aprobado && !u.es_root));
      setEmpresas(allEmpresas);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [])
  );

  const handleAprobar = async (usuario) => {
    if (!usuario.empresa_id) {
      const buttons = empresas.map(e => ({
        text: e.nombre,
        onPress: async () => {
          try {
            await api.asignarEmpresa(usuario.id, e.id);
            Alert.alert('Listo', `${usuario.nombre} aprobado y asignado a ${e.nombre}`);
            loadData();
          } catch (err) {
            Alert.alert('Error', err.message);
          }
        },
      }));
      buttons.push({ text: 'Cancelar', style: 'cancel' });

      Alert.alert(
        'Asignar empresa',
        `${usuario.nombre} no tiene empresa asignada. Selecciona una:`,
        buttons
      );
      return;
    }

    try {
      await api.aprobarUsuario(usuario.id);
      Alert.alert('Listo', `${usuario.nombre} aprobado`);
      loadData();
    } catch (err) {
      Alert.alert('Error', err.message);
    }
  };

  const handleRechazar = (usuario) => {
    Alert.alert(
      'Rechazar usuario',
      `¿Estás seguro de rechazar a ${usuario.nombre}? Se desactivará su cuenta.`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Rechazar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.toggleActivoUsuario(usuario.id);
              Alert.alert('Listo', `${usuario.nombre} rechazado`);
              loadData();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const renderItem = ({ item }) => (
    <Card style={styles.card}>
      <View style={styles.userInfo}>
        <View style={styles.avatar}>
          <Ionicons name="person" size={24} color={Colors.warning} />
        </View>
        <View style={styles.details}>
          <Text style={styles.nombre}>{item.nombre}</Text>
          <Text style={styles.email}>{item.email}</Text>
          {item.empresa_nombre ? (
            <Text style={styles.empresa}>Empresa: {item.empresa_nombre}</Text>
          ) : (
            <Text style={styles.sinEmpresa}>Sin empresa asignada</Text>
          )}
          <Text style={styles.fecha}>
            Registrado: {new Date(item.created_at).toLocaleDateString('es-MX')}
          </Text>
        </View>
      </View>
      <View style={styles.actions}>
        <Button
          title="Aprobar"
          onPress={() => handleAprobar(item)}
          style={styles.approveBtn}
        />
        <Button
          title="Rechazar"
          onPress={() => handleRechazar(item)}
          variant="destructive"
          style={styles.rejectBtn}
        />
      </View>
    </Card>
  );

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  if (usuarios.length === 0) {
    return (
      <View style={styles.centered}>
        <Ionicons name="checkmark-circle-outline" size={48} color={Colors.success} />
        <Text style={styles.emptyTitle}>Todo en orden</Text>
        <Text style={styles.emptyText}>No hay usuarios pendientes de aprobación</Text>
      </View>
    );
  }

  return (
    <FlatList
      style={styles.container}
      contentContainerStyle={styles.list}
      data={usuarios}
      keyExtractor={(item) => item.id}
      renderItem={renderItem}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadData(); }} />}
    />
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  list: {
    padding: Spacing.md,
    gap: Spacing.sm,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.background,
    paddingHorizontal: Spacing.lg,
  },
  card: {
    paddingVertical: Spacing.sm,
  },
  userInfo: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: Colors.warning + '20',
    justifyContent: 'center',
    alignItems: 'center',
  },
  details: {
    flex: 1,
  },
  nombre: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  email: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  empresa: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    marginTop: 2,
  },
  sinEmpresa: {
    fontSize: FontSize.caption,
    color: Colors.warning,
    marginTop: 2,
    fontStyle: 'italic',
  },
  fecha: {
    fontSize: FontSize.caption,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  actions: {
    flexDirection: 'row',
    gap: Spacing.sm,
    marginTop: Spacing.sm,
    paddingLeft: 60,
  },
  approveBtn: {
    flex: 1,
  },
  rejectBtn: {
    flex: 1,
  },
  emptyTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    marginTop: Spacing.md,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: 4,
  },
});
