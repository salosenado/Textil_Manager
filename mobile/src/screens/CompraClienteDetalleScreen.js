import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator, Alert, TouchableOpacity } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

function formatMoney(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  const day = d.getDate();
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return `${day} ${months[d.getMonth()]} ${d.getFullYear()}`;
}

export default function CompraClienteDetalleScreen({ route, navigation }) {
  const { id } = route.params;
  const [orden, setOrden] = useState(null);
  const [loading, setLoading] = useState(true);

  const loadOrden = async () => {
    try {
      const data = await api.getOrdenCompra(id);
      setOrden(data);
    } catch (err) {
      console.error(err);
      Alert.alert('Error', 'No se pudo cargar la orden de compra');
    } finally {
      setLoading(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadOrden();
    }, [id])
  );

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: orden ? `OC-${orden.numero_compra}` : 'Detalle OC',
    });
  }, [navigation, orden]);

  const handleCancelar = () => {
    Alert.alert(
      'Cancelar Orden',
      '¿Estás seguro de cancelar esta orden de compra? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarOrdenCompra(id);
              loadOrden();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleEliminar = () => {
    Alert.alert(
      'Eliminar Orden',
      '¿Estás seguro de eliminar esta orden de compra? Esta acción no se puede deshacer.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteOrdenCompra(id);
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
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textTertiary} />
        <Text style={styles.emptyText}>Orden no encontrada</Text>
      </View>
    );
  }

  const detalles = orden.detalles || [];
  const movimientos = orden.movimientos || [];

  const subtotal = detalles.reduce((sum, d) => {
    return sum + ((parseFloat(d.cantidad) || 0) * (parseFloat(d.costo_unitario) || 0));
  }, 0);
  const iva = orden.aplica_iva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  return (
    <ScrollView style={styles.container}>
      <SectionHeader title="Información General" />
      <View style={styles.card}>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}># Orden</Text>
          <Text style={styles.infoValue}>OC-{orden.numero_compra}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Estado</Text>
          <View style={[styles.badge, orden.cancelada ? styles.badgeCancelled : styles.badgeActive]}>
            <Text style={[styles.badgeText, orden.cancelada ? styles.badgeTextCancelled : styles.badgeTextActive]}>
              {orden.cancelada ? 'Cancelada' : 'Activa'}
            </Text>
          </View>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Proveedor</Text>
          <Text style={styles.infoValue}>{orden.proveedor_nombre || orden.proveedor_nombre_rel || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha Creación</Text>
          <Text style={styles.infoValue}>{formatDate(orden.fecha_creacion)}</Text>
        </View>
        {orden.fecha_recepcion && (
          <>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Fecha Recepción</Text>
              <Text style={styles.infoValue}>{formatDate(orden.fecha_recepcion)}</Text>
            </View>
          </>
        )}
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Aplica IVA</Text>
          <Text style={styles.infoValue}>{orden.aplica_iva ? 'Sí' : 'No'}</Text>
        </View>
        {orden.observaciones && (
          <>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Observaciones</Text>
              <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]}>{orden.observaciones}</Text>
            </View>
          </>
        )}
      </View>

      <SectionHeader title={`Detalles (${detalles.length})`} />
      {detalles.length === 0 ? (
        <View style={styles.card}>
          <Text style={styles.emptyCardText}>Sin detalles</Text>
        </View>
      ) : (
        detalles.map((det, i) => (
          <View key={det.id || i} style={styles.card}>
            <Text style={styles.detalleTitle}>{det.articulo || 'Sin artículo'}</Text>
            {det.modelo ? <Text style={styles.detalleSubtitle}>Modelo: {det.modelo}</Text> : null}
            <View style={styles.detalleRow}>
              <Text style={styles.detalleCant}>Cant: {det.cantidad || 0}</Text>
              <Text style={styles.detallePrecio}>Costo: {formatMoney(det.costo_unitario)}</Text>
            </View>
            <Text style={styles.detalleImporte}>
              Importe: {formatMoney((parseFloat(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
            </Text>
          </View>
        ))
      )}

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMoney(subtotal)}</Text>
        </View>
        {orden.aplica_iva && (
          <>
            <View style={styles.divider} />
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>IVA (16%)</Text>
              <Text style={styles.summaryValue}>{formatMoney(iva)}</Text>
            </View>
          </>
        )}
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabelBold}>Total</Text>
          <Text style={styles.summaryValueBold}>{formatMoney(total)}</Text>
        </View>
      </View>

      {movimientos.length > 0 && (
        <>
          <SectionHeader title="Historial" />
          <View style={styles.card}>
            {movimientos.map((mov, i) => (
              <React.Fragment key={mov.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.movRow}>
                  <Ionicons name="time-outline" size={16} color={Colors.textTertiary} />
                  <View style={styles.movTextContainer}>
                    <Text style={styles.movText}>{mov.movimiento}</Text>
                    <Text style={styles.movDate}>{formatDate(mov.fecha)}</Text>
                  </View>
                </View>
              </React.Fragment>
            ))}
          </View>
        </>
      )}

      {!orden.cancelada && (
        <View style={styles.buttonContainer}>
          <Button
            title="Editar"
            onPress={() => navigation.navigate('CompraClienteForm', { id: orden.id })}
          />
          <View style={{ height: Spacing.sm }} />
          <Button
            title="Cancelar Orden"
            onPress={handleCancelar}
            variant="destructive"
          />
        </View>
      )}

      <View style={styles.buttonContainer}>
        <Button
          title="Eliminar"
          onPress={handleEliminar}
          variant="secondary"
        />
      </View>

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
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
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
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  badgeActive: {
    backgroundColor: Colors.success + '20',
  },
  badgeCancelled: {
    backgroundColor: Colors.error + '20',
  },
  badgeText: {
    fontSize: FontSize.caption,
    fontWeight: '600',
  },
  badgeTextActive: {
    color: Colors.success,
  },
  badgeTextCancelled: {
    color: Colors.error,
  },
  detalleTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    paddingTop: Spacing.xs,
  },
  detalleSubtitle: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  detalleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 4,
  },
  detalleCant: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
  },
  detallePrecio: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
  },
  detalleImporte: {
    fontSize: FontSize.footnote,
    color: Colors.primary,
    textAlign: 'right',
    fontWeight: '500',
    marginTop: 2,
    marginBottom: Spacing.xs,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  summaryLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  summaryValue: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  summaryLabelBold: {
    fontSize: FontSize.headline,
    fontWeight: '700',
    color: Colors.text,
  },
  summaryValueBold: {
    fontSize: FontSize.headline,
    fontWeight: '700',
    color: Colors.primary,
  },
  movRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: Spacing.xs,
    gap: 8,
  },
  movTextContainer: {
    flex: 1,
  },
  movText: {
    fontSize: FontSize.footnote,
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
    marginTop: Spacing.md,
  },
  emptyCardText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingVertical: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.md,
  },
});
