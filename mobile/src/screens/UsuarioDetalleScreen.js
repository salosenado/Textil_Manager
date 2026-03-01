import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Modal, TextInput, TouchableOpacity, FlatList, KeyboardAvoidingView, Platform } from 'react-native';
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
  const [empresas, setEmpresas] = useState([]);
  const [selectedRol, setSelectedRol] = useState(usuario.rol_id);
  const [selectedEmpresa, setSelectedEmpresa] = useState(usuario.empresa_id);
  const [loading, setLoading] = useState(false);
  const [empresaModalVisible, setEmpresaModalVisible] = useState(false);
  const [empresaSearch, setEmpresaSearch] = useState('');

  useEffect(() => {
    loadRoles();
    if (currentUser?.es_root) loadEmpresas();
  }, []);

  async function loadRoles() {
    try {
      const data = await api.getRoles();
      setRoles(data);
    } catch (err) {
      // ignore
    }
  }

  async function loadEmpresas() {
    try {
      const data = await api.getEmpresas();
      setEmpresas(data);
    } catch (err) {
      // ignore
    }
  }

  async function handleAsignarEmpresa(empresaId) {
    try {
      setLoading(true);
      await api.asignarEmpresa(usuario.id, empresaId);
      setSelectedEmpresa(empresaId);
      const empresaNombre = empresas.find(e => e.id === empresaId)?.nombre || 'Sin empresa';
      Alert.alert('Listo', `Empresa asignada: ${empresaNombre}`);
      if (onRefresh) onRefresh();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
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

  async function handleToggleRoot() {
    const action = usuario.es_root ? 'quitar acceso root a' : 'designar como root a';
    Alert.alert(
      'Confirmar',
      `¿${action} ${usuario.nombre}?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Confirmar',
          style: usuario.es_root ? 'destructive' : 'default',
          onPress: async () => {
            try {
              setLoading(true);
              const result = await api.toggleRootUsuario(usuario.id);
              Alert.alert('Listo', result.message);
              if (onRefresh) onRefresh();
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
            } finally {
              setLoading(false);
            }
          },
        },
      ]
    );
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
          {usuario.es_root && (
            <View style={[styles.badge, { backgroundColor: Colors.primary }]}>
              <Text style={styles.badgeText}>Root</Text>
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

      {!isCurrentUser && currentUser?.es_root && (
        <>
          <SectionHeader title="Empresa" />
          <Card>
            <TouchableOpacity
              style={styles.empresaSelector}
              onPress={() => { setEmpresaSearch(''); setEmpresaModalVisible(true); }}
            >
              <View style={styles.empresaSelectorLeft}>
                <Ionicons name="business-outline" size={20} color={Colors.primary} />
                <Text style={styles.empresaSelectorText}>
                  {selectedEmpresa
                    ? empresas.find(e => e.id === selectedEmpresa)?.nombre || usuario.empresa_nombre || 'Empresa asignada'
                    : 'Sin empresa (Root)'}
                </Text>
              </View>
              <Ionicons name="chevron-forward" size={16} color={Colors.textTertiary} />
            </TouchableOpacity>
          </Card>
        </>
      )}

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
            {currentUser?.es_root && (
              <Button
                title={usuario.es_root ? 'Quitar Acceso Root' : 'Designar como Root'}
                onPress={handleToggleRoot}
                variant={usuario.es_root ? 'destructive' : 'secondary'}
                loading={loading}
                style={styles.actionBtn}
              />
            )}
          </View>
        </>
      )}

      <Modal visible={empresaModalVisible} animationType="slide" transparent>
        <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Seleccionar Empresa</Text>
              <TouchableOpacity onPress={() => setEmpresaModalVisible(false)}>
                <Text style={styles.modalClose}>Cerrar</Text>
              </TouchableOpacity>
            </View>
            <TextInput
              style={styles.searchInput}
              value={empresaSearch}
              onChangeText={setEmpresaSearch}
              placeholder="Buscar empresa..."
              placeholderTextColor={Colors.textTertiary}
              autoFocus
            />
            <FlatList
              data={[
                { id: null, nombre: 'Sin empresa (Root)', isNone: true },
                ...empresas.filter(e => e.nombre?.toLowerCase().includes(empresaSearch.toLowerCase()))
              ]}
              keyExtractor={(item) => item.id || 'none'}
              style={styles.modalList}
              keyboardShouldPersistTaps="handled"
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={styles.modalRow}
                  onPress={() => {
                    setEmpresaModalVisible(false);
                    handleAsignarEmpresa(item.id);
                  }}
                >
                  <View style={styles.modalRowLeft}>
                    <Ionicons
                      name={item.isNone ? 'remove-circle-outline' : 'business-outline'}
                      size={20}
                      color={selectedEmpresa === item.id || (!selectedEmpresa && item.isNone) ? Colors.primary : Colors.textSecondary}
                    />
                    <Text style={[
                      styles.modalRowText,
                      (selectedEmpresa === item.id || (!selectedEmpresa && item.isNone)) && { color: Colors.primary, fontWeight: '600' }
                    ]}>
                      {item.nombre}
                    </Text>
                  </View>
                  {(selectedEmpresa === item.id || (!selectedEmpresa && item.isNone)) && (
                    <Ionicons name="checkmark" size={20} color={Colors.primary} />
                  )}
                </TouchableOpacity>
              )}
              ItemSeparatorComponent={() => <View style={styles.modalSeparator} />}
            />
          </View>
        </KeyboardAvoidingView>
      </Modal>
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
  empresaSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  empresaSelectorLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  empresaSelectorText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: Colors.card,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    maxHeight: '70%',
    paddingBottom: 34,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
  },
  modalTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    flex: 1,
  },
  modalClose: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '500',
  },
  searchInput: {
    backgroundColor: Colors.background,
    marginHorizontal: Spacing.md,
    marginVertical: Spacing.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: 10,
    borderRadius: BorderRadius.md,
    fontSize: FontSize.body,
    color: Colors.text,
  },
  modalList: {
    paddingHorizontal: Spacing.md,
  },
  modalRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
  },
  modalRowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    flex: 1,
  },
  modalRowText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  modalSeparator: {
    height: 1,
    backgroundColor: Colors.separator,
  },
});
