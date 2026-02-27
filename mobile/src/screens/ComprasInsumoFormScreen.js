import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Switch, TouchableOpacity, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

const EMPTY_DETALLE = {
  articulo: '',
  linea: '',
  modelo: '',
  color: '',
  talla: '',
  unidad: '',
  cantidad: '',
  costo_unitario: '',
};

function formatMX(valor) {
  const num = Number(valor) || 0;
  return `MX $${num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
}

export default function ComprasInsumoFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [proveedor_cliente, setProveedorCliente] = useState('');
  const [fecha_recepcion, setFechaRecepcion] = useState('');
  const [aplica_iva, setAplicaIva] = useState(false);
  const [observaciones, setObservaciones] = useState('');
  const [detalles, setDetalles] = useState([{ ...EMPTY_DETALLE }]);
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isEditing) {
      loadCompra();
    }
  }, [editId]);

  const loadCompra = async () => {
    setLoadingData(true);
    try {
      const data = await api.getCompraInsumo(editId);
      setProveedorCliente(data.proveedor_cliente || '');
      setFechaRecepcion(data.fecha_recepcion ? data.fecha_recepcion.split('T')[0] : '');
      setAplicaIva(data.aplica_iva || false);
      setObservaciones(data.observaciones || '');
      if (data.detalles && data.detalles.length > 0) {
        setDetalles(data.detalles.map(d => ({
          articulo: d.articulo || '',
          linea: d.linea || '',
          modelo: d.modelo || '',
          color: d.color || '',
          talla: d.talla || '',
          unidad: d.unidad || '',
          cantidad: d.cantidad != null ? String(d.cantidad) : '',
          costo_unitario: d.costo_unitario != null ? String(d.costo_unitario) : '',
        })));
      }
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar Compra Insumo' : 'Nueva Compra Insumo',
    });
  }, [navigation, isEditing]);

  const updateDetalle = (index, key, value) => {
    setDetalles(prev => {
      const copy = [...prev];
      copy[index] = { ...copy[index], [key]: value };
      return copy;
    });
  };

  const addDetalle = () => {
    setDetalles(prev => [...prev, { ...EMPTY_DETALLE }]);
  };

  const removeDetalle = (index) => {
    if (detalles.length <= 1) return;
    setDetalles(prev => prev.filter((_, i) => i !== index));
  };

  const calcSubtotal = () => {
    return detalles.reduce((sum, d) => {
      return sum + (Number(d.cantidad) || 0) * (Number(d.costo_unitario) || 0);
    }, 0);
  };

  const subtotal = calcSubtotal();
  const iva = aplica_iva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  const handleSave = async () => {
    const validDetalles = detalles.filter(d =>
      d.articulo.trim() || d.modelo.trim() || (Number(d.cantidad) > 0)
    );

    if (validDetalles.length === 0) {
      setError('Se requiere al menos un detalle con datos');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const payload = {
        proveedor_cliente: proveedor_cliente || null,
        fecha_recepcion: fecha_recepcion || null,
        aplica_iva,
        observaciones: observaciones || null,
        detalles: validDetalles.map(d => ({
          articulo: d.articulo || null,
          linea: d.linea || null,
          modelo: d.modelo || null,
          color: d.color || null,
          talla: d.talla || null,
          unidad: d.unidad || null,
          cantidad: Number(d.cantidad) || 0,
          costo_unitario: Number(d.costo_unitario) || 0,
        })),
      };

      if (isEditing) {
        await api.updateCompraInsumo(editId, payload);
      } else {
        await api.createCompraInsumo(payload);
      }

      navigation.goBack();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (loadingData) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      <SectionHeader title="Datos Generales" />
      <View style={styles.card}>
        <Input
          label="Proveedor"
          value={proveedor_cliente}
          onChangeText={setProveedorCliente}
          placeholder="Nombre del proveedor"
        />
        <View style={styles.divider} />
        <Input
          label="Fecha de Recepción (YYYY-MM-DD)"
          value={fecha_recepcion}
          onChangeText={setFechaRecepcion}
          placeholder="2025-01-15"
        />
        <View style={styles.divider} />
        <Input
          label="Observaciones"
          value={observaciones}
          onChangeText={setObservaciones}
          placeholder="Observaciones"
          multiline
        />
        <View style={styles.divider} />
        <View style={styles.toggleRow}>
          <Text style={styles.toggleLabel}>Aplica IVA (16%)</Text>
          <Switch
            value={aplica_iva}
            onValueChange={setAplicaIva}
            trackColor={{ false: Colors.separator, true: Colors.primary + '80' }}
            thumbColor={aplica_iva ? Colors.primary : '#f4f3f4'}
          />
        </View>
      </View>

      <SectionHeader title="Detalles" />
      {detalles.map((det, index) => (
        <View key={index} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Línea {index + 1}</Text>
            {detalles.length > 1 && (
              <TouchableOpacity onPress={() => removeDetalle(index)}>
                <Ionicons name="trash-outline" size={20} color={Colors.error} />
              </TouchableOpacity>
            )}
          </View>
          <Input
            label="Artículo"
            value={det.articulo}
            onChangeText={(v) => updateDetalle(index, 'articulo', v)}
            placeholder="Artículo"
          />
          <View style={styles.divider} />
          <Input
            label="Línea"
            value={det.linea}
            onChangeText={(v) => updateDetalle(index, 'linea', v)}
            placeholder="Línea"
          />
          <View style={styles.divider} />
          <Input
            label="Modelo"
            value={det.modelo}
            onChangeText={(v) => updateDetalle(index, 'modelo', v)}
            placeholder="Modelo"
          />
          <View style={styles.divider} />
          <View style={styles.rowInputs}>
            <View style={styles.halfInput}>
              <Input
                label="Color"
                value={det.color}
                onChangeText={(v) => updateDetalle(index, 'color', v)}
                placeholder="Color"
              />
            </View>
            <View style={styles.halfInput}>
              <Input
                label="Talla"
                value={det.talla}
                onChangeText={(v) => updateDetalle(index, 'talla', v)}
                placeholder="Talla"
              />
            </View>
          </View>
          <View style={styles.divider} />
          <Input
            label="Unidad"
            value={det.unidad}
            onChangeText={(v) => updateDetalle(index, 'unidad', v)}
            placeholder="Unidad"
          />
          <View style={styles.divider} />
          <View style={styles.rowInputs}>
            <View style={styles.halfInput}>
              <Input
                label="Cantidad"
                value={det.cantidad}
                onChangeText={(v) => updateDetalle(index, 'cantidad', v)}
                placeholder="0"
                keyboardType="decimal-pad"
              />
            </View>
            <View style={styles.halfInput}>
              <Input
                label="Costo Unitario"
                value={det.costo_unitario}
                onChangeText={(v) => updateDetalle(index, 'costo_unitario', v)}
                placeholder="0.00"
                keyboardType="decimal-pad"
              />
            </View>
          </View>
          <View style={styles.lineTotal}>
            <Text style={styles.lineTotalLabel}>Importe:</Text>
            <Text style={styles.lineTotalValue}>
              {formatMX((Number(det.cantidad) || 0) * (Number(det.costo_unitario) || 0))}
            </Text>
          </View>
        </View>
      ))}

      <View style={styles.addBtnWrap}>
        <TouchableOpacity style={styles.addBtn} onPress={addDetalle}>
          <Ionicons name="add-circle-outline" size={22} color={Colors.primary} />
          <Text style={styles.addBtnText}>Agregar línea</Text>
        </TouchableOpacity>
      </View>

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMX(subtotal)}</Text>
        </View>
        {aplica_iva && (
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

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Compra'}
          onPress={handleSave}
          loading={loading}
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
  toggleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  toggleLabel: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  detalleHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  detalleTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  rowInputs: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  halfInput: {
    flex: 1,
  },
  lineTotal: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
    marginTop: Spacing.xs,
  },
  lineTotalLabel: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
  },
  lineTotalValue: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.primary,
  },
  addBtnWrap: {
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
  },
  addBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: Spacing.md,
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    borderColor: Colors.primary + '40',
    borderStyle: 'dashed',
  },
  addBtnText: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '500',
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
  error: {
    color: Colors.error,
    fontSize: FontSize.footnote,
    textAlign: 'center',
    marginTop: Spacing.md,
    paddingHorizontal: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
