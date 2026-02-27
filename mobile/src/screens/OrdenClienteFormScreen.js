import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert, Switch,
  TouchableOpacity, ActivityIndicator, Platform
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

const EMPTY_DETALLE = {
  articulo: '',
  linea: '',
  modelo: '',
  color: '',
  talla: '',
  unidad: '',
  cantidad: '',
  precio_unitario: '',
};

export default function OrdenClienteFormScreen({ route, navigation }) {
  const { orden } = route.params || {};
  const isEditing = !!orden;

  const [clienteId, setClienteId] = useState(orden?.cliente_id || '');
  const [clienteNombre, setClienteNombre] = useState(orden?.cliente_nombre || '');
  const [agenteId, setAgenteId] = useState(orden?.agente_id || '');
  const [agenteNombre, setAgenteNombre] = useState(orden?.agente_nombre || '');
  const [numeroPedidoCliente, setNumeroPedidoCliente] = useState(orden?.numero_pedido_cliente || '');
  const [fechaEntrega, setFechaEntrega] = useState(orden?.fecha_entrega ? orden.fecha_entrega.split('T')[0] : '');
  const [aplicaIva, setAplicaIva] = useState(orden?.aplica_iva || false);
  const [detalles, setDetalles] = useState([{ ...EMPTY_DETALLE }]);

  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(!!isEditing);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isEditing && orden?.id) {
      loadData();
    }
  }, []);

  const loadData = async () => {
    setLoadingData(true);
    try {
      const full = await api.getOrdenCliente(orden.id);
      if (full.detalles && full.detalles.length > 0) {
        setDetalles(full.detalles.map(d => ({
          articulo: d.articulo || '',
          linea: d.linea || '',
          modelo: d.modelo || '',
          color: d.color || '',
          talla: d.talla || '',
          unidad: d.unidad || '',
          cantidad: String(d.cantidad || ''),
          precio_unitario: String(d.precio_unitario || ''),
        })));
      }
    } catch (err) {
      console.error('Error loading data:', err);
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? `Editar Orden #${orden?.numero_venta || ''}` : 'Nueva Orden',
    });
  }, [navigation, isEditing, orden]);

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

  const subtotal = detalles.reduce((sum, d) => {
    return sum + (parseFloat(d.cantidad) || 0) * (parseFloat(d.precio_unitario) || 0);
  }, 0);
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  const handleSave = async () => {
    const validDetalles = detalles.filter(d =>
      d.articulo.trim() || d.modelo.trim()
    );

    if (validDetalles.length === 0) {
      setError('Se requiere al menos un detalle con artículo o modelo');
      return;
    }

    for (const d of validDetalles) {
      if (!d.cantidad || parseFloat(d.cantidad) <= 0) {
        setError('Todos los detalles deben tener cantidad mayor a 0');
        return;
      }
      if (!d.precio_unitario || parseFloat(d.precio_unitario) <= 0) {
        setError('Todos los detalles deben tener precio unitario mayor a 0');
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        cliente_id: clienteId || null,
        cliente_nombre: clienteNombre || null,
        agente_id: agenteId || null,
        numero_pedido_cliente: numeroPedidoCliente || null,
        fecha_entrega: fechaEntrega || null,
        aplica_iva: aplicaIva,
        detalles: validDetalles.map(d => ({
          articulo: d.articulo || null,
          linea: d.linea || null,
          modelo: d.modelo || null,
          color: d.color || null,
          talla: d.talla || null,
          unidad: d.unidad || null,
          cantidad: parseInt(d.cantidad) || 0,
          precio_unitario: parseFloat(d.precio_unitario) || 0,
        })),
      };

      if (isEditing) {
        await api.updateOrdenCliente(orden.id, data);
      } else {
        await api.createOrdenCliente(data);
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
      <SectionHeader title="Cliente" />
      <View style={styles.card}>
        <CatalogPicker
          label="Seleccionar Cliente"
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
      </View>

      <SectionHeader title="Agente" />
      <View style={styles.card}>
        <CatalogPicker
          label="Seleccionar Agente"
          catalogo="agentes"
          value={agenteId}
          displayValue={agenteNombre}
          displayField="nombre"
          secondaryField="apellido"
          placeholder="Sin agente"
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
      </View>

      <SectionHeader title="Datos de la Orden" />
      <View style={styles.card}>
        <Input
          label="No. Pedido del Cliente"
          value={numeroPedidoCliente}
          onChangeText={setNumeroPedidoCliente}
          placeholder="Referencia del cliente"
        />
        <View style={styles.divider} />
        <DatePicker
          label="Fecha de Entrega"
          value={fechaEntrega}
          onChange={setFechaEntrega}
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
      </View>

      <SectionHeader title="Detalles del Pedido" />
      {detalles.map((det, index) => (
        <View key={index} style={styles.card}>
          <View style={styles.detalleHeader}>
            <Text style={styles.detalleTitle}>Línea {index + 1}</Text>
            {detalles.length > 1 && (
              <TouchableOpacity onPress={() => removeDetalle(index)}>
                <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
              </TouchableOpacity>
            )}
          </View>
          <CatalogPicker
            label="Artículo"
            catalogo="articulos"
            displayValue={det.articulo}
            displayField="nombre"
            placeholder="Seleccionar artículo"
            onSelect={(item) => {
              updateDetalle(index, 'articulo', item ? item.nombre : '');
            }}
          />
          <View style={styles.row}>
            <View style={styles.halfField}>
              <CatalogPicker
                label="Modelo"
                catalogo="modelos"
                displayValue={det.modelo}
                displayField="nombre"
                placeholder="Modelo"
                onSelect={(item) => {
                  updateDetalle(index, 'modelo', item ? item.nombre : '');
                }}
              />
            </View>
            <View style={styles.halfField}>
              <CatalogPicker
                label="Línea"
                catalogo="lineas"
                displayValue={det.linea}
                displayField="nombre"
                placeholder="Línea"
                onSelect={(item) => {
                  updateDetalle(index, 'linea', item ? item.nombre : '');
                }}
              />
            </View>
          </View>
          <View style={styles.row}>
            <View style={styles.halfField}>
              <CatalogPicker
                label="Color"
                catalogo="colores"
                displayValue={det.color}
                displayField="nombre"
                placeholder="Color"
                onSelect={(item) => {
                  updateDetalle(index, 'color', item ? item.nombre : '');
                }}
              />
            </View>
            <View style={styles.halfField}>
              <CatalogPicker
                label="Talla"
                catalogo="tallas"
                displayValue={det.talla}
                displayField="nombre"
                placeholder="Talla"
                onSelect={(item) => {
                  updateDetalle(index, 'talla', item ? item.nombre : '');
                }}
              />
            </View>
          </View>
          <View style={styles.row}>
            <View style={styles.halfField}>
              <CatalogPicker
                label="Unidad"
                catalogo="unidades"
                displayValue={det.unidad}
                displayField="nombre"
                placeholder="Pza, Kg..."
                onSelect={(item) => {
                  updateDetalle(index, 'unidad', item ? item.nombre : '');
                }}
              />
            </View>
            <View style={styles.halfField}>
              <Input
                label="Cantidad *"
                value={det.cantidad}
                onChangeText={(v) => updateDetalle(index, 'cantidad', v)}
                placeholder="0"
                keyboardType="number-pad"
              />
            </View>
          </View>
          <Input
            label="Precio Unitario *"
            value={det.precio_unitario}
            onChangeText={(v) => updateDetalle(index, 'precio_unitario', v)}
            placeholder="0.00"
            keyboardType="decimal-pad"
          />
          <View style={styles.lineTotal}>
            <Text style={styles.lineTotalLabel}>Importe:</Text>
            <Text style={styles.lineTotalValue}>
              {formatMX((parseFloat(det.cantidad) || 0) * (parseFloat(det.precio_unitario) || 0))}
            </Text>
          </View>
        </View>
      ))}

      <View style={styles.addButtonContainer}>
        <TouchableOpacity style={styles.addButton} onPress={addDetalle}>
          <Ionicons name="add-circle-outline" size={22} color={Colors.primary} />
          <Text style={styles.addButtonText}>Agregar Línea</Text>
        </TouchableOpacity>
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
          <Text style={styles.summaryValue}>{formatMX(iva)}</Text>
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
          title={isEditing ? 'Guardar Cambios' : 'Crear Orden'}
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
    borderTopWidth: 1,
    borderTopColor: Colors.separator,
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
  },
  addButtonText: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '600',
    marginLeft: Spacing.sm,
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
