import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl, ActivityIndicator, Alert } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Card from '../components/Card';
import SectionHeader from '../components/SectionHeader';
import Button from '../components/Button';

export default function EmpresaDetalleScreen({ route, navigation }) {
  const { empresaId } = route.params;
  const [empresa, setEmpresa] = useState(null);
  const [reportes, setReportes] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [toggling, setToggling] = useState(false);
  const [deleting, setDeleting] = useState(false);

  const loadData = async () => {
    try {
      const [empresaData, reportesData] = await Promise.all([
        api.getEmpresa(empresaId),
        api.getEmpresaReportes(empresaId),
      ]);
      setEmpresa(empresaData);
      setReportes(reportesData);
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
    }, [empresaId])
  );

  const handleToggleActivo = () => {
    const accion = empresa.activo ? 'desactivar' : 'activar';
    Alert.alert(
      `${accion.charAt(0).toUpperCase() + accion.slice(1)} empresa`,
      `¿Estás seguro de ${accion} "${empresa.nombre}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: accion.charAt(0).toUpperCase() + accion.slice(1),
          style: empresa.activo ? 'destructive' : 'default',
          onPress: async () => {
            setToggling(true);
            try {
              const result = await api.toggleActivoEmpresa(empresaId);
              setEmpresa(prev => ({ ...prev, activo: result.activo }));
            } catch (err) {
              Alert.alert('Error', err.message);
            } finally {
              setToggling(false);
            }
          },
        },
      ]
    );
  };

  const handleEliminar = () => {
    Alert.alert(
      'Eliminar empresa',
      `¿Estás seguro de eliminar "${empresa.nombre}"? Esta acción no se puede deshacer.`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            setDeleting(true);
            try {
              await api.deleteEmpresa(empresaId);
              Alert.alert('Listo', `Empresa "${empresa.nombre}" eliminada`);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
            } finally {
              setDeleting(false);
            }
          },
        },
      ]
    );
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  if (!empresa) {
    return (
      <View style={styles.centered}>
        <Text style={styles.emptyText}>Empresa no encontrada</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadData(); }} />}
    >
      <View style={styles.headerCard}>
        <View style={[styles.headerIcon, { backgroundColor: empresa.activo ? Colors.primary + '20' : Colors.error + '20' }]}>
          <Ionicons name="business" size={32} color={empresa.activo ? Colors.primary : Colors.error} />
        </View>
        <Text style={styles.headerName}>{empresa.nombre}</Text>
        {!empresa.activo && (
          <View style={styles.inactiveBadge}>
            <Text style={styles.inactiveBadgeText}>Inactiva</Text>
          </View>
        )}
        {empresa.rfc && <Text style={styles.headerSub}>RFC: {empresa.rfc}</Text>}
      </View>

      <SectionHeader title="Información" />
      <Card style={styles.infoCard}>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Dirección</Text>
          <Text style={styles.infoValue}>{empresa.direccion || 'No registrada'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Teléfono</Text>
          <Text style={styles.infoValue}>{empresa.telefono || 'No registrado'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Creada</Text>
          <Text style={styles.infoValue}>{new Date(empresa.created_at).toLocaleDateString('es-MX')}</Text>
        </View>
      </Card>

      {reportes && (
        <>
          <SectionHeader title="Actividad" />
          <View style={styles.statsRow}>
            <StatBox label="Usuarios" value={reportes.usuarios} icon="people" color={Colors.primary} />
            <StatBox label="Roles" value={reportes.roles} icon="shield" color={Colors.purple} />
            <StatBox label="Órdenes" value={reportes.ordenes} icon="document-text" color={Colors.orange} />
          </View>
          <View style={styles.statsRow}>
            <StatBox label="Producciones" value={reportes.producciones} icon="construct" color={Colors.teal} />
            <StatBox label="Ventas" value={reportes.ventas} icon="cart" color={Colors.success} />
          </View>
        </>
      )}

      <SectionHeader title={`Usuarios (${empresa.usuarios?.length || 0})`} />
      {empresa.usuarios?.length > 0 ? (
        <Card style={styles.listCard}>
          {empresa.usuarios.map((u, i) => (
            <React.Fragment key={u.id}>
              {i > 0 && <View style={styles.listDivider} />}
              <View style={styles.userRow}>
                <View style={styles.userInfo}>
                  <Text style={styles.userName}>{u.nombre}</Text>
                  <Text style={styles.userEmail}>{u.email}</Text>
                  {u.rol_nombre && <Text style={styles.userRol}>{u.rol_nombre}</Text>}
                </View>
                <View style={styles.userBadges}>
                  {!u.aprobado && (
                    <View style={[styles.smallBadge, { backgroundColor: Colors.warning + '20' }]}>
                      <Text style={[styles.smallBadgeText, { color: Colors.warning }]}>Pendiente</Text>
                    </View>
                  )}
                  {!u.activo && (
                    <View style={[styles.smallBadge, { backgroundColor: Colors.error + '20' }]}>
                      <Text style={[styles.smallBadgeText, { color: Colors.error }]}>Inactivo</Text>
                    </View>
                  )}
                </View>
              </View>
            </React.Fragment>
          ))}
        </Card>
      ) : (
        <Card style={styles.listCard}>
          <Text style={styles.emptyList}>Sin usuarios registrados</Text>
        </Card>
      )}

      <View style={styles.actions}>
        <Button
          title="Editar Empresa"
          onPress={() => navigation.navigate('EmpresaForm', { empresa })}
          variant="secondary"
        />
        <View style={{ height: Spacing.sm }} />
        <Button
          title={empresa.activo ? 'Desactivar Empresa' : 'Activar Empresa'}
          onPress={handleToggleActivo}
          loading={toggling}
          variant={empresa.activo ? 'destructive' : 'primary'}
        />
        <View style={{ height: Spacing.sm }} />
        <Button
          title="Eliminar Empresa"
          onPress={handleEliminar}
          loading={deleting}
          variant="destructive"
        />
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

function StatBox({ label, value, icon, color }) {
  return (
    <View style={styles.statBox}>
      <Ionicons name={icon} size={20} color={color} />
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.background,
  },
  headerCard: {
    backgroundColor: Colors.card,
    padding: Spacing.lg,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
  },
  headerIcon: {
    width: 64,
    height: 64,
    borderRadius: 32,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  headerName: {
    fontSize: FontSize.title,
    fontWeight: 'bold',
    color: Colors.text,
  },
  headerSub: {
    fontSize: FontSize.subheadline,
    color: Colors.textSecondary,
    marginTop: 4,
  },
  inactiveBadge: {
    backgroundColor: Colors.error + '20',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 10,
    marginTop: 8,
  },
  inactiveBadgeText: {
    color: Colors.error,
    fontWeight: '600',
    fontSize: FontSize.caption,
  },
  infoCard: {
    marginHorizontal: Spacing.md,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 4,
  },
  infoLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  infoValue: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
    textAlign: 'right',
    flex: 1,
    marginLeft: Spacing.md,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginVertical: 6,
  },
  statsRow: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.md,
    gap: Spacing.sm,
    marginBottom: Spacing.sm,
  },
  statBox: {
    flex: 1,
    backgroundColor: Colors.card,
    borderRadius: 12,
    padding: Spacing.sm,
    alignItems: 'center',
    gap: 4,
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: Colors.text,
  },
  statLabel: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
  },
  listCard: {
    marginHorizontal: Spacing.md,
  },
  listDivider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginVertical: 6,
  },
  userRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  userInfo: {
    flex: 1,
  },
  userName: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  userEmail: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  userRol: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    marginTop: 2,
  },
  userBadges: {
    flexDirection: 'row',
    gap: 4,
  },
  smallBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  smallBadgeText: {
    fontSize: 11,
    fontWeight: '600',
  },
  emptyList: {
    textAlign: 'center',
    color: Colors.textTertiary,
    fontSize: FontSize.body,
    paddingVertical: Spacing.sm,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  actions: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
