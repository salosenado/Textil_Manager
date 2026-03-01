import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Alert,
  ActivityIndicator, TouchableOpacity, RefreshControl,
  Modal, TextInput, KeyboardAvoidingView, Platform
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

function getStatusInfo(venta) {
  if (venta.cancelada) return { label: 'Cancelada', color: Colors.destructive, icon: 'close-circle' };
  if (venta.mercancia_enviada) return { label: 'Mercancía enviada', color: Colors.primary, icon: 'checkmark-circle' };
  return { label: 'Activa', color: Colors.success, icon: 'ellipse' };
}

function getMovIconColor(mov) {
  const t = (mov.titulo || '').toLowerCase();
  if (t.includes('creada')) return { icon: 'add-circle', color: Colors.success };
  if (t.includes('editada')) return { icon: 'create', color: Colors.primary };
  if (t.includes('enviada') || t.includes('envío') || t.includes('mercancía')) return { icon: 'paper-plane', color: Colors.orange };
  if (t.includes('cancelada')) return { icon: 'close-circle', color: Colors.destructive };
  if (t.includes('cobro')) return { icon: 'cash', color: Colors.success };
  return { icon: mov.icono || 'time-outline', color: mov.color || Colors.textSecondary };
}

export default function VentaClienteDetalleScreen({ route, navigation }) {
  const ventaId = route.params?.id;
  const [venta, setVenta] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [cobroModalVisible, setCobroModalVisible] = useState(false);
  const [cobroMonto, setCobroMonto] = useState('');
  const [cobroReferencia, setCobroReferencia] = useState('');
  const [cobroObservaciones, setCobroObservaciones] = useState('');
  const [cobroSaving, setCobroSaving] = useState(false);

  const loadVenta = useCallback(async () => {
    try {
      const data = await api.getVentaCliente(ventaId);
      setVenta(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [ventaId]);

  useEffect(() => {
    loadVenta();
  }, [loadVenta]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      if (venta) {
        loadVenta();
      }
    });
    return unsubscribe;
  }, [navigation, loadVenta, venta]);

  useEffect(() => {
    if (venta) {
      navigation.setOptions({
        title: venta.folio || 'Venta',
      });
    }
  }, [venta, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadVenta();
  };

  const handleEdit = () => {
    navigation.navigate('VentaClienteForm', { id: venta.id });
  };

  const handleEnviar = () => {
    Alert.alert(
      'Enviar Mercancía',
      '¿Estás seguro de marcar la mercancía como enviada? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Enviar',
          onPress: async () => {
            try {
              await api.enviarVentaCliente(venta.id);
              loadVenta();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancelar Venta',
      '¿Estás seguro de cancelar esta venta? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarVentaCliente(venta.id);
              loadVenta();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleDelete = () => {
    Alert.alert(
      'Eliminar Venta',
      '¿Estás seguro de eliminar esta venta? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteVentaCliente(venta.id);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleCreateCobro = async () => {
    const monto = parseFloat(cobroMonto);
    if (!monto || monto <= 0) {
      Alert.alert('Error', 'Ingresa un monto válido mayor a 0');
      return;
    }
    const saldo = parseFloat(venta.saldo) || 0;
    if (monto > saldo + 0.01) {
      Alert.alert('Error', `El monto no puede ser mayor al saldo pendiente (${formatMX(saldo)})`);
      return;
    }
    setCobroSaving(true);
    try {
      await api.createCobroVenta(venta.id, {
        monto,
        referencia: cobroReferencia,
        observaciones: cobroObservaciones,
      });
      setCobroModalVisible(false);
      setCobroMonto('');
      setCobroReferencia('');
      setCobroObservaciones('');
      loadVenta();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setCobroSaving(false);
    }
  };

  const handleDeleteCobro = (cobro) => {
    Alert.alert(
      'Eliminar Cobro',
      `¿Eliminar cobro de ${formatMX(cobro.monto)}?`,
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCobroVenta(venta.id, cobro.id);
              loadVenta();
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

  if (!venta) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Venta no encontrada</Text>
      </View>
    );
  }

  const isCancelled = venta.cancelada;
  const isEnviada = venta.mercancia_enviada;
  const status = getStatusInfo(venta);
  const detalles = venta.detalles || [];
  const cobros = venta.cobros || [];
  const movimientos = venta.movimientos || [];

  const subtotal = parseFloat(venta.subtotal) || 0;
  const aplicaIva = venta.aplica_iva;
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = parseFloat(venta.total) || (subtotal + iva);
  const totalCobrado = parseFloat(venta.totalCobrado) || cobros.reduce((sum, c) => sum + (parseFloat(c.monto) || 0), 0);
  const saldo = parseFloat(venta.saldo) || (total - totalCobrado);

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {isCancelled && (
          <View style={styles.cancelledBanner}>
            <Ionicons name="close-circle" size={20} color={Colors.white} />
            <Text style={styles.cancelledText}>Venta Cancelada</Text>
          </View>
        )}

        <View style={styles.headerCard}>
          <Text style={styles.folioText}>{venta.folio}</Text>
          <View style={[styles.statusBadge, { backgroundColor: status.color + '20' }]}>
            <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
          </View>
          <Text style={styles.headerDate}>{formatDate(venta.fecha_venta)}</Text>
        </View>

        <SectionHeader title="Información General" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Cliente</Text>
            <Text style={styles.infoValue}>{venta.cliente_nombre || '—'}</Text>
          </View>
          {venta.agente_nombre ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Agente</Text>
                <Text style={styles.infoValue}>{venta.agente_nombre}</Text>
              </View>
            </>
          ) : null}
          {venta.fecha_entrega ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Fecha Entrega</Text>
                <Text style={styles.infoValue}>{formatDate(venta.fecha_entrega)}</Text>
              </View>
            </>
          ) : null}
          {venta.numero_factura ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>No. Factura</Text>
                <Text style={styles.infoValue}>{venta.numero_factura}</Text>
              </View>
            </>
          ) : null}
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Aplica IVA</Text>
            <Text style={styles.infoValue}>{aplicaIva ? 'Sí' : 'No'}</Text>
          </View>
          {venta.observaciones ? (
            <>
              <View style={styles.divider} />
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Observaciones</Text>
                <Text style={[styles.infoValue, { flex: 1, textAlign: 'right' }]} numberOfLines={3}>
                  {venta.observaciones}
                </Text>
              </View>
            </>
          ) : null}
        </View>

        <SectionHeader title={`Artículos (${detalles.length})`} />
        <View style={styles.card}>
          {detalles.length > 0 ? (
            detalles.map((det, i) => (
              <React.Fragment key={det.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.detalleItem}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.detalleArticulo}>{det.modelo_nombre || 'Sin artículo'}</Text>
                    {det.marca_nombre ? (
                      <Text style={styles.detalleCaption}>Marca: {det.marca_nombre}</Text>
                    ) : null}
                    <Text style={styles.detalleCaption}>
                      {det.cantidad} {det.unidad || 'PZ'} × {formatMX(det.costo_unitario)}
                    </Text>
                  </View>
                  <Text style={styles.detalleSubtotal}>
                    {formatMX((parseInt(det.cantidad) || 0) * (parseFloat(det.costo_unitario) || 0))}
                  </Text>
                </View>
              </React.Fragment>
            ))
          ) : (
            <Text style={styles.emptyText}>Sin artículos</Text>
          )}
        </View>

        <SectionHeader title="Resumen Financiero" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Subtotal</Text>
            <Text style={styles.infoValue}>{formatMX(subtotal)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>IVA (16%)</Text>
            <Text style={styles.infoValue}>{aplicaIva ? formatMX(iva) : '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.summaryRow}>
            <Text style={styles.totalLabel}>Total</Text>
            <Text style={styles.totalValue}>{formatMX(total)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Total Cobrado</Text>
            <Text style={[styles.infoValue, { color: Colors.success, fontWeight: '600' }]}>{formatMX(totalCobrado)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Saldo Pendiente</Text>
            <Text style={[styles.infoValue, { color: saldo > 0 ? Colors.destructive : Colors.success, fontWeight: '600' }]}>
              {formatMX(saldo)}
            </Text>
          </View>
        </View>

        <SectionHeader title={`Cobros (${cobros.length})`} />
        <View style={styles.card}>
          {cobros.length > 0 ? (
            cobros.map((cobro, i) => (
              <React.Fragment key={cobro.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.reciboRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.pagoMonto}>{formatMX(cobro.monto)}</Text>
                    <Text style={styles.reciboDate}>{formatDate(cobro.fecha_cobro)}</Text>
                    {cobro.referencia ? (
                      <Text style={styles.reciboObs}>Ref: {cobro.referencia}</Text>
                    ) : null}
                    {cobro.observaciones ? (
                      <Text style={styles.reciboObs}>{cobro.observaciones}</Text>
                    ) : null}
                  </View>
                  {!isCancelled && (
                    <TouchableOpacity onPress={() => handleDeleteCobro(cobro)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                      <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
                    </TouchableOpacity>
                  )}
                </View>
              </React.Fragment>
            ))
          ) : (
            <Text style={styles.emptyText}>Sin cobros</Text>
          )}
          {!isCancelled && saldo > 0 && (
            <>
              <View style={styles.divider} />
              <TouchableOpacity
                style={styles.addButton}
                onPress={() => setCobroModalVisible(true)}
              >
                <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
                <Text style={styles.addButtonText}>Registrar Cobro (saldo: {formatMX(saldo)})</Text>
              </TouchableOpacity>
            </>
          )}
          {!isCancelled && saldo <= 0 && totalCobrado > 0 && (
            <>
              <View style={styles.divider} />
              <View style={styles.completeBanner}>
                <Ionicons name="checkmark-circle" size={18} color={Colors.success} />
                <Text style={[styles.addButtonText, { color: Colors.success }]}>Cobro completo</Text>
              </View>
            </>
          )}
        </View>

        {movimientos.length > 0 && (
          <>
            <SectionHeader title="Timeline" />
            <View style={styles.card}>
              {movimientos.map((mov, i) => {
                const mc = getMovIconColor(mov);
                return (
                  <React.Fragment key={mov.id || i}>
                    {i > 0 && <View style={styles.divider} />}
                    <View style={styles.movRow}>
                      <Ionicons name={mc.icon} size={16} color={mc.color} />
                      <View style={styles.movContent}>
                        <Text style={styles.movText}>
                          {mov.titulo}{mov.usuario ? ` por ${mov.usuario}` : ''}
                        </Text>
                        <Text style={styles.movDate}>{formatDate(mov.fecha)}</Text>
                      </View>
                    </View>
                  </React.Fragment>
                );
              })}
            </View>
          </>
        )}

        {!isCancelled && !isEnviada && (
          <View style={styles.buttonContainer}>
            <Button title="Editar" onPress={handleEdit} />
          </View>
        )}

        {!isCancelled && !isEnviada && (
          <View style={styles.buttonContainer}>
            <Button title="Enviar Mercancía" onPress={handleEnviar} variant="secondary" />
          </View>
        )}

        {!isCancelled && (
          <View style={styles.buttonContainer}>
            <Button title="Cancelar Venta" onPress={handleCancel} variant="destructive" />
          </View>
        )}

        <View style={styles.buttonContainer}>
          <Button title="Eliminar" onPress={handleDelete} variant="destructive" />
        </View>

        <View style={{ height: 40 }} />
      </ScrollView>

      <Modal visible={cobroModalVisible} animationType="slide" transparent>
        <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Registrar Cobro</Text>
              <TouchableOpacity onPress={() => setCobroModalVisible(false)}>
                <Text style={styles.modalClose}>Cerrar</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.modalBody}>
              <Text style={styles.inputLabel}>Monto * (máximo {formatMX(saldo)})</Text>
              <TextInput
                style={styles.modalInput}
                value={cobroMonto}
                onChangeText={setCobroMonto}
                placeholder="0.00"
                keyboardType="decimal-pad"
                placeholderTextColor={Colors.textTertiary}
              />

              <Text style={styles.inputLabel}>Referencia</Text>
              <TextInput
                style={styles.modalInput}
                value={cobroReferencia}
                onChangeText={setCobroReferencia}
                placeholder="Número de referencia"
                placeholderTextColor={Colors.textTertiary}
              />

              <Text style={styles.inputLabel}>Observaciones</Text>
              <TextInput
                style={[styles.modalInput, { height: 80, textAlignVertical: 'top' }]}
                value={cobroObservaciones}
                onChangeText={setCobroObservaciones}
                placeholder="Observaciones del cobro"
                multiline
                placeholderTextColor={Colors.textTertiary}
              />

              <Button
                title="Registrar Cobro"
                onPress={handleCreateCobro}
                loading={cobroSaving}
                style={{ marginTop: Spacing.md }}
              />
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
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
  cancelledBanner: {
    backgroundColor: Colors.destructive,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.sm,
    gap: Spacing.xs,
  },
  cancelledText: {
    color: Colors.white,
    fontSize: FontSize.footnote,
    fontWeight: '600',
  },
  headerCard: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    marginBottom: Spacing.sm,
    alignItems: 'center',
  },
  folioText: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: Spacing.sm,
  },
  headerDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
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
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: 8,
  },
  statusText: {
    fontSize: FontSize.caption,
    fontWeight: '600',
  },
  detalleItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  detalleArticulo: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 2,
  },
  detalleCaption: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 1,
  },
  detalleSubtotal: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
    marginLeft: Spacing.sm,
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
  reciboRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  pagoMonto: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
    marginBottom: 2,
  },
  reciboDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 1,
  },
  reciboObs: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 1,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    gap: Spacing.xs,
  },
  addButtonText: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '500',
  },
  completeBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.sm,
    gap: Spacing.xs,
  },
  movRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: Spacing.sm,
    gap: Spacing.sm,
  },
  movContent: {
    flex: 1,
  },
  movText: {
    fontSize: FontSize.body,
    color: Colors.text,
    marginBottom: 2,
  },
  movDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingVertical: Spacing.md,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: Colors.card,
    borderTopLeftRadius: BorderRadius.xl,
    borderTopRightRadius: BorderRadius.xl,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
  },
  modalTitle: {
    fontSize: FontSize.lg,
    fontWeight: '600',
    color: Colors.text,
  },
  modalClose: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '500',
  },
  modalBody: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.lg,
  },
  inputLabel: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
    marginTop: Spacing.sm,
  },
  modalInput: {
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    fontSize: FontSize.body,
    color: Colors.text,
  },
});
