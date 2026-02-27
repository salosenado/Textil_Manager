import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator, TouchableOpacity, RefreshControl
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

export default function OrdenClienteDetalleScreen({ route, navigation }) {
  const ordenId = route.params?.id || route.params?.ordenId;
  const [orden, setOrden] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadOrden = useCallback(async () => {
    try {
      const data = await api.getOrdenCliente(ordenId);
      setOrden(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [ordenId]);

  useEffect(() => {
    loadOrden();
  }, [loadOrden]);

  useEffect(() => {
    if (orden) {
      navigation.setOptions({
        title: `Orden #${orden.numero_venta}`,
      });
    }
  }, [orden, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadOrden();
  };

  const handleEdit = () => {
    navigation.navigate('OrdenClienteForm', { orden });
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancelar Orden',
      `¿Estás seguro de cancelar la Orden #${orden.numero_venta}? Esta acción no se puede deshacer.`,
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarOrdenCliente(orden.id);
              loadOrden();
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
      'Eliminar Orden',
      `¿Estás seguro de eliminar la Orden #${orden.numero_venta}? Esta acción no se puede deshacer.`,
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteOrdenCliente(orden.id);
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

  if (!orden) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Orden no encontrada</Text>
      </View>
    );
  }

  const isCancelled = orden.cancelada;

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      {isCancelled && (
        <View style={styles.cancelledBanner}>
          <Ionicons name="close-circle" size={20} color={Colors.white} />
          <Text style={styles.cancelledText}>Orden Cancelada</Text>
        </View>
      )}

      <SectionHeader title="Información General" />
      <View style={styles.card}>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}># de Venta</Text>
          <Text style={styles.infoValue}>Venta #{orden.numero_venta}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Cliente</Text>
          <Text style={styles.infoValue}>
            {orden.cliente_nombre_ref || orden.cliente_nombre || '—'}
          </Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Agente</Text>
          <Text style={styles.infoValue}>{orden.agente_nombre || '—'}</Text>
        </View>
        {orden.numero_pedido_cliente && (
          <>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Pedido Cliente</Text>
              <Text style={styles.infoValue}>{orden.numero_pedido_cliente}</Text>
            </View>
          </>
        )}
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha Creación</Text>
          <Text style={styles.infoValue}>{formatDate(orden.fecha_creacion)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha Entrega</Text>
          <Text style={styles.infoValue}>{formatDate(orden.fecha_entrega)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Aplica IVA</Text>
          <Text style={[styles.infoValue, { color: orden.aplica_iva ? Colors.success : Colors.textSecondary }]}>
            {orden.aplica_iva ? 'Sí' : 'No'}
          </Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Estado</Text>
          <View style={[styles.badge, isCancelled ? styles.badgeCancelled : styles.badgeActive]}>
            <Text style={[styles.badgeText, isCancelled ? styles.badgeCancelledText : styles.badgeActiveText]}>
              {isCancelled ? 'Cancelada' : 'Activa'}
            </Text>
          </View>
        </View>
      </View>

      <SectionHeader title={`Detalles (${orden.detalles?.length || 0})`} />
      {orden.detalles && orden.detalles.length > 0 ? (
        orden.detalles.map((det, index) => (
          <View key={det.id || index} style={styles.card}>
            <View style={styles.detalleHeader}>
              <Text style={styles.detalleTitle}>
                {det.articulo || det.modelo || `Línea ${index + 1}`}
              </Text>
              <Text style={styles.detalleImporte}>
                {formatMX(det.cantidad * parseFloat(det.precio_unitario))}
              </Text>
            </View>
            <View style={styles.detalleGrid}>
              {det.modelo && (
                <View style={styles.detalleChip}>
                  <Text style={styles.chipLabel}>Modelo</Text>
                  <Text style={styles.chipValue}>{det.modelo}</Text>
                </View>
              )}
              {det.linea && (
                <View style={styles.detalleChip}>
                  <Text style={styles.chipLabel}>Línea</Text>
                  <Text style={styles.chipValue}>{det.linea}</Text>
                </View>
              )}
              {det.color && (
                <View style={styles.detalleChip}>
                  <Text style={styles.chipLabel}>Color</Text>
                  <Text style={styles.chipValue}>{det.color}</Text>
                </View>
              )}
              {det.talla && (
                <View style={styles.detalleChip}>
                  <Text style={styles.chipLabel}>Talla</Text>
                  <Text style={styles.chipValue}>{det.talla}</Text>
                </View>
              )}
              {det.unidad && (
                <View style={styles.detalleChip}>
                  <Text style={styles.chipLabel}>Unidad</Text>
                  <Text style={styles.chipValue}>{det.unidad}</Text>
                </View>
              )}
            </View>
            <View style={styles.divider} />
            <View style={styles.detallePricing}>
              <Text style={styles.pricingText}>
                {det.cantidad} x {formatMX(det.precio_unitario)}
              </Text>
            </View>
          </View>
        ))
      ) : (
        <View style={styles.card}>
          <Text style={styles.emptyText}>Sin detalles</Text>
        </View>
      )}

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMX(orden.subtotal)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>IVA (16%)</Text>
          <Text style={styles.summaryValue}>{formatMX(orden.iva)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>{formatMX(orden.total)}</Text>
        </View>
      </View>

      {orden.movimientos && orden.movimientos.length > 0 && (
        <>
          <SectionHeader title="Historial" />
          <View style={styles.card}>
            {orden.movimientos.map((mov, i) => (
              <React.Fragment key={mov.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.movRow}>
                  <Ionicons name="time-outline" size={16} color={Colors.textSecondary} />
                  <View style={styles.movContent}>
                    <Text style={styles.movText}>{mov.movimiento}</Text>
                    <Text style={styles.movDate}>{formatDate(mov.fecha)}</Text>
                  </View>
                </View>
              </React.Fragment>
            ))}
          </View>
        </>
      )}

      {!isCancelled && (
        <View style={styles.buttonContainer}>
          <Button title="Editar Orden" onPress={handleEdit} />
          <View style={{ height: Spacing.sm }} />
          <Button title="Cancelar Orden" onPress={handleCancel} variant="destructive" />
        </View>
      )}

      {isCancelled && (
        <View style={styles.buttonContainer}>
          <Button title="Eliminar Orden" onPress={handleDelete} variant="destructive" />
        </View>
      )}

      <View style={{ height: 40 }} />
    </ScrollView>
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
  cancelledBanner: {
    backgroundColor: Colors.destructive,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: BorderRadius.sm,
    gap: Spacing.sm,
  },
  cancelledText: {
    color: Colors.white,
    fontSize: FontSize.body,
    fontWeight: '600',
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
    flex: 1,
  },
  infoValue: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
    textAlign: 'right',
    flex: 1,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  badgeActive: {
    backgroundColor: Colors.success + '20',
  },
  badgeCancelled: {
    backgroundColor: Colors.destructive + '20',
  },
  badgeText: {
    fontSize: FontSize.footnote,
    fontWeight: '600',
  },
  badgeActiveText: {
    color: Colors.success,
  },
  badgeCancelledText: {
    color: Colors.destructive,
  },
  detalleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  detalleTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    flex: 1,
  },
  detalleImporte: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.primary,
  },
  detalleGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.xs,
    marginBottom: Spacing.sm,
  },
  detalleChip: {
    backgroundColor: Colors.background,
    borderRadius: 8,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
  },
  chipLabel: {
    fontSize: FontSize.xs,
    color: Colors.textSecondary,
  },
  chipValue: {
    fontSize: FontSize.footnote,
    color: Colors.text,
    fontWeight: '500',
  },
  detallePricing: {
    paddingVertical: Spacing.xs,
  },
  pricingText: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  summaryLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  summaryValue: {
    fontSize: FontSize.body,
    color: Colors.text,
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
  movRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: Spacing.sm,
    gap: Spacing.sm,
  },
  movContent: {
    flex: 1,
  },
  movText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  movDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
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
