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
import CatalogPicker from '../components/CatalogPicker';
import DatePicker from '../components/DatePicker';

const INSUMOS_PREDETERMINADOS = [
  'ESTAMPADO', 'BORDADO', 'MAQUILA', 'BROCHE', 'ELÁSTICO',
  'ETIQUETA', 'HILO', 'CIERRE', 'BOTÓN', 'REMACHE',
];

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

export default function CostoGeneralFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [modelo, setModelo] = useState('');
  const [tallas, setTallas] = useState('');
  const [descripcion, setDescripcion] = useState('');
  const [departamentoId, setDepartamentoId] = useState('');
  const [departamentoNombre, setDepartamentoNombre] = useState('');
  const [lineaId, setLineaId] = useState('');
  const [lineaNombre, setLineaNombre] = useState('');
  const [fecha, setFecha] = useState('');

  const [telas, setTelas] = useState([]);
  const [insumos, setInsumos] = useState([]);

  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(!!editId);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isEditing) loadData();
  }, []);

  const loadData = async () => {
    setLoadingData(true);
    try {
      const data = await api.getCostoGeneral(editId);
      setModelo(data.modelo || '');
      setTallas(data.tallas || '');
      setDescripcion(data.descripcion || '');
      setDepartamentoId(data.departamento_id || '');
      setDepartamentoNombre(data.departamento_nombre || '');
      setLineaId(data.linea_id || '');
      setLineaNombre(data.linea_nombre || '');
      if (data.fecha) {
        const d = new Date(data.fecha);
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        setFecha(`${y}-${m}-${day}`);
      }
      setTelas((data.telas || []).map(t => ({
        nombre: t.nombre || '',
        consumo: String(t.consumo || ''),
        precio_unitario: String(t.precio_unitario || ''),
      })));
      setInsumos((data.insumos || []).map(i => ({
        nombre: i.nombre || '',
        cantidad: String(i.cantidad || ''),
        costo_unitario: String(i.costo_unitario || ''),
      })));
    } catch (err) {
      setError(err.message || 'Error al cargar datos');
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar Costo General' : 'Nuevo Costo General',
    });
  }, [navigation, isEditing]);

  const addTela = () => {
    setTelas([...telas, { nombre: '', consumo: '', precio_unitario: '' }]);
  };

  const removeTela = (index) => {
    setTelas(telas.filter((_, i) => i !== index));
  };

  const updateTela = (index, field, value) => {
    const updated = [...telas];
    updated[index] = { ...updated[index], [field]: value };
    setTelas(updated);
  };

  const addInsumo = (nombre) => {
    setInsumos([...insumos, { nombre: nombre || '', cantidad: '', costo_unitario: '' }]);
  };

  const removeInsumo = (index) => {
    setInsumos(insumos.filter((_, i) => i !== index));
  };

  const updateInsumo = (index, field, value) => {
    const updated = [...insumos];
    updated[index] = { ...updated[index], [field]: value };
    setInsumos(updated);
  };

  const totalTelas = telas.reduce((sum, t) => {
    return sum + ((parseFloat(t.consumo) || 0) * (parseFloat(t.precio_unitario) || 0));
  }, 0);

  const totalInsumos = insumos.reduce((sum, i) => {
    return sum + ((parseFloat(i.cantidad) || 0) * (parseFloat(i.costo_unitario) || 0));
  }, 0);

  const total = totalTelas + totalInsumos;
  const gastos = total * 0.15;
  const totalConGastos = total * 1.15;

  const handleSave = async () => {
    for (const t of telas) {
      if ((parseFloat(t.consumo) || 0) <= 0 || (parseFloat(t.precio_unitario) || 0) <= 0) {
        setError('El consumo y precio unitario de telas deben ser mayores a 0');
        return;
      }
    }
    for (const i of insumos) {
      if ((parseFloat(i.cantidad) || 0) <= 0 || (parseFloat(i.costo_unitario) || 0) <= 0) {
        setError('La cantidad y costo unitario de insumos deben ser mayores a 0');
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        modelo: modelo || null,
        tallas: tallas || null,
        descripcion: descripcion || null,
        departamento_id: departamentoId || null,
        linea_id: lineaId || null,
        fecha: fecha || null,
        telas: telas.map(t => ({
          nombre: t.nombre,
          consumo: parseFloat(t.consumo) || 0,
          precio_unitario: parseFloat(t.precio_unitario) || 0,
        })),
        insumos: insumos.map(i => ({
          nombre: i.nombre,
          cantidad: parseFloat(i.cantidad) || 0,
          costo_unitario: parseFloat(i.costo_unitario) || 0,
        })),
      };

      if (isEditing) {
        await api.updateCostoGeneral(editId, data);
      } else {
        await api.createCostoGeneral(data);
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
          label="Modelo"
          value={modelo}
          onChangeText={setModelo}
          placeholder="Nombre del modelo"
          autoCapitalize="characters"
        />
        <View style={styles.divider} />
        <Input
          label="Tallas"
          value={tallas}
          onChangeText={setTallas}
          placeholder="Ej: S, M, L, XL"
        />
        <View style={styles.divider} />
        <Input
          label="Descripción"
          value={descripcion}
          onChangeText={setDescripcion}
          placeholder="Descripción del costo"
          multiline
        />
        <View style={styles.divider} />
        <CatalogPicker
          label="Departamento"
          catalogo="departamentos"
          value={departamentoId}
          displayValue={departamentoNombre}
          displayField="nombre"
          placeholder="Seleccionar departamento..."
          onSelect={(item) => {
            if (item) {
              setDepartamentoId(item.id);
              setDepartamentoNombre(item.nombre || '');
            } else {
              setDepartamentoId('');
              setDepartamentoNombre('');
            }
          }}
        />
        <CatalogPicker
          label="Línea"
          catalogo="lineas"
          value={lineaId}
          displayValue={lineaNombre}
          displayField="nombre"
          placeholder="Seleccionar línea..."
          onSelect={(item) => {
            if (item) {
              setLineaId(item.id);
              setLineaNombre(item.nombre || '');
            } else {
              setLineaId('');
              setLineaNombre('');
            }
          }}
        />
        <DatePicker
          label="Fecha"
          value={fecha}
          onChange={setFecha}
          placeholder="Seleccionar fecha"
        />
      </View>

      <SectionHeader title={`Telas (${telas.length})`} />
      <View style={styles.card}>
        {telas.map((t, i) => {
          const subtotal = (parseFloat(t.consumo) || 0) * (parseFloat(t.precio_unitario) || 0);
          return (
            <React.Fragment key={i}>
              {i > 0 && <View style={styles.divider} />}
              <View style={styles.dynamicItem}>
                <View style={styles.dynamicHeader}>
                  <Text style={styles.dynamicIndex}>Tela {i + 1}</Text>
                  <TouchableOpacity onPress={() => removeTela(i)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                    <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
                  </TouchableOpacity>
                </View>
                <Input
                  label="Nombre"
                  value={t.nombre}
                  onChangeText={(v) => updateTela(i, 'nombre', v)}
                  placeholder="Nombre de la tela"
                />
                <View style={styles.rowInputs}>
                  <View style={styles.halfInput}>
                    <Input
                      label="Consumo"
                      value={t.consumo}
                      onChangeText={(v) => updateTela(i, 'consumo', v)}
                      placeholder="0.00"
                      keyboardType="decimal-pad"
                    />
                  </View>
                  <View style={styles.halfInput}>
                    <Input
                      label="Precio Unitario"
                      value={t.precio_unitario}
                      onChangeText={(v) => updateTela(i, 'precio_unitario', v)}
                      placeholder="0.00"
                      keyboardType="decimal-pad"
                    />
                  </View>
                </View>
                <Text style={styles.subtotalText}>Subtotal: {formatMX(subtotal)}</Text>
              </View>
            </React.Fragment>
          );
        })}
        <TouchableOpacity style={styles.addButton} onPress={addTela}>
          <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
          <Text style={styles.addButtonText}>Agregar Tela</Text>
        </TouchableOpacity>
      </View>

      <SectionHeader title={`Insumos (${insumos.length})`} />
      <View style={styles.card}>
        {insumos.map((ins, i) => {
          const subtotal = (parseFloat(ins.cantidad) || 0) * (parseFloat(ins.costo_unitario) || 0);
          return (
            <React.Fragment key={i}>
              {i > 0 && <View style={styles.divider} />}
              <View style={styles.dynamicItem}>
                <View style={styles.dynamicHeader}>
                  <Text style={styles.dynamicIndex}>Insumo {i + 1}</Text>
                  <TouchableOpacity onPress={() => removeInsumo(i)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                    <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
                  </TouchableOpacity>
                </View>
                <Input
                  label="Nombre"
                  value={ins.nombre}
                  onChangeText={(v) => updateInsumo(i, 'nombre', v)}
                  placeholder="Nombre del insumo"
                />
                <View style={styles.rowInputs}>
                  <View style={styles.halfInput}>
                    <Input
                      label="Cantidad"
                      value={ins.cantidad}
                      onChangeText={(v) => updateInsumo(i, 'cantidad', v)}
                      placeholder="0"
                      keyboardType="decimal-pad"
                    />
                  </View>
                  <View style={styles.halfInput}>
                    <Input
                      label="Costo Unitario"
                      value={ins.costo_unitario}
                      onChangeText={(v) => updateInsumo(i, 'costo_unitario', v)}
                      placeholder="0.00"
                      keyboardType="decimal-pad"
                    />
                  </View>
                </View>
                <Text style={styles.subtotalText}>Subtotal: {formatMX(subtotal)}</Text>
              </View>
            </React.Fragment>
          );
        })}

        <View style={styles.presetContainer}>
          <Text style={styles.presetLabel}>Agregar insumo:</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.presetChips}>
            {INSUMOS_PREDETERMINADOS.map((nombre) => (
              <TouchableOpacity
                key={nombre}
                style={styles.presetChip}
                onPress={() => addInsumo(nombre)}
              >
                <Text style={styles.presetChipText}>{nombre}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        <TouchableOpacity style={styles.addButton} onPress={() => addInsumo('')}>
          <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
          <Text style={styles.addButtonText}>Agregar Insumo Personalizado</Text>
        </TouchableOpacity>
      </View>

      <SectionHeader title="Cálculos" />
      <View style={styles.card}>
        <View style={styles.calcRow}>
          <Text style={styles.calcLabel}>Total Telas</Text>
          <Text style={styles.calcValue}>{formatMX(totalTelas)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.calcRow}>
          <Text style={styles.calcLabel}>Total Insumos</Text>
          <Text style={styles.calcValue}>{formatMX(totalInsumos)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.calcRow}>
          <Text style={styles.calcLabel}>Total</Text>
          <Text style={styles.calcValue}>{formatMX(total)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.calcRow}>
          <Text style={styles.calcLabel}>Gastos Indirectos (15%)</Text>
          <Text style={styles.calcValue}>{formatMX(gastos)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.calcRow}>
          <Text style={styles.totalLabel}>Total con Gastos</Text>
          <Text style={styles.totalValue}>{formatMX(totalConGastos)}</Text>
        </View>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Costo General'}
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
  dynamicItem: {
    paddingVertical: Spacing.sm,
  },
  dynamicHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xs,
  },
  dynamicIndex: {
    fontSize: FontSize.footnote,
    fontWeight: '600',
    color: Colors.primary,
    textTransform: 'uppercase',
  },
  rowInputs: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  halfInput: {
    flex: 1,
  },
  subtotalText: {
    fontSize: FontSize.footnote,
    color: Colors.success,
    fontWeight: '600',
    textAlign: 'right',
    marginTop: -Spacing.sm,
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
    fontWeight: '600',
  },
  presetContainer: {
    marginTop: Spacing.sm,
  },
  presetLabel: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
  },
  presetChips: {
    flexDirection: 'row',
    gap: Spacing.xs,
    paddingBottom: Spacing.sm,
  },
  presetChip: {
    backgroundColor: Colors.primary + '15',
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
    borderRadius: 12,
  },
  presetChipText: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    fontWeight: '500',
  },
  calcRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  calcLabel: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  calcValue: {
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
