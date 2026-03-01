import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert, Switch,
  TouchableOpacity, ActivityIndicator
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

const emptyArticulo = () => ({
  key: Date.now() + Math.random(),
  modelo_nombre: '',
  cantidad: '',
  costo_unitario: '',
  unidad: '',
});

export default function VentaClienteFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [clienteId, setClienteId] = useState('');
  const [clienteNombre, setClienteNombre] = useState('');
  const [agenteId, setAgenteId] = useState('');
  const [agenteNombre, setAgenteNombre] = useState('');
  const [fechaEntrega, setFechaEntrega] = useState('');
  const [numeroFactura, setNumeroFactura] = useState('');
  const [aplicaIva, setAplicaIva] = useState(false);
  const [observaciones, setObservaciones] = useState('');
  const [detalles, setDetalles] = useState([emptyArticulo()]);

  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(!!editId);
  const [error, setError] = useState('');
  const [blocked, setBlocked] = useState(false);

  useEffect(() => {
    if (isEditing) {
      loadData();
    }
  }, []);

  const loadData = async () => {
    setLoadingData(true);
    try {
      const data = await api.getVentaCliente(editId);
      if (data.cancelada || data.mercancia_enviada) {
        setBlocked(true);
      }
      setClienteId(data.cliente_id || '');
      setClienteNombre(data.cliente_nombre || '');
      setAgenteId(data.agente_id || '');
      setAgenteNombre(data.agente_nombre || '');
      setNumeroFactura(data.numero_factura || '');
      setAplicaIva(data.aplica_iva || false);
      setObservaciones(data.observaciones || '');
      if (data.fecha_entrega) {
        const d = new Date(data.fecha_entrega);
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        setFechaEntrega(`${y}-${m}-${day}`);
      }
      if (data.detalles && data.detalles.length > 0) {
        setDetalles(data.detalles.map(det => ({
          key: det.id || Date.now() + Math.random(),
          modelo_nombre: det.modelo_nombre || '',
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
      title: isEditing ? 'Editar Venta' : 'Nueva Venta',
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
    setDetalles(prev => [...prev, emptyArticulo()]);
  };

  const removeDetalle = (index) => {
    if (detalles.length <= 1) {
      Alert.alert('Aviso', 'Se requiere al menos un artículo');
      return;
    }
    setDetalles(prev => prev.filter((_, i) => i !== index));
  };

  const subtotal = detalles.reduce((sum, det) => {
    const cantidad = parseInt(det.cantidad) || 0;
    const costoUnitario = parseFloat(det.costo_unitario) || 0;
    return sum + (cantidad * costoUnitario);
  }, 0);
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  const handleSave = async () => {
    if (!clienteId) {
      setError('Debe seleccionar un cliente');
      return;
    }

    if (detalles.length === 0) {
      setError('Se requiere al menos un artículo');
      return;
    }

    for (let i = 0; i < detalles.length; i++) {
      const det = detalles[i];
      const cantidad = parseInt(det.cantidad) || 0;
      const costoUnitario = parseFloat(det.costo_unitario) || 0;
      if (cantidad <= 0) {
        setError(`La cantidad del artículo ${i + 1} debe ser mayor a 0`);
        return;
      }
      if (costoUnitario < 0) {
        setError(`El costo unitario del artículo ${i + 1} no puede ser negativo`);
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        cliente_id: clienteId || null,
        agente_id: agenteId || null,
        fecha_entrega: fechaEntrega || null,
        numero_factura: numeroFactura.trim() || null,
        aplica_iva: aplicaIva,
        observaciones: observaciones.trim() || null,
        detalles: detalles.map(det => ({
          modelo_nombre: det.modelo_nombre.trim() || null,
          cantidad: parseInt(det.cantidad) || 0,
          costo_unitario: parseFloat(det.costo_unitario) || 0,
          unidad: det.unidad.trim() || null,
        })),
      };

      if (isEditing) {
        await api.updateVentaCliente(editId, data);
      } else {
        await api.createVentaCliente(data);
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

  if (blocked) {
    return (
      <View style={styles.centered}>
        <Ionicons name="lock-closed-outline" size={48} color={Colors.textTertiary} />
        <Text style={styles.blockedText}>Esta venta no puede ser editada</Text>
        <Text style={styles.blockedSubtext}>La venta está cancelada o la mercancía ya fue enviada</Text>
        <Button title="Volver" onPress={() => navigation.goBack()} variant="secondary" style={{ marginTop: Spacing.lg }} />
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      <SectionHeader title="Información General" />
      <View style={styles.card}>
        <CatalogPicker
          label="Cliente *"
          catalogo="clientes"
          value={clienteId}
          displayValue={clienteNombre}
          displayField="nombre_comercial"
          placeholder="Seleccionar cliente..."
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
        <View style={styles.divider} />
        <CatalogPicker
          label="Agente"
          catalogo="agentes"
          value={agenteId}
          displayValue={agenteNombre}
          displayField="nombre"
          secondaryField="apellido"
          placeholder="Sin agente (opcional)"
          onSelect={(item) => {
            if (item) {
              setAgenteId(item.id);
              setAgenteNombre(`${item.nombre || ''}${item.apellido ? ' ' + item.apellido : ''}`);
            } else {
              setAgenteId('');
              setAgenteNombre('');
            }
          }}
        />
        <View style={styles.divider} />
        <DatePicker
          label="Fecha de Entrega"
          value={fechaEntrega}
          onChange={setFechaEntrega}
          placeholder="Seleccionar fecha"
        />
        <View style={styles.divider} />
        <Input
          label="Número de Factura"
          value={numeroFactura}
          onChangeText={setNumeroFactura}
          placeholder="Número de factura (opcional)"
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
      </View>

      <SectionHeader title={`Artículos (${detalles.length})`} />
      {detalles.map((det, index) => (
        <View key={det.key} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Artículo {index + 1}</Text>
            <TouchableOpacity onPress={() => removeDetalle(index)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
            </TouchableOpacity>
          </View>
          <View style={styles.divider} />
          <Input
            label="Modelo / Nombre"
            value={det.modelo_nombre}
            onChangeText={(val) => updateDetalle(index, 'modelo_nombre', val)}
            placeholder="Nombre del artículo"
          />
          <View style={styles.divider} />
          <View style={styles.row}>
            <View style={styles.halfField}>
              <Input
                label="Cantidad *"
                value={det.cantidad}
                onChangeText={(val) => updateDetalle(index, 'cantidad', val)}
                placeholder="0"
                keyboardType="number-pad"
              />
            </View>
            <View style={styles.halfField}>
              <Input
                label="Costo Unitario *"
                value={det.costo_unitario}
                onChangeText={(val) => updateDetalle(index, 'costo_unitario', val)}
                placeholder="0.00"
                keyboardType="decimal-pad"
              />
            </View>
          </View>
          <View style={styles.divider} />
          <Input
            label="Unidad"
            value={det.unidad}
            onChangeText={(val) => updateDetalle(index, 'unidad', val)}
            placeholder="PZ, MT, KG..."
          />
          <View style={styles.divider} />
          <View style={styles.lineTotal}>
            <Text style={styles.lineTotalLabel}>Subtotal</Text>
            <Text style={styles.lineTotalValue}>
              {formatMX((parseInt(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
            </Text>
          </View>
        </View>
      ))}

      <View style={styles.addButtonContainer}>
        <TouchableOpacity style={styles.addButton} onPress={addDetalle} activeOpacity={0.7}>
          <Ionicons name="add-circle-outline" size={22} color={Colors.primary} />
          <Text style={styles.addButtonText}>Agregar Artículo</Text>
        </TouchableOpacity>
      </View>

      <SectionHeader title="Observaciones" />
      <View style={styles.card}>
        <Input
          label="Observaciones"
          value={observaciones}
          onChangeText={setObservaciones}
          placeholder="Observaciones (opcional)"
          multiline
        />
      </View>

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMX(subtotal)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>IVA (16%)</Text>
          <Text style={styles.summaryValue}>{aplicaIva ? formatMX(iva) : '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.totalLabel}>Total</Text>
          <Text style={styles.totalValue}>{formatMX(total)}</Text>
        </View>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Venta'}
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
    paddingHorizontal: Spacing.xl,
  },
  blockedText: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
    marginTop: Spacing.lg,
    textAlign: 'center',
  },
  blockedSubtext: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.sm,
    textAlign: 'center',
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
    paddingVertical: Spacing.sm,
  },
  detalleTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  row: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  halfField: {
    flex: 1,
  },
  lineTotal: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
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
  addButtonContainer: {
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    borderWidth: 1,
    borderColor: Colors.primary,
    borderStyle: 'dashed',
    gap: Spacing.sm,
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
