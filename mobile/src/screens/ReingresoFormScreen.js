import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert, Switch,
  ActivityIndicator, TouchableOpacity
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';
import CatalogPicker from '../components/CatalogPicker';
import DatePicker from '../components/DatePicker';

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function todayStr() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

const EMPTY_DETALLE = { nombre: '', talla: '', unidad: '', cantidad: '', costo_unitario: '', es_servicio: false };

export default function ReingresoFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [motivo, setMotivo] = useState('');
  const [observaciones, setObservaciones] = useState('');
  const [fechaReingreso, setFechaReingreso] = useState(todayStr());
  const [clienteId, setClienteId] = useState('');
  const [clienteNombre, setClienteNombre] = useState('');
  const [detalles, setDetalles] = useState([{ ...EMPTY_DETALLE }]);

  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(!!editId);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isEditing) {
      loadData();
    }
  }, []);

  const loadData = async () => {
    setLoadingData(true);
    try {
      const data = await api.getReingreso(editId);
      setMotivo(data.motivo || '');
      setObservaciones(data.observaciones || '');
      setFechaReingreso(data.fecha_reingreso ? data.fecha_reingreso.substring(0, 10) : todayStr());
      setClienteId(data.cliente_id || '');
      setClienteNombre(data.cliente_nombre || '');
      if (data.detalles && data.detalles.length > 0) {
        setDetalles(data.detalles.map(d => ({
          nombre: d.nombre || '',
          talla: d.talla || '',
          unidad: d.unidad || '',
          cantidad: d.cantidad ? String(d.cantidad) : '',
          costo_unitario: d.costo_unitario ? String(d.costo_unitario) : '',
          es_servicio: !!d.es_servicio,
        })));
      }
    } catch (err) {
      setError(err.message || 'Error al cargar datos');
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar Reingreso' : 'Nuevo Reingreso',
    });
  }, [navigation, isEditing]);

  const addDetalle = () => {
    setDetalles([...detalles, { ...EMPTY_DETALLE }]);
  };

  const removeDetalle = (index) => {
    if (detalles.length <= 1) return;
    const updated = detalles.filter((_, i) => i !== index);
    setDetalles(updated);
  };

  const updateDetalle = (index, field, value) => {
    const updated = [...detalles];
    updated[index] = { ...updated[index], [field]: value };
    setDetalles(updated);
  };

  const totalMonto = detalles.reduce((sum, d) => {
    const cant = parseInt(d.cantidad) || 0;
    const costo = parseFloat(d.costo_unitario) || 0;
    return sum + (cant * costo);
  }, 0);

  const handleSave = async () => {
    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      if (!det.nombre.trim()) {
        setError(`El nombre del detalle ${i + 1} es requerido`);
        return;
      }
      const cantidad = parseInt(det.cantidad) || 0;
      if (cantidad <= 0) {
        setError(`La cantidad del detalle ${i + 1} debe ser mayor a 0`);
        return;
      }
      const costo = parseFloat(det.costo_unitario) || 0;
      if (costo < 0) {
        setError(`El costo unitario del detalle ${i + 1} no puede ser negativo`);
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        motivo: motivo || null,
        observaciones: observaciones || null,
        fecha_reingreso: fechaReingreso || null,
        cliente_id: clienteId || null,
        detalles: detalles.map(d => ({
          nombre: d.nombre,
          talla: d.talla || null,
          unidad: d.unidad || null,
          cantidad: parseInt(d.cantidad) || 0,
          costo_unitario: parseFloat(d.costo_unitario) || 0,
          es_servicio: d.es_servicio,
        })),
      };

      if (isEditing) {
        await api.updateReingreso(editId, data);
      } else {
        await api.createReingreso(data);
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
      <SectionHeader title="Información" />
      <View style={styles.card}>
        <Input
          label="Motivo"
          value={motivo}
          onChangeText={setMotivo}
          placeholder="Motivo del reingreso"
        />
        <View style={styles.divider} />
        <Input
          label="Observaciones"
          value={observaciones}
          onChangeText={setObservaciones}
          placeholder="Observaciones adicionales"
          multiline
        />
        <View style={styles.divider} />
        <DatePicker
          label="Fecha de Reingreso"
          value={fechaReingreso}
          onChange={setFechaReingreso}
          placeholder="Seleccionar fecha"
        />
        <View style={styles.divider} />
        <CatalogPicker
          label="Cliente (opcional)"
          catalogo="clientes"
          value={clienteId}
          displayValue={clienteNombre}
          displayField="nombre_comercial"
          placeholder="Seleccionar cliente..."
          allowCreate={false}
          onSelect={(item) => {
            if (item) {
              setClienteId(item.id);
              setClienteNombre(item.nombre_comercial || item.nombre || '');
            } else {
              setClienteId('');
              setClienteNombre('');
            }
          }}
        />
      </View>

      <SectionHeader title={`Detalles (${detalles.length})`} />
      {detalles.map((det, index) => (
        <View key={index} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Detalle {index + 1}</Text>
            {detalles.length > 1 && (
              <TouchableOpacity onPress={() => removeDetalle(index)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
              </TouchableOpacity>
            )}
          </View>
          <View style={styles.divider} />
          <Input
            label="Nombre *"
            value={det.nombre}
            onChangeText={(v) => updateDetalle(index, 'nombre', v)}
            placeholder="Nombre del artículo/servicio"
          />
          <View style={styles.divider} />
          <Input
            label="Talla"
            value={det.talla}
            onChangeText={(v) => updateDetalle(index, 'talla', v)}
            placeholder="Talla (opcional)"
          />
          <View style={styles.divider} />
          <Input
            label="Unidad"
            value={det.unidad}
            onChangeText={(v) => updateDetalle(index, 'unidad', v)}
            placeholder="PZ, KG, MT..."
          />
          <View style={styles.divider} />
          <Input
            label="Cantidad *"
            value={det.cantidad}
            onChangeText={(v) => updateDetalle(index, 'cantidad', v)}
            placeholder="0"
            keyboardType="number-pad"
          />
          <View style={styles.divider} />
          <Input
            label="Costo Unitario"
            value={det.costo_unitario}
            onChangeText={(v) => updateDetalle(index, 'costo_unitario', v)}
            placeholder="0.00"
            keyboardType="decimal-pad"
          />
          <View style={styles.divider} />
          <View style={styles.toggleRow}>
            <Text style={styles.toggleLabel}>Es servicio</Text>
            <Switch
              value={det.es_servicio}
              onValueChange={(v) => updateDetalle(index, 'es_servicio', v)}
              trackColor={{ false: Colors.separator, true: Colors.primary + '80' }}
              thumbColor={det.es_servicio ? Colors.primary : '#f4f3f4'}
            />
          </View>
          <View style={styles.divider} />
          <View style={styles.subtotalRow}>
            <Text style={styles.subtotalLabel}>Subtotal</Text>
            <Text style={styles.subtotalValue}>
              {formatMX((parseInt(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
            </Text>
          </View>
        </View>
      ))}

      <TouchableOpacity style={styles.addButton} onPress={addDetalle} activeOpacity={0.7}>
        <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
        <Text style={styles.addButtonText}>Agregar Detalle</Text>
      </TouchableOpacity>

      <SectionHeader title="Total" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>{formatMX(totalMonto)}</Text>
        </View>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Reingreso'}
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
  subtotalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  subtotalLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  subtotalValue: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    marginHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    gap: 6,
  },
  addButtonText: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '600',
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
