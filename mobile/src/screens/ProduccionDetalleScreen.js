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

function getStatusInfo(prod) {
  if (prod.cancelada) return { label: 'Cancelada', color: Colors.destructive };
  const recibido = parseInt(prod.total_recibido) || 0;
  const cortadas = parseInt(prod.pz_cortadas) || 0;
  if (recibido === 0) return { label: 'En producción', color: Colors.destructive };
  if (recibido < cortadas) return { label: 'Parcial', color: Colors.orange };
  return { label: 'Completa', color: Colors.success };
}

export default function ProduccionDetalleScreen({ route, navigation }) {
  const produccionId = route.params?.id || route.params?.produccionId;
  const [produccion, setProduccion] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [reciboModalVisible, setReciboModalVisible] = useState(false);
  const [reciboCantidad, setReciboCantidad] = useState('');
  const [reciboObservaciones, setReciboObservaciones] = useState('');
  const [reciboNombreEntrega, setReciboNombreEntrega] = useState('');
  const [reciboNombreRecepcion, setReciboNombreRecepcion] = useState('');
  const [reciboSaving, setReciboSaving] = useState(false);

  const [pagoModalVisible, setPagoModalVisible] = useState(false);
  const [pagoMonto, setPagoMonto] = useState('');
  const [pagoObservaciones, setPagoObservaciones] = useState('');
  const [pagoReciboId, setPagoReciboId] = useState(null);
  const [pagoSaving, setPagoSaving] = useState(false);

  const loadProduccion = useCallback(async () => {
    try {
      const data = await api.getProduccion(produccionId);
      setProduccion(data);
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [produccionId]);

  useEffect(() => {
    loadProduccion();
  }, [loadProduccion]);

  useEffect(() => {
    const unsubscribe = navigation.addListener('focus', () => {
      if (produccion) {
        loadProduccion();
      }
    });
    return unsubscribe;
  }, [navigation, loadProduccion, produccion]);

  useEffect(() => {
    if (produccion) {
      navigation.setOptions({
        title: produccion.orden_maquila || 'Producción',
      });
    }
  }, [produccion, navigation]);

  const onRefresh = () => {
    setRefreshing(true);
    loadProduccion();
  };

  const handleEdit = () => {
    navigation.navigate('ProduccionForm', { id: produccion.id });
  };

  const handleCancel = () => {
    Alert.alert(
      'Cancelar Producción',
      '¿Estás seguro de cancelar esta producción? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Sí, Cancelar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.cancelarProduccion(produccion.id);
              loadProduccion();
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
      'Eliminar Producción',
      '¿Estás seguro de eliminar esta producción? Esta acción no se puede deshacer.',
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteProduccion(produccion.id);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleCreateRecibo = async () => {
    if (!reciboCantidad || parseFloat(reciboCantidad) <= 0) {
      Alert.alert('Error', 'Ingresa una cantidad válida');
      return;
    }
    setReciboSaving(true);
    try {
      await api.createReciboProduccion(produccion.id, {
        cantidad: parseInt(reciboCantidad),
        observaciones: reciboObservaciones,
        nombre_entrega: reciboNombreEntrega,
        nombre_recepcion: reciboNombreRecepcion,
      });
      setReciboModalVisible(false);
      setReciboCantidad('');
      setReciboObservaciones('');
      setReciboNombreEntrega('');
      setReciboNombreRecepcion('');
      loadProduccion();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setReciboSaving(false);
    }
  };

  const handleDeleteRecibo = (recibo) => {
    Alert.alert(
      'Eliminar Recepción',
      `¿Eliminar recepción de ${recibo.cantidad} pz?`,
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteReciboProduccion(recibo.id);
              loadProduccion();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const handleCreatePago = async () => {
    if (!pagoMonto || parseFloat(pagoMonto) <= 0) {
      Alert.alert('Error', 'Ingresa un monto válido');
      return;
    }
    setPagoSaving(true);
    try {
      await api.createPagoRecibo(pagoReciboId, {
        monto: parseFloat(pagoMonto),
        observaciones: pagoObservaciones,
      });
      setPagoModalVisible(false);
      setPagoMonto('');
      setPagoObservaciones('');
      setPagoReciboId(null);
      loadProduccion();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setPagoSaving(false);
    }
  };

  const handleDeletePago = (pago) => {
    Alert.alert(
      'Eliminar Pago',
      `¿Eliminar pago de ${formatMX(pago.monto)}?`,
      [
        { text: 'No', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deletePagoRecibo(pago.id);
              loadProduccion();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const openPagoModal = (reciboId) => {
    setPagoReciboId(reciboId);
    setPagoMonto('');
    setPagoObservaciones('');
    setPagoModalVisible(true);
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  if (!produccion) {
    return (
      <View style={styles.centered}>
        <Ionicons name="alert-circle-outline" size={48} color={Colors.textSecondary} />
        <Text style={styles.emptyText}>Producción no encontrada</Text>
      </View>
    );
  }

  const isCancelled = produccion.cancelada;
  const totalRecibido = parseInt(produccion.total_recibido) || 0;
  const pzCortadas = parseInt(produccion.pz_cortadas) || 0;
  const pzPendientes = Math.max(0, pzCortadas - totalRecibido);
  const costoMaquila = parseFloat(produccion.costo_maquila) || 0;
  const subtotal = pzCortadas * costoMaquila;
  const detOrden = produccion.detalle_orden;
  const aplicaIva = detOrden?.aplica_iva || false;
  const iva = aplicaIva ? subtotal * 0.16 : 0;
  const total = subtotal + iva;
  const recibos = produccion.recibos || [];
  const pagos = produccion.pagos || [];
  const totalPagado = pagos.reduce((sum, p) => sum + (parseFloat(p.monto) || 0), 0);
  const saldoPendiente = total - totalPagado;
  const hasRecibos = recibos.length > 0;
  const status = getStatusInfo(produccion);

  const movimientos = [];
  if (produccion.created_at) {
    movimientos.push({ texto: 'Producción creada', fecha: produccion.created_at });
  }
  if (produccion.fecha_orden_maquila) {
    movimientos.push({ texto: `Orden de Maquila ${produccion.orden_maquila} generada`, fecha: produccion.fecha_orden_maquila });
  }
  recibos.forEach(r => {
    movimientos.push({ texto: `Recepción de ${r.cantidad} pz`, fecha: r.fecha_recibo || r.created_at });
  });
  pagos.forEach(p => {
    movimientos.push({ texto: `Pago de ${formatMX(p.monto)}`, fecha: p.fecha_pago || p.created_at });
  });
  if (produccion.fecha_cancelacion) {
    movimientos.push({ texto: `Cancelada por ${produccion.usuario_cancelacion || '—'}`, fecha: produccion.fecha_cancelacion });
  }
  movimientos.sort((a, b) => new Date(a.fecha) - new Date(b.fecha));

  return (
    <View style={{ flex: 1, backgroundColor: Colors.background }}>
      <ScrollView
        style={styles.container}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {isCancelled && (
          <View style={styles.cancelledBanner}>
            <Ionicons name="close-circle" size={20} color={Colors.white} />
            <Text style={styles.cancelledText}>Producción Cancelada</Text>
          </View>
        )}

        {produccion.orden_maquila && (
          <>
            <SectionHeader title="Orden de Maquila" />
            <View style={styles.card}>
              <Text style={styles.omNumber}>{produccion.orden_maquila}</Text>
              <Text style={styles.omDate}>{formatDate(produccion.fecha_orden_maquila)}</Text>
              <View style={[styles.statusBadge, { backgroundColor: status.color + '20' }]}>
                <Text style={[styles.statusText, { color: status.color }]}>{status.label}</Text>
              </View>
            </View>
          </>
        )}

        {detOrden && (
          <>
            <SectionHeader title="Solicitud" />
            <View style={styles.card}>
              {detOrden.numero_venta && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>No. Venta</Text>
                    <Text style={styles.infoValue}>#{detOrden.numero_venta}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              {detOrden.numero_pedido_cliente && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Pedido Cliente</Text>
                    <Text style={styles.infoValue}>{detOrden.numero_pedido_cliente}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              {detOrden.articulo && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Artículo</Text>
                    <Text style={styles.infoValue}>{detOrden.articulo}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              {detOrden.modelo && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Modelo</Text>
                    <Text style={styles.infoValue}>{detOrden.modelo}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              {detOrden.cliente_nombre && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Cliente</Text>
                    <Text style={styles.infoValue}>{detOrden.cliente_nombre}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              {detOrden.fecha_entrega && (
                <>
                  <View style={styles.infoRow}>
                    <Text style={styles.infoLabel}>Fecha Entrega</Text>
                    <Text style={styles.infoValue}>{formatDate(detOrden.fecha_entrega)}</Text>
                  </View>
                  <View style={styles.divider} />
                </>
              )}
              <View style={styles.infoRow}>
                <Text style={styles.infoLabel}>Cantidad Solicitada</Text>
                <Text style={styles.infoValue}>{detOrden.cantidad || '—'}</Text>
              </View>
            </View>
          </>
        )}

        <SectionHeader title="Producción" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Maquilero</Text>
            <Text style={styles.infoValue}>{produccion.maquilero_nombre || '—'}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Pz Cortadas</Text>
            <Text style={styles.infoValue}>{pzCortadas}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Costo Maquila</Text>
            <Text style={styles.infoValue}>{formatMX(costoMaquila)}</Text>
          </View>
        </View>

        <SectionHeader title="Cálculos" />
        <View style={styles.card}>
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Pz Pendientes</Text>
            <Text style={[styles.infoValue, { color: pzPendientes > 0 ? Colors.orange : Colors.success }]}>
              {pzPendientes}
            </Text>
          </View>
          <View style={styles.divider} />
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
        </View>

        <SectionHeader title={`Recepciones (${recibos.length})`} />
        <View style={styles.card}>
          {recibos.length > 0 ? (
            recibos.map((recibo, i) => (
              <React.Fragment key={recibo.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.reciboRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.reciboQty}>{recibo.cantidad} pz</Text>
                    <Text style={styles.reciboDate}>{formatDate(recibo.fecha_recibo)}</Text>
                    {recibo.observaciones ? (
                      <Text style={styles.reciboObs}>{recibo.observaciones}</Text>
                    ) : null}
                    {recibo.nombre_entrega ? (
                      <Text style={styles.reciboFirma}>Entrega: {recibo.nombre_entrega}</Text>
                    ) : null}
                    {recibo.nombre_recepcion ? (
                      <Text style={styles.reciboFirma}>Recepción: {recibo.nombre_recepcion}</Text>
                    ) : null}
                  </View>
                  {!isCancelled && (
                    <TouchableOpacity onPress={() => handleDeleteRecibo(recibo)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                      <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
                    </TouchableOpacity>
                  )}
                </View>
              </React.Fragment>
            ))
          ) : (
            <Text style={styles.emptyText}>Sin recepciones</Text>
          )}
          {!isCancelled && pzPendientes > 0 && (
            <>
              <View style={styles.divider} />
              <TouchableOpacity
                style={styles.addButton}
                onPress={() => setReciboModalVisible(true)}
              >
                <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
                <Text style={styles.addButtonText}>Registrar Recepción ({pzPendientes} pendientes)</Text>
              </TouchableOpacity>
            </>
          )}
          {!isCancelled && pzPendientes <= 0 && pzCortadas > 0 && (
            <>
              <View style={styles.divider} />
              <View style={styles.completeBanner}>
                <Ionicons name="checkmark-circle" size={18} color={Colors.success} />
                <Text style={[styles.addButtonText, { color: Colors.success }]}>Recepción completa</Text>
              </View>
            </>
          )}
        </View>

        <SectionHeader title={`Pagos (${pagos.length})`} />
        <View style={styles.card}>
          {pagos.length > 0 ? (
            pagos.map((pago, i) => (
              <React.Fragment key={pago.id || i}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.reciboRow}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.pagoMonto}>{formatMX(pago.monto)}</Text>
                    <Text style={styles.reciboDate}>{formatDate(pago.fecha_pago)}</Text>
                    {pago.observaciones ? (
                      <Text style={styles.reciboObs}>{pago.observaciones}</Text>
                    ) : null}
                  </View>
                  {!isCancelled && (
                    <TouchableOpacity onPress={() => handleDeletePago(pago)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                      <Ionicons name="trash-outline" size={20} color={Colors.destructive} />
                    </TouchableOpacity>
                  )}
                </View>
              </React.Fragment>
            ))
          ) : (
            <Text style={styles.emptyText}>Sin pagos</Text>
          )}
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Total Pagado</Text>
            <Text style={[styles.infoValue, { color: Colors.success, fontWeight: '600' }]}>{formatMX(totalPagado)}</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.infoRow}>
            <Text style={styles.infoLabel}>Saldo Pendiente</Text>
            <Text style={[styles.infoValue, { color: saldoPendiente > 0 ? Colors.destructive : Colors.success, fontWeight: '600' }]}>
              {formatMX(saldoPendiente)}
            </Text>
          </View>
          {!isCancelled && recibos.length > 0 && (
            <>
              <View style={styles.divider} />
              <TouchableOpacity
                style={styles.addButton}
                onPress={() => openPagoModal(recibos[0].id)}
              >
                <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
                <Text style={styles.addButtonText}>Registrar Pago</Text>
              </TouchableOpacity>
            </>
          )}
        </View>

        {movimientos.length > 0 && (
          <>
            <SectionHeader title="Movimientos" />
            <View style={styles.card}>
              {movimientos.map((mov, i) => (
                <React.Fragment key={i}>
                  {i > 0 && <View style={styles.divider} />}
                  <View style={styles.movRow}>
                    <Ionicons name="time-outline" size={16} color={Colors.textSecondary} />
                    <View style={styles.movContent}>
                      <Text style={styles.movText}>{mov.texto}</Text>
                      <Text style={styles.movDate}>{formatDate(mov.fecha)}</Text>
                    </View>
                  </View>
                </React.Fragment>
              ))}
            </View>
          </>
        )}

        {!isCancelled && (
          <View style={styles.buttonContainer}>
            <Button title="Editar" onPress={handleEdit} />
            <View style={{ height: Spacing.sm }} />
            {!hasRecibos && (
              <Button title="Cancelar Producción" onPress={handleCancel} variant="destructive" />
            )}
          </View>
        )}

        {!isCancelled && !hasRecibos && (
          <View style={styles.buttonContainer}>
            <Button title="Eliminar" onPress={handleDelete} variant="destructive" />
          </View>
        )}

        {isCancelled && !hasRecibos && (
          <View style={styles.buttonContainer}>
            <Button title="Eliminar Producción" onPress={handleDelete} variant="destructive" />
          </View>
        )}

        <View style={{ height: 40 }} />
      </ScrollView>

      <Modal visible={reciboModalVisible} animationType="slide" transparent>
        <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Registrar Recepción</Text>
              <TouchableOpacity onPress={() => setReciboModalVisible(false)}>
                <Text style={styles.modalClose}>Cerrar</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.modalBody}>
              <Text style={styles.inputLabel}>Cantidad * (máximo {pzPendientes})</Text>
              <TextInput
                style={styles.modalInput}
                value={reciboCantidad}
                onChangeText={(text) => {
                  const num = parseInt(text) || 0;
                  if (num > pzPendientes) {
                    setReciboCantidad(String(pzPendientes));
                  } else {
                    setReciboCantidad(text.replace(/[^0-9]/g, ''));
                  }
                }}
                placeholder={`Hasta ${pzPendientes} piezas`}
                placeholderTextColor={Colors.textTertiary}
                keyboardType="number-pad"
              />
              <Text style={styles.inputLabel}>Nombre Entrega</Text>
              <TextInput
                style={styles.modalInput}
                value={reciboNombreEntrega}
                onChangeText={setReciboNombreEntrega}
                placeholder="Nombre de quien entrega"
                placeholderTextColor={Colors.textTertiary}
              />
              <Text style={styles.inputLabel}>Nombre Recepción</Text>
              <TextInput
                style={styles.modalInput}
                value={reciboNombreRecepcion}
                onChangeText={setReciboNombreRecepcion}
                placeholder="Nombre de quien recibe"
                placeholderTextColor={Colors.textTertiary}
              />
              <Text style={styles.inputLabel}>Observaciones</Text>
              <TextInput
                style={[styles.modalInput, { height: 80, textAlignVertical: 'top' }]}
                value={reciboObservaciones}
                onChangeText={setReciboObservaciones}
                placeholder="Observaciones (opcional)"
                placeholderTextColor={Colors.textTertiary}
                multiline
              />
              <TouchableOpacity
                style={[styles.saveButton, reciboSaving && { opacity: 0.6 }]}
                onPress={handleCreateRecibo}
                disabled={reciboSaving}
              >
                {reciboSaving ? (
                  <ActivityIndicator color={Colors.white} />
                ) : (
                  <Text style={styles.saveButtonText}>Guardar Recepción</Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>

      <Modal visible={pagoModalVisible} animationType="slide" transparent>
        <KeyboardAvoidingView style={styles.modalOverlay} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Registrar Pago</Text>
              <TouchableOpacity onPress={() => setPagoModalVisible(false)}>
                <Text style={styles.modalClose}>Cerrar</Text>
              </TouchableOpacity>
            </View>
            <View style={styles.modalBody}>
              <Text style={styles.inputLabel}>Monto *</Text>
              <TextInput
                style={styles.modalInput}
                value={pagoMonto}
                onChangeText={setPagoMonto}
                placeholder="Monto del pago"
                placeholderTextColor={Colors.textTertiary}
                keyboardType="decimal-pad"
              />
              <Text style={styles.inputLabel}>Observaciones</Text>
              <TextInput
                style={[styles.modalInput, { height: 80, textAlignVertical: 'top' }]}
                value={pagoObservaciones}
                onChangeText={setPagoObservaciones}
                placeholder="Observaciones (opcional)"
                placeholderTextColor={Colors.textTertiary}
                multiline
              />
              <TouchableOpacity
                style={[styles.saveButton, pagoSaving && { opacity: 0.6 }]}
                onPress={handleCreatePago}
                disabled={pagoSaving}
              >
                {pagoSaving ? (
                  <ActivityIndicator color={Colors.white} />
                ) : (
                  <Text style={styles.saveButtonText}>Guardar Pago</Text>
                )}
              </TouchableOpacity>
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
  cancelledBanner: {
    backgroundColor: Colors.destructive,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    borderRadius: BorderRadius.sm,
    gap: Spacing.sm,
  },
  cancelledText: {
    color: Colors.white,
    fontSize: FontSize.body,
    fontWeight: '600',
  },
  omNumber: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.primary,
    textAlign: 'center',
    paddingTop: Spacing.sm,
  },
  omDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginTop: Spacing.xs,
  },
  statusBadge: {
    alignSelf: 'center',
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: 12,
    marginTop: Spacing.sm,
    marginBottom: Spacing.sm,
  },
  statusText: {
    fontSize: FontSize.footnote,
    fontWeight: '600',
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
    textAlign: 'right',
    flex: 1,
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
    alignItems: 'center',
    paddingVertical: Spacing.sm,
  },
  reciboQty: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.text,
  },
  reciboDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  reciboObs: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
    marginTop: 2,
    fontStyle: 'italic',
  },
  reciboFirma: {
    fontSize: FontSize.caption,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  pagoMonto: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.success,
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
  completeBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    gap: 6,
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
  },
  movDate: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    textAlign: 'center',
    paddingVertical: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
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
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
  },
  modalTitle: {
    fontSize: FontSize.xl,
    fontWeight: '700',
    color: Colors.text,
  },
  modalClose: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '600',
  },
  modalBody: {
    padding: Spacing.lg,
  },
  inputLabel: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  modalInput: {
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    fontSize: FontSize.body,
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  saveButton: {
    backgroundColor: Colors.primary,
    borderRadius: BorderRadius.sm,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: Spacing.sm,
  },
  saveButtonText: {
    color: Colors.white,
    fontSize: FontSize.body,
    fontWeight: '600',
  },
});
