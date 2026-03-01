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

export default function CostoGeneralDetalleScreen({ route, navigation }) {
  const costoId = route.params?.id;
  const [costo, setCosto] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadCosto = useCallback(async () => {
    try {
      const data = await api.getCostoGeneral(costoId);
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
      navigation.setOptions({ title: costo.modelo || 'Costo General' });
    }
  }, [costo, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadCosto();
  };

  const handleEdit = () => {
    navigation.navigate('CostoGeneralForm', { id: costo.id });
  };

  const handleDelete = () => {
    Alert.alert(
      'Eliminar Costo',
      '¿Estás seguro de eliminar este costo general? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCostoGeneral(costo.id);
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

  const telas = costo.telas || [];
  const insumos = costo.insumos || [];
  const totalTelas = parseFloat(costo.total_telas) || 0;
  const totalInsumos = parseFloat(costo.total_insumos) || 0;
  const total = parseFloat(costo.total) || 0;
  const totalConGastos = parseFloat(costo.total_con_gastos) || 0;

  return (
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
          <Text style={styles.infoLabel}>Tallas</Text>
          <Text style={styles.infoValue}>{costo.tallas || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Descripción</Text>
          <Text style={styles.infoValue}>{costo.descripcion || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Departamento</Text>
          <Text style={styles.infoValue}>{costo.departamento_nombre || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Línea</Text>
          <Text style={styles.infoValue}>{costo.linea_nombre || '—'}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.infoRow}>
          <Text style={styles.infoLabel}>Fecha</Text>
          <Text style={styles.infoValue}>{formatDate(costo.fecha)}</Text>
        </View>
      </View>

      <SectionHeader title={`Telas (${telas.length})`} />
      <View style={styles.card}>
        {telas.length > 0 ? (
          telas.map((t, i) => {
            const subtotal = (parseFloat(t.consumo) || 0) * (parseFloat(t.precio_unitario) || 0);
            return (
              <React.Fragment key={t.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.itemRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.itemName}>{t.nombre || 'Sin nombre'}</Text>
                    <Text style={styles.itemDetail}>
                      Consumo: {t.consumo} × {formatMX(t.precio_unitario)}
                    </Text>
                  </View>
                  <Text style={styles.itemSubtotal}>{formatMX(subtotal)}</Text>
                </View>
              </React.Fragment>
            );
          })
        ) : (
          <Text style={styles.emptyItemText}>Sin telas registradas</Text>
        )}
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Telas</Text>
          <Text style={styles.summaryValue}>{formatMX(totalTelas)}</Text>
        </View>
      </View>

      <SectionHeader title={`Insumos (${insumos.length})`} />
      <View style={styles.card}>
        {insumos.length > 0 ? (
          insumos.map((ins, i) => {
            const subtotal = (parseFloat(ins.cantidad) || 0) * (parseFloat(ins.costo_unitario) || 0);
            return (
              <React.Fragment key={ins.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.itemRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.itemName}>{ins.nombre || 'Sin nombre'}</Text>
                    <Text style={styles.itemDetail}>
                      Cantidad: {ins.cantidad} × {formatMX(ins.costo_unitario)}
                    </Text>
                  </View>
                  <Text style={styles.itemSubtotal}>{formatMX(subtotal)}</Text>
                </View>
              </React.Fragment>
            );
          })
        ) : (
          <Text style={styles.emptyItemText}>Sin insumos registrados</Text>
        )}
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Insumos</Text>
          <Text style={styles.summaryValue}>{formatMX(totalInsumos)}</Text>
        </View>
      </View>

      <SectionHeader title="Resumen" />
      <View style={styles.card}>
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Telas</Text>
          <Text style={styles.summaryValue}>{formatMX(totalTelas)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total Insumos</Text>
          <Text style={styles.summaryValue}>{formatMX(totalInsumos)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Total</Text>
          <Text style={styles.summaryValue}>{formatMX(total)}</Text>
        </View>
        <View style={styles.divider} />
        <View style={styles.summaryRow}>
          <Text style={styles.summaryLabel}>Gastos Indirectos (15%)</Text>
          <Text style={styles.summaryValue}>{formatMX(total * 0.15)}</Text>
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
    flex: 1,
  },
  infoValue: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
    flex: 1,
    textAlign: 'right',
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  itemName: {
    fontSize: FontSize.body,
    color: Colors.text,
    fontWeight: '500',
  },
  itemDetail: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  itemSubtotal: {
    fontSize: FontSize.body,
    color: Colors.text,
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
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
  emptyItemText: {
    fontSize: FontSize.footnote,
    color: Colors.textTertiary,
    fontStyle: 'italic',
    paddingVertical: Spacing.md,
    textAlign: 'center',
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
