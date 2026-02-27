import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Switch, TouchableOpacity, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';
import CatalogPicker from '../components/CatalogPicker';
import DatePicker from '../components/DatePicker';

function formatMoney(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

const EMPTY_DETALLE = { articulo: '', modelo: '', modelo_id: null, cantidad: '', costo_unitario: '' };

export default function CompraClienteFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [proveedorNombre, setProveedorNombre] = useState('');
  const [proveedorId, setProveedorId] = useState(null);
  const [fechaRecepcion, setFechaRecepcion] = useState('');
  const [aplicaIva, setAplicaIva] = useState(false);
  const [observaciones, setObservaciones] = useState('');
  const [detalles, setDetalles] = useState([{ ...EMPTY_DETALLE }]);
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isEditing) return;
    const loadData = async () => {
      setLoadingData(true);
      try {
        const orden = await api.getOrdenCompra(editId);
        setProveedorNombre(orden.proveedor_nombre || '');
        setProveedorId(orden.proveedor_id || null);
        setFechaRecepcion(orden.fecha_recepcion ? orden.fecha_recepcion.split('T')[0] : '');
        setAplicaIva(orden.aplica_iva || false);
        setObservaciones(orden.observaciones || '');
        if (orden.detalles && orden.detalles.length > 0) {
          setDetalles(orden.detalles.map(d => ({
            articulo: d.articulo || '',
            modelo: d.modelo || '',
            modelo_id: d.modelo_id || null,
            cantidad: d.cantidad != null ? String(d.cantidad) : '',
            costo_unitario: d.costo_unitario != null ? String(d.costo_unitario) : '',
          })));
        }
      } catch (err) {
        console.error('Error loading data:', err);
      } finally {
        setLoadingData(false);
      }
    };
    loadData();
  }, []);

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar OC' : 'Nueva Orden de Compra',
    });
  }, [navigation, isEditing]);

  const updateDetalle = (index, key, value) => {
    setDetalles(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [key]: value };
      return updated;
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
      const cant = parseFloat(d.cantidad) || 0;
      const precio = parseFloat(d.costo_unitario) || 0;
      return sum + (cant * precio);
    }, 0);
  };

  const subtotal = calcSubtotal();
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  const handleSave = async () => {
    const validDetalles = detalles.filter(d => d.articulo || d.modelo || d.cantidad);
    if (validDetalles.length === 0) {
      setError('Agrega al menos un detalle');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        proveedor_id: proveedorId || null,
        proveedor_nombre: proveedorNombre || null,
        fecha_recepcion: fechaRecepcion || null,
        aplica_iva: aplicaIva,
        observaciones: observaciones || null,
        detalles: validDetalles.map(d => ({
          articulo: d.articulo || null,
          modelo: d.modelo || null,
          modelo_id: d.modelo_id || null,
          cantidad: parseFloat(d.cantidad) || 0,
          costo_unitario: parseFloat(d.costo_unitario) || 0,
        })),
      };

      if (isEditing) {
        await api.updateOrdenCompra(editId, data);
      } else {
        await api.createOrdenCompra(data);
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
      <SectionHeader title="Proveedor" />
      <View style={styles.card}>
        <CatalogPicker
          label="Proveedor"
          catalogo="proveedores"
          value={proveedorId}
          displayValue={proveedorNombre || undefined}
          displayField="nombre"
          placeholder="Seleccionar proveedor"
          onSelect={(item) => {
            if (item) {
              setProveedorId(item.id);
              setProveedorNombre(item.nombre);
            } else {
              setProveedorId(null);
              setProveedorNombre('');
            }
          }}
        />
      </View>

      <SectionHeader title="Datos de la Orden" />
      <View style={styles.card}>
        <DatePicker
          label="Fecha de Recepción"
          value={fechaRecepcion}
          onChange={setFechaRecepcion}
          placeholder="Seleccionar fecha"
        />
        <View style={styles.divider} />
        <View style={styles.toggleRow}>
          <Text style={styles.toggleLabel}>Aplica IVA (16%)</Text>
          <Switch
            value={aplicaIva}
            onValueChange={setAplicaIva}
            trackColor={{ false: Colors.separator, true: Colors.primary + '80' }}
            thumbColor={aplicaIva ? Colors.primary : '#f4f3f4'}
          />
        </View>
        <View style={styles.divider} />
        <Input
          label="Observaciones"
          value={observaciones}
          onChangeText={setObservaciones}
          placeholder="Notas adicionales"
          multiline
        />
      </View>

      <SectionHeader title="Detalles" />
      {detalles.map((det, index) => (
        <View key={index} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Artículo {index + 1}</Text>
            {detalles.length > 1 && (
              <TouchableOpacity onPress={() => removeDetalle(index)}>
                <Ionicons name="trash-outline" size={20} color={Colors.error} />
              </TouchableOpacity>
            )}
          </View>
          <CatalogPicker
            label="Artículo"
            catalogo="articulos"
            displayValue={det.articulo || undefined}
            displayField="nombre"
            placeholder="Seleccionar artículo"
            onSelect={(item) => {
              if (item) {
                updateDetalle(index, 'articulo', item.nombre);
              } else {
                updateDetalle(index, 'articulo', '');
              }
            }}
          />
          <CatalogPicker
            label="Modelo"
            catalogo="modelos"
            displayValue={det.modelo || undefined}
            displayField="nombre"
            placeholder="Seleccionar modelo"
            onSelect={(item) => {
              if (item) {
                updateDetalle(index, 'modelo', item.nombre);
                updateDetalle(index, 'modelo_id', item.id);
              } else {
                updateDetalle(index, 'modelo', '');
                updateDetalle(index, 'modelo_id', null);
              }
            }}
          />
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
          <Text style={styles.lineTotal}>
            Importe: {formatMoney((parseFloat(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
          </Text>
        </View>
      ))}

      <TouchableOpacity style={styles.addButton} onPress={addDetalle}>
        <Ionicons name="add-circle-outline" size={22} color={Colors.primary} />
        <Text style={styles.addButtonText}>Agregar Artículo</Text>
      </TouchableOpacity>

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMoney(subtotal)}</Text>
        </View>
        {aplicaIva && (
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

      {error ? (
        <Text style={styles.error}>{error}</Text>
      ) : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Orden de Compra'}
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
    marginBottom: Spacing.xs,
    paddingTop: Spacing.xs,
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
    fontSize: FontSize.footnote,
    color: Colors.primary,
    textAlign: 'right',
    marginBottom: Spacing.xs,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    gap: 6,
  },
  addButtonText: {
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
