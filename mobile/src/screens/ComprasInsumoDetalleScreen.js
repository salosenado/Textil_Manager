import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator, Alert } from 'react-native';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

function formatMX(valor) {
  const num = Number(valor) || 0;
  return `MX $${num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function ComprasInsumoDetalleScreen({ route, navigation }) {
  const { id } = route.params;
  const [compra, setCompra] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCompra();
  }, [id]);

  const loadCompra = async () => {
    try {
      const data = await api.getCompraInsumo(id);
      setCompra(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: compra ? `OCI-${compra.numero_compra}` : 'Detalle',
    });
  }, [navigation, compra]);

  const handleDelete = () => {
    Alert.alert(
      'Eliminar',
      '¿Estás seguro de eliminar esta compra de insumo? Esta acción no se puede deshacer.',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCompraInsumo(id);
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

  if (!compra) {
    return (
      <View style={styles.centered}>
        <Text style={styles.emptyText}>Compra no encontrada</Text>
      </View>
    );
  }

  const detalles = compra.detalles || [];
  const subtotal = detalles.reduce((sum, d) => sum + (Number(d.cantidad) || 0) * (Number(d.costo_unitario) || 0), 0);
  const iva = compra.aplica_iva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  return (
    <ScrollView style={styles.container}>
      <SectionHeader title="Información General" />
      <View style={styles.card}>
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Folio</Text>
          <Text style={styles.infoValue}>OCI-{compra.numero_compra}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Proveedor</Text>
          <Text style={styles.infoValue}>{compra.proveedor_cliente || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha Creación</Text>
          <Text style={styles.infoValue}>{formatDate(compra.fecha_creacion)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha Recepción</Text>
          <Text style={styles.infoValue}>{formatDate(compra.fecha_recepcion)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Aplica IVA</Text>
          <Text style={styles.infoValue}>{compra.aplica_iva ? 'Sí' : 'No'}</Text>
        </View>
        {compra.observaciones ? (
          <>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Observaciones</Text>
              <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]}>{compra.observaciones}</Text>
            </View>
          </>
        ) : null}
      </View>

      <SectionHeader title={`Detalles (${detalles.length})`} />
      {detalles.map((det, index) => (
        <View key={det.id || index} style={styles.card}>
          <Text style={styles.detalleTitle}>Línea {index + 1}</Text>
          {det.articulo ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Artículo</Text>
              <Text style={styles.detValue}>{det.articulo}</Text>
            </View>
          ) : null}
          {det.linea ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Línea</Text>
              <Text style={styles.detValue}>{det.linea}</Text>
            </View>
          ) : null}
          {det.modelo ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Modelo</Text>
              <Text style={styles.detValue}>{det.modelo}</Text>
            </View>
          ) : null}
          {det.color ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Color</Text>
              <Text style={styles.detValue}>{det.color}</Text>
            </View>
          ) : null}
          {det.talla ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Talla</Text>
              <Text style={styles.detValue}>{det.talla}</Text>
            </View>
          ) : null}
          {det.unidad ? (
            <View style={styles.detRow}>
              <Text style={styles.detLabel}>Unidad</Text>
              <Text style={styles.detValue}>{det.unidad}</Text>
            </View>
          ) : null}
          <View style={styles.detRow}>
            <Text style={styles.detLabel}>Cantidad</Text>
            <Text style={styles.detValue}>{Number(det.cantidad) || 0}</Text>
          </View>
          <View style={styles.detRow}>
            <Text style={styles.detLabel}>Costo Unitario</Text>
            <Text style={styles.detValue}>{formatMX(det.costo_unitario)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.detRow}>
            <Text style={styles.detLabelBold}>Importe</Text>
            <Text style={styles.detValueBold}>
              {formatMX((Number(det.cantidad) || 0) * (Number(det.costo_unitario) || 0))}
            </Text>
          </View>
        </View>
      ))}

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMX(subtotal)}</Text>
        </View>
        {compra.aplica_iva && (
          <>
            <View style={styles.divider} />
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>IVA (16%)</Text>
              <Text style={styles.summaryValue}>{formatMX(iva)}</Text>
            </View>
          </>
        )}
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabelBold}>Total</Text>
          <Text style={styles.summaryValueBold}>{formatMX(total)}</Text>
        </View>
      </View>

      <View style={styles.buttonContainer}>
        <Button
          title="Editar"
          onPress={() => navigation.navigate('ComprasInsumoForm', { id: compra.id })}
        />
        <View style={{ height: Spacing.sm }} />
        <Button
          title="Eliminar"
          onPress={handleDelete}
          variant="destructive"
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
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
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
  detalleTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    paddingVertical: Spacing.xs,
  },
  detRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 3,
  },
  detLabel: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
  },
  detValue: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  detLabelBold: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  detValueBold: {
    fontSize: FontSize.body,
    fontWeight: '700',
    color: Colors.primary,
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
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
