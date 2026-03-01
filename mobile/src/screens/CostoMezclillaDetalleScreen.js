import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator, RefreshControl
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import SectionHeader from '../components/SectionHeader';
import Button from '../components/Button';

function formatMX(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function CostoMezclillaDetalleScreen({ route, navigation }) {
  const costoId = route.params?.id;
  const [costo, setCosto] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadCosto = useCallback(async () => {
    try {
      const data = await api.getCostoMezclilla(costoId);
      setCosto(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [costoId]);

  useEffect(() => {
    loadCosto();
  }, [loadCosto]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      if (costo) loadCosto();
    });
    return unsubscribe;
  }, [navigation, loadCosto, costo]);

  useEffect(() => {
    if (costo) {
      navigation.setOptions({
        title: costo.modelo || 'Costo Mezclilla',
      });
    }
  }, [costo, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadCosto();
  };

  const handleEdit = () => {
    navigation.navigate('CostoMezclillaForm', { id: costo.id });
  };

  const handleDelete = () => {
    Alert.alert(
      'Eliminar Costo',
      '¿Estás seguro de eliminar este costo de mezclilla? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCostoMezclilla(costo.id);
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

  if (!costo) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Costo no encontrado</Text>
      </View>
    );
  }

  const totalTela = parseFloat(costo.total_tela) || 0;
  const totalPoquetin = parseFloat(costo.total_poquetin) || 0;
  const totalProcesos = parseFloat(costo.total_procesos) || 0;
  const total = parseFloat(costo.total) || 0;
  const totalConGastos = parseFloat(costo.total_con_gastos) || 0;
  const gastos15 = total * 0.15;

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        <SectionHeader title="Información" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Modelo</Text>
            <Text style={styles.infoValue}>{costo.modelo || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Tela</Text>
            <Text style={styles.infoValue}>{costo.tela || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Fecha</Text>
            <Text style={styles.infoValue}>{formatDate(costo.fecha)}</Text>
          </View>
          {costo.usuario_creacion && (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Creado por</Text>
                <Text style={styles.infoValue}>{costo.usuario_creacion}</Text>
              </View>
            </>
          )}
        </View>

        <SectionHeader title="Tela Principal" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Costo Tela</Text>
            <Text style={styles.infoValue}>{formatMX(costo.costo_tela)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Consumo Tela</Text>
            <Text style={styles.infoValue}>{parseFloat(costo.consumo_tela) || 0}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Subtotal Tela</Text>
            <Text style={styles.summaryValue}>{formatMX(totalTela)}</Text>
          </View>
        </View>

        <SectionHeader title="Poquetín" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Costo Poquetín</Text>
            <Text style={styles.infoValue}>{formatMX(costo.costo_poquetin)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Consumo Poquetín</Text>
            <Text style={styles.infoValue}>{parseFloat(costo.consumo_poquetin) || 0}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Subtotal Poquetín</Text>
            <Text style={styles.summaryValue}>{formatMX(totalPoquetin)}</Text>
          </View>
        </View>

        <SectionHeader title="Procesos" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Maquila</Text>
            <Text style={styles.infoValue}>{formatMX(costo.maquila)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Lavandería</Text>
            <Text style={styles.infoValue}>{formatMX(costo.lavanderia)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Cierre</Text>
            <Text style={styles.infoValue}>{formatMX(costo.cierre)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Botón</Text>
            <Text style={styles.infoValue}>{formatMX(costo.boton)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Remaches</Text>
            <Text style={styles.infoValue}>{formatMX(costo.remaches)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Etiquetas</Text>
            <Text style={styles.infoValue}>{formatMX(costo.etiquetas)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Flete y Cajas</Text>
            <Text style={styles.infoValue}>{formatMX(costo.flete_y_cajas)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryRow}>
            <Text style={styles.summaryLabel}>Total Procesos</Text>
            <Text style={styles.summaryValue}>{formatMX(totalProcesos)}</Text>
          </View>
        </View>

        <SectionHeader title="Resumen" />
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
            <Text style={[styles.summaryLabel, { fontWeight: '700', color: Colors.text }]}>Total</Text>
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

        <View style={styles.buttonContainer}>
          <Button title="Editar" onPress={handleEdit} />
          <View style={{ height: Spacing.sm }} />
          <Button title="Eliminar" onPress={handleDelete} variant="destructive" />
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
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
    paddingHorizontal: Spacing.lg,
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
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
