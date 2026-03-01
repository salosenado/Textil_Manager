import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert, Switch,
  ActivityIndicator
} from 'react-native';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';
import CatalogPicker from '../components/CatalogPicker';

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export default function ProduccionFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [maquileroId, setMaquileroId] = useState('');
  const [maquileroNombre, setMaquileroNombre] = useState('');
  const [pzCortadas, setPzCortadas] = useState('');
  const [costoMaquila, setCostoMaquila] = useState('');
  const [aplicaIva, setAplicaIva] = useState(false);
  const [cancelada, setCancelada] = useState(false);
  const [detalleOrdenInfo, setDetalleOrdenInfo] = useState(null);

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
      const data = await api.getProduccion(editId);
      setMaquileroId(data.maquilero_id || '');
      setMaquileroNombre(data.maquilero_nombre || '');
      setPzCortadas(data.pz_cortadas ? String(data.pz_cortadas) : '');
      setCostoMaquila(data.costo_maquila ? String(data.costo_maquila) : '');
      setCancelada(!!data.cancelada);
      if (data.detalle_orden) {
        setDetalleOrdenInfo(data.detalle_orden);
        setAplicaIva(!!data.detalle_orden.aplica_iva);
      }
    } catch (err) {
      setError(err.message || 'Error al cargar datos');
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar Producción' : 'Nueva Producción',
    });
  }, [navigation, isEditing]);

  const pzNum = parseInt(pzCortadas) || 0;
  const costoNum = parseFloat(costoMaquila) || 0;
  const subtotal = pzNum * costoNum;
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;

  const handleSave = async () => {
    if (!maquileroNombre.trim()) {
      setError('Se requiere seleccionar un maquilero');
      return;
    }
    if (pzNum <= 0) {
      setError('Las piezas cortadas deben ser mayor a 0');
      return;
    }
    if (costoNum < 0) {
      setError('El costo de maquila no puede ser negativo');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        maquilero_id: maquileroId || null,
        maquilero_nombre: maquileroNombre,
        pz_cortadas: pzNum || null,
        costo_maquila: costoNum || null,
      };

      if (isEditing) {
        await api.updateProduccion(editId, data);
      } else {
        await api.createProduccion(data);
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
      {cancelada && (
        <View style={styles.cancelledBanner}>
          <Text style={styles.cancelledText}>Esta producción está cancelada</Text>
        </View>
      )}

      <SectionHeader title="Maquilero" />
      <View style={styles.card}>
        <CatalogPicker
          label="Seleccionar Maquilero"
          catalogo="maquileros"
          value={maquileroId}
          displayValue={maquileroNombre}
          displayField="nombre"
          placeholder="Seleccionar maquilero..."
          onSelect={(item) => {
            if (item) {
              setMaquileroId(item.id);
              setMaquileroNombre(item.nombre || '');
            } else {
              setMaquileroId('');
              setMaquileroNombre('');
            }
          }}
        />
      </View>

      <SectionHeader title="Producción" />
      <View style={styles.card}>
        <Input
          label="Piezas Cortadas"
          value={pzCortadas}
          onChangeText={setPzCortadas}
          placeholder="0"
          keyboardType="number-pad"
          editable={!cancelada}
        />
        <View style={styles.divider} />
        <Input
          label="Costo Maquila (por pieza)"
          value={costoMaquila}
          onChangeText={setCostoMaquila}
          placeholder="0.00"
          keyboardType="decimal-pad"
          editable={!cancelada}
        />
      </View>

      <SectionHeader title="Orden de Cliente" />
      <View style={styles.card}>
        {detalleOrdenInfo ? (
          <View>
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Artículo</Text>
              <Text style={styles.infoValue}>{detalleOrdenInfo.articulo || '-'}</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Modelo</Text>
              <Text style={styles.infoValue}>{detalleOrdenInfo.modelo || '-'}</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.infoRow}>
              <Text style={styles.infoLabel}>Cliente</Text>
              <Text style={styles.infoValue}>{detalleOrdenInfo.cliente_nombre || '-'}</Text>
            </View>
          </View>
        ) : (
          <Text style={styles.optionalNote}>Opcional — se puede vincular después</Text>
        )}
      </View>

      <SectionHeader title="Cálculos" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal</Text>
          <Text style={styles.summaryValue}>{formatMX(subtotal)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.toggleRow}>
          <Text style={styles.toggleLabel}>Aplica IVA (16%)</Text>
          <Switch
            value={aplicaIva}
            onValueChange={setAplicaIva}
            trackColor={{ false: Colors.separator, true: Colors.primary + '80' }}
            thumbColor={aplicaIva ? Colors.primary : '#f4f3f4'}
            disabled={cancelada}
          />
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

      {!cancelada && (
        <View style={styles.buttonContainer}>
          <Button
            title={isEditing ? 'Guardar Cambios' : 'Crear Producción'}
            onPress={handleSave}
            loading={loading}
          />
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
  cancelledBanner: {
    backgroundColor: Colors.destructive + '15',
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.lg,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: BorderRadius.sm,
    borderLeftWidth: 4,
    borderLeftColor: Colors.destructive,
  },
  cancelledText: {
    color: Colors.destructive,
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
  optionalNote: {
    fontSize: FontSize.footnote,
    color: Colors.textTertiary,
    fontStyle: 'italic',
    paddingVertical: Spacing.md,
    textAlign: 'center',
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
