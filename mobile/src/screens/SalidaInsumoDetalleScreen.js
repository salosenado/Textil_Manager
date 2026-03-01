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

export default function SalidaInsumoDetalleScreen({ route, navigation }) {
  const salidaId = route.params?.id;
  const [salida, setSalida] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadSalida = useCallback(async () => {
    try {
      const data = await api.getSalidaInsumo(salidaId);
      setSalida(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [salidaId]);

  useEffect(() => {
    loadSalida();
  }, [loadSalida]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      if (salida) {
        loadSalida();
      }
    });
    return unsubscribe;
  }, [navigation, loadSalida, salida]);

  useEffect(() => {
    if (salida) {
      navigation.setOptions({
        title: salida.folio || 'Salida de Insumo',
      });
    }
  }, [salida, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadSalida();
  };

  const handleEdit = () => {
    navigation.navigate('SalidaInsumoForm', { id: salida.id });
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancelar Salida',
      '¿Estás seguro de cancelar esta salida de insumo? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarSalidaInsumo(salida.id);
              loadSalida();
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
      'Eliminar Salida',
      '¿Estás seguro de eliminar esta salida de insumo? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteSalidaInsumo(salida.id);
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

  if (!salida) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Salida no encontrada</Text>
      </View>
    );
  }

  const isCancelled = salida.cancelada;
  const detalles = salida.detalles || [];
  const totalMonto = parseFloat(salida.total_monto) || 0;

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {isCancelled && (
          <View style={styles.cancelledBanner}>
            <Ionicons name="close-circle" size={20} color={Colors.white} />
            <Text style={styles.cancelledText}>Salida Cancelada</Text>
          </View>
        )}

        <SectionHeader title="Información" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Folio</Text>
            <Text style={styles.infoValue}>{salida.folio || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Fecha</Text>
            <Text style={styles.infoValue}>{formatDate(salida.fecha_salida)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Destino</Text>
            <Text style={styles.infoValue}>{salida.destino || '—'}</Text>
          </View>
          {salida.observaciones ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Observaciones</Text>
                <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]} numberOfLines={3}>
                  {salida.observaciones}
                </Text>
              </View>
            </>
          ) : null}
          {salida.usuario_creacion ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Creado por</Text>
                <Text style={styles.infoValue}>{salida.usuario_creacion}</Text>
              </View>
            </>
          ) : null}
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Estado</Text>
            <View style={[styles.statusBadge, { backgroundColor: (isCancelled ? Colors.error : Colors.success) + '20' }]}>
              <Text style={[styles.statusText, { color: isCancelled ? Colors.error : Colors.success }]}>
                {isCancelled ? 'Cancelada' : 'Activa'}
              </Text>
            </View>
          </View>
        </View>

        <SectionHeader title={`Detalles (${detalles.length})`} />
        <View style={styles.card}>
          {detalles.length > 0 ? (
            detalles.map((det, i) => (
              <React.Fragment key={det.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.detalleItem}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.detalleArticulo}>{det.articulo || 'Sin artículo'}</Text>
                    {det.modelo ? (
                      <Text style={styles.detalleCaption}>Modelo: {det.modelo}</Text>
                    ) : null}
                    <Text style={styles.detalleCaption}>
                      {det.cantidad} {det.unidad || 'PZ'} × {formatMX(det.costo_unitario)}
                    </Text>
                  </View>
                  <Text style={styles.detalleSubtotal}>
                    {formatMX((parseInt(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
                  </Text>
                </View>
              </React.Fragment>
            ))
          ) : (
            <Text style={styles.emptyText}>Sin detalles</Text>
          )}
        </View>

        <SectionHeader title="Resumen" />
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
            <Button title="Cancelar Salida" onPress={handleCancel} variant="destructive" />
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
    gap: Spacing.xs,
  },
  cancelledText: {
    color: Colors.white,
    fontSize: FontSize.footnote,
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
  },
  infoValue: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  statusText: {
    fontSize: FontSize.caption,
    fontWeight: '600',
  },
  detalleItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  detalleArticulo: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 2,
  },
  detalleCaption: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 1,
  },
  detalleSubtotal: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
    marginLeft: Spacing.sm,
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
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingVertical: Spacing.md,
  },
});
