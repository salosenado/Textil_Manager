import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator, RefreshControl
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import SectionHeader from '../components/SectionHeader';
import Button from '../components/Button';

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function ReingresoDetalleScreen({ route, navigation }) {
  const reingresoId = route.params?.id;
  const [reingreso, setReingreso] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadReingreso = useCallback(async () => {
    try {
      const data = await api.getReingreso(reingresoId);
      setReingreso(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [reingresoId]);

  useEffect(() => {
    loadReingreso();
  }, [loadReingreso]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      if (reingreso) {
        loadReingreso();
      }
    });
    return unsubscribe;
  }, [navigation, loadReingreso, reingreso]);

  useEffect(() => {
    if (reingreso) {
      navigation.setOptions({
        title: reingreso.folio || 'Reingreso',
      });
    }
  }, [reingreso, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadReingreso();
  };

  const handleEdit = () => {
    navigation.navigate('ReingresoForm', { id: reingreso.id });
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancelar Reingreso',
      '¿Estás seguro de cancelar este reingreso? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarReingreso(reingreso.id);
              loadReingreso();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleDelete = () => {
    Alert.alert(
      'Eliminar Reingreso',
      '¿Estás seguro de eliminar este reingreso? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteReingreso(reingreso.id);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
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

  if (!reingreso) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Reingreso no encontrado</Text>
      </View>
    );
  }

  const isCancelled = reingreso.cancelado;
  const detalles = reingreso.detalles || [];
  const totalMonto = parseFloat(reingreso.total_monto) || 0;

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {isCancelled && (
          <View style={styles.cancelledBanner}>
            <Ionicons name="close-circle" size={20} color={Colors.white} />
            <Text style={styles.cancelledText}>Reingreso Cancelado</Text>
          </View>
        )}

        <SectionHeader title="Información" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Folio</Text>
            <Text style={styles.infoValue}>{reingreso.folio || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Fecha</Text>
            <Text style={styles.infoValue}>{formatDate(reingreso.fecha_reingreso)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Cliente</Text>
            <Text style={styles.infoValue}>{reingreso.cliente_nombre || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Motivo</Text>
            <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]} numberOfLines={3}>
              {reingreso.motivo || '—'}
            </Text>
          </View>
          {reingreso.observaciones ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Observaciones</Text>
                <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]} numberOfLines={3}>
                  {reingreso.observaciones}
                </Text>
              </View>
            </>
          ) : null}
          {reingreso.usuario_creacion ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Creado por</Text>
                <Text style={styles.infoValue}>{reingreso.usuario_creacion}</Text>
              </View>
            </>
          ) : null}
        </View>

        <SectionHeader title={`Detalles (${detalles.length})`} />
        {detalles.length > 0 ? (
          <View style={styles.card}>
            {detalles.map((det, i) => {
              const cant = parseInt(det.cantidad) || 0;
              const costo = parseFloat(det.costo_unitario) || 0;
              const subtotal = cant * costo;
              return (
                <React.Fragment key={det.id || i}>
                  {i > 0 && <View style={styles.divider} />}
                  <View style={styles.detalleItem}>
                    <View style={styles.detalleMain}>
                      <View style={styles.detalleNameRow}>
                        <Text style={styles.detalleName} numberOfLines={1}>{det.nombre || '—'}</Text>
                        {det.es_servicio && (
                          <View style={styles.servicioBadge}>
                            <Text style={styles.servicioBadgeText}>Servicio</Text>
                          </View>
                        )}
                      </View>
                      {det.talla ? (
                        <Text style={styles.detalleCaption}>Talla: {det.talla}</Text>
                      ) : null}
                      <Text style={styles.detalleCaption}>
                        {cant} {det.unidad || 'PZ'} × {formatMX(costo)}
                      </Text>
                    </View>
                    <Text style={styles.detalleSubtotal}>{formatMX(subtotal)}</Text>
                  </View>
                </React.Fragment>
              );
            })}
          </View>
        ) : (
          <View style={styles.card}>
            <Text style={styles.emptyText}>Sin detalles</Text>
          </View>
        )}

        <SectionHeader title="Total" />
        <View style={styles.card}>
          <View style={styles.summaryRow}>
            <Text style={styles.totalLabel}>Total</Text>
            <Text style={styles.totalValue}>{formatMX(totalMonto)}</Text>
          </View>
        </View>

        {!isCancelled && (
          <View style={styles.buttonContainer}>
            <Button title="Editar" onPress={handleEdit} />
            <View style={{ height: Spacing.sm }} />
            <Button title="Cancelar Reingreso" onPress={handleCancel} variant="destructive" />
          </View>
        )}

        <View style={styles.buttonContainer}>
          <Button title="Eliminar" onPress={handleDelete} variant="destructive" />
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
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
    paddingHorizontal: Spacing.lg,
  },
  cancelledBanner: {
    backgroundColor: Colors.destructive,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.sm,
    gap: 8,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: BorderRadius.sm,
  },
  cancelledText: {
    color: Colors.white,
    fontSize: FontSize.body,
    fontWeight: '600',
  },
  card: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginVertical: Spacing.xs,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  infoLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginRight: Spacing.md,
  },
  infoValue: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
  },
  detalleItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  detalleMain: {
    flex: 1,
    marginRight: Spacing.md,
  },
  detalleNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 2,
  },
  detalleName: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  servicioBadge: {
    backgroundColor: Colors.purple + '20',
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  servicioBadgeText: {
    fontSize: FontSize.xs,
    fontWeight: '600',
    color: Colors.purple,
  },
  detalleCaption: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
  },
  detalleSubtotal: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  totalLabel: {
    fontSize: FontSize.body,
    fontWeight: '700',
    color: Colors.text,
  },
  totalValue: {
    fontSize: FontSize.xl,
    fontWeight: '700',
    color: Colors.primary,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingVertical: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
