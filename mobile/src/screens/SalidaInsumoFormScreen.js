import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator, TouchableOpacity
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';
import DatePicker from '../components/DatePicker';

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

const emptyDetalle = () => ({
  key: Date.now() + Math.random(),
  articulo: '',
  modelo: '',
  cantidad: '',
  costo_unitario: '',
  unidad: '',
});

export default function SalidaInsumoFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [destino, setDestino] = useState('');
  const [observaciones, setObservaciones] = useState('');
  const [fechaSalida, setFechaSalida] = useState('');
  const [detalles, setDetalles] = useState([emptyDetalle()]);

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
      const data = await api.getSalidaInsumo(editId);
      setDestino(data.destino || '');
      setObservaciones(data.observaciones || '');
      if (data.fecha_salida) {
        const d = new Date(data.fecha_salida);
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        setFechaSalida(`${y}-${m}-${day}`);
      }
      if (data.detalles && data.detalles.length > 0) {
        setDetalles(data.detalles.map(det => ({
          key: det.id || Date.now() + Math.random(),
          articulo: det.articulo || '',
          modelo: det.modelo || '',
          cantidad: det.cantidad ? String(det.cantidad) : '',
          costo_unitario: det.costo_unitario ? String(det.costo_unitario) : '',
          unidad: det.unidad || '',
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
      title: isEditing ? 'Editar Salida' : 'Nueva Salida',
    });
  }, [navigation, isEditing]);

  const updateDetalle = (index, field, value) => {
    setDetalles(prev => {
      const updated = [...prev];
      updated[index] = { ...updated[index], [field]: value };
      return updated;
    });
  };

  const addDetalle = () => {
    setDetalles(prev => [...prev, emptyDetalle()]);
  };

  const removeDetalle = (index) => {
    if (detalles.length <= 1) {
      Alert.alert('Aviso', 'Se requiere al menos un detalle');
      return;
    }
    setDetalles(prev => prev.filter((_, i) => i !== index));
  };

  const totalMonto = detalles.reduce((sum, det) => {
    const cantidad = parseInt(det.cantidad) || 0;
    const costoUnitario = parseFloat(det.costo_unitario) || 0;
    return sum + (cantidad * costoUnitario);
  }, 0);

  const handleSave = async () => {
    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      const cantidad = parseInt(det.cantidad) || 0;
      const costoUnitario = parseFloat(det.costo_unitario) || 0;
      if (cantidad <= 0) {
        setError(`La cantidad del detalle ${i + 1} debe ser mayor a 0`);
        return;
      }
      if (costoUnitario < 0) {
        setError(`El costo unitario del detalle ${i + 1} no puede ser negativo`);
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        destino: destino.trim() || null,
        observaciones: observaciones.trim() || null,
        fecha_salida: fechaSalida || null,
        detalles: detalles.map(det => ({
          articulo: det.articulo.trim() || null,
          modelo: det.modelo.trim() || null,
          cantidad: parseInt(det.cantidad) || 0,
          costo_unitario: parseFloat(det.costo_unitario) || 0,
          unidad: det.unidad.trim() || null,
        })),
      };

      if (isEditing) {
        await api.updateSalidaInsumo(editId, data);
      } else {
        await api.createSalidaInsumo(data);
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
          label="Destino"
          value={destino}
          onChangeText={setDestino}
          placeholder="Destino de la salida"
        />
        <View style={styles.divider} />
        <DatePicker
          label="Fecha de Salida"
          value={fechaSalida}
          onChange={setFechaSalida}
          placeholder="Seleccionar fecha"
        />
        <View style={styles.divider} />
        <Input
          label="Observaciones"
          value={observaciones}
          onChangeText={setObservaciones}
          placeholder="Observaciones (opcional)"
          multiline
        />
      </View>

      <SectionHeader title={`Detalles (${detalles.length})`} />
      {detalles.map((det, index) => (
        <View key={det.key} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Detalle {index + 1}</Text>
            <TouchableOpacity onPress={() => removeDetalle(index)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
            </TouchableOpacity>
          </View>
          <View style={styles.divider} />
          <Input
            label="Artículo"
            value={det.articulo}
            onChangeText={(val) => updateDetalle(index, 'articulo', val)}
            placeholder="Nombre del artículo"
          />
          <View style={styles.divider} />
          <Input
            label="Modelo"
            value={det.modelo}
            onChangeText={(val) => updateDetalle(index, 'modelo', val)}
            placeholder="Modelo (opcional)"
          />
          <View style={styles.divider} />
          <Input
            label="Cantidad *"
            value={det.cantidad}
            onChangeText={(val) => updateDetalle(index, 'cantidad', val)}
            placeholder="0"
            keyboardType="number-pad"
          />
          <View style={styles.divider} />
          <Input
            label="Costo Unitario"
            value={det.costo_unitario}
            onChangeText={(val) => updateDetalle(index, 'costo_unitario', val)}
            placeholder="0.00"
            keyboardType="decimal-pad"
          />
          <View style={styles.divider} />
          <Input
            label="Unidad"
            value={det.unidad}
            onChangeText={(val) => updateDetalle(index, 'unidad', val)}
            placeholder="PZ, MT, KG..."
          />
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

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>{formatMX(totalMonto)}</Text>
        </View>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Salida'}
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
    color: Colors.text,
    fontWeight: '500',
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
    gap: Spacing.xs,
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
