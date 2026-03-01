import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator
} from 'react-native';
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

function todayStr() {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${dd}`;
}

export default function CostoMezclillaFormScreen({ route, navigation }) {
  const editId = route.params?.id;
  const isEditing = !!editId;

  const [modelo, setModelo] = useState('');
  const [tela, setTela] = useState('');
  const [fecha, setFecha] = useState(todayStr());

  const [costoTela, setCostoTela] = useState('');
  const [consumoTela, setConsumoTela] = useState('');

  const [costoPoquetin, setCostoPoquetin] = useState('');
  const [consumoPoquetin, setConsumoPoquetin] = useState('');

  const [maquila, setMaquila] = useState('');
  const [lavanderia, setLavanderia] = useState('');
  const [cierre, setCierre] = useState('');
  const [boton, setBoton] = useState('');
  const [remaches, setRemaches] = useState('');
  const [etiquetas, setEtiquetas] = useState('');
  const [fleteYCajas, setFleteYCajas] = useState('');

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
      const data = await api.getCostoMezclilla(editId);
      setModelo(data.modelo || '');
      setTela(data.tela || '');
      setFecha(data.fecha ? data.fecha.substring(0, 10) : todayStr());
      setCostoTela(data.costo_tela ? String(data.costo_tela) : '');
      setConsumoTela(data.consumo_tela ? String(data.consumo_tela) : '');
      setCostoPoquetin(data.costo_poquetin ? String(data.costo_poquetin) : '');
      setConsumoPoquetin(data.consumo_poquetin ? String(data.consumo_poquetin) : '');
      setMaquila(data.maquila ? String(data.maquila) : '');
      setLavanderia(data.lavanderia ? String(data.lavanderia) : '');
      setCierre(data.cierre ? String(data.cierre) : '');
      setBoton(data.boton ? String(data.boton) : '');
      setRemaches(data.remaches ? String(data.remaches) : '');
      setEtiquetas(data.etiquetas ? String(data.etiquetas) : '');
      setFleteYCajas(data.flete_y_cajas ? String(data.flete_y_cajas) : '');
    } catch (err) {
      setError(err.message || 'Error al cargar datos');
    } finally {
      setLoadingData(false);
    }
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? 'Editar Costo Mezclilla' : 'Nuevo Costo Mezclilla',
    });
  }, [navigation, isEditing]);

  const costoTelaNum = parseFloat(costoTela) || 0;
  const consumoTelaNum = parseFloat(consumoTela) || 0;
  const totalTela = costoTelaNum * consumoTelaNum;

  const costoPoqNum = parseFloat(costoPoquetin) || 0;
  const consumoPoqNum = parseFloat(consumoPoquetin) || 0;
  const totalPoquetin = costoPoqNum * consumoPoqNum;

  const maquilaNum = parseFloat(maquila) || 0;
  const lavanderiaNum = parseFloat(lavanderia) || 0;
  const cierreNum = parseFloat(cierre) || 0;
  const botonNum = parseFloat(boton) || 0;
  const remachesNum = parseFloat(remaches) || 0;
  const etiquetasNum = parseFloat(etiquetas) || 0;
  const fleteNum = parseFloat(fleteYCajas) || 0;
  const totalProcesos = maquilaNum + lavanderiaNum + cierreNum + botonNum + remachesNum + etiquetasNum + fleteNum;

  const total = totalTela + totalPoquetin + totalProcesos;
  const gastos15 = total * 0.15;
  const totalConGastos = total * 1.15;

  const handleSave = async () => {
    const allNumericFields = [
      { name: 'Costo Tela', val: costoTelaNum },
      { name: 'Consumo Tela', val: consumoTelaNum },
      { name: 'Costo Poquetín', val: costoPoqNum },
      { name: 'Consumo Poquetín', val: consumoPoqNum },
      { name: 'Maquila', val: maquilaNum },
      { name: 'Lavandería', val: lavanderiaNum },
      { name: 'Cierre', val: cierreNum },
      { name: 'Botón', val: botonNum },
      { name: 'Remaches', val: remachesNum },
      { name: 'Etiquetas', val: etiquetasNum },
      { name: 'Flete y Cajas', val: fleteNum },
    ];

    for (const f of allNumericFields) {
      if (f.val < 0) {
        setError(`El campo ${f.name} no puede ser negativo`);
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {
        modelo: modelo.trim() || null,
        tela: tela.trim() || null,
        fecha: fecha || null,
        costo_tela: costoTelaNum,
        consumo_tela: consumoTelaNum,
        costo_poquetin: costoPoqNum,
        consumo_poquetin: consumoPoqNum,
        maquila: maquilaNum,
        lavanderia: lavanderiaNum,
        cierre: cierreNum,
        boton: botonNum,
        remaches: remachesNum,
        etiquetas: etiquetasNum,
        flete_y_cajas: fleteNum,
      };

      if (isEditing) {
        await api.updateCostoMezclilla(editId, data);
      } else {
        await api.createCostoMezclilla(data);
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
          autoCapitalize="words"
        />
        <View style={styles.divider} />
        <Input
          label="Tela"
          value={tela}
          onChangeText={setTela}
          placeholder="Tipo de tela"
          autoCapitalize="words"
        />
        <View style={styles.divider} />
        <DatePicker
          label="Fecha"
          value={fecha}
          onChange={setFecha}
          placeholder="Seleccionar fecha"
        />
      </View>

      <SectionHeader title="Tela Principal" />
      <View style={styles.card}>
        <Input
          label="Costo Tela"
          value={costoTela}
          onChangeText={setCostoTela}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Consumo Tela"
          value={consumoTela}
          onChangeText={setConsumoTela}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal Tela</Text>
          <Text style={styles.summaryValue}>{formatMX(totalTela)}</Text>
        </View>
      </View>

      <SectionHeader title="Poquetín" />
      <View style={styles.card}>
        <Input
          label="Costo Poquetín"
          value={costoPoquetin}
          onChangeText={setCostoPoquetin}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Consumo Poquetín"
          value={consumoPoquetin}
          onChangeText={setConsumoPoquetin}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Subtotal Poquetín</Text>
          <Text style={styles.summaryValue}>{formatMX(totalPoquetin)}</Text>
        </View>
      </View>

      <SectionHeader title="Procesos" />
      <View style={styles.card}>
        <Input
          label="Maquila"
          value={maquila}
          onChangeText={setMaquila}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Lavandería"
          value={lavanderia}
          onChangeText={setLavanderia}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Cierre"
          value={cierre}
          onChangeText={setCierre}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Botón"
          value={boton}
          onChangeText={setBoton}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Remaches"
          value={remaches}
          onChangeText={setRemaches}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Etiquetas"
          value={etiquetas}
          onChangeText={setEtiquetas}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <Input
          label="Flete y Cajas"
          value={fleteYCajas}
          onChangeText={setFleteYCajas}
          placeholder="0.00"
          keyboardType="decimal-pad"
        />
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Procesos</Text>
          <Text style={styles.summaryValue}>{formatMX(totalProcesos)}</Text>
        </View>
      </View>

      <SectionHeader title="Cálculos" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Tela</Text>
          <Text style={styles.summaryValue}>{formatMX(totalTela)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Poquetín</Text>
          <Text style={styles.summaryValue}>{formatMX(totalPoquetin)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Procesos</Text>
          <Text style={styles.summaryValue}>{formatMX(totalProcesos)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total</Text>
          <Text style={[styles.summaryValue, { fontWeight: '700' }]}>{formatMX(total)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>+ 15% Gastos Indirectos</Text>
          <Text style={styles.summaryValue}>{formatMX(gastos15)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.totalLabel}>Total con Gastos</Text>
          <Text style={styles.totalValue}>{formatMX(totalConGastos)}</Text>
        </View>
      </View>

      {error ? <Text style={styles.error}>{error}</Text> : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Costo Mezclilla'}
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
