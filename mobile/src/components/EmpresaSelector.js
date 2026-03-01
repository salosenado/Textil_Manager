import React, { useState, useEffect } from 'react';
import {
  View, Text, StyleSheet, Modal, TouchableOpacity, FlatList,
  SafeAreaView, ActivityIndicator
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';

export default function EmpresaSelector() {
  const { user, empresaActiva, setEmpresaActiva } = useAuth();
  const [visible, setVisible] = useState(false);
  const [empresas, setEmpresas] = useState([]);
  const [loading, setLoading] = useState(false);

  if (!user?.es_root) return null;

  const loadEmpresas = async () => {
    setLoading(true);
    try {
      const data = await api.getEmpresas();
      setEmpresas((data || []).filter(e => e.activa !== false));
    } catch (err) {
      console.error('Error loading empresas:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleOpen = () => {
    setVisible(true);
    loadEmpresas();
  };

  const handleSelect = (empresa) => {
    setEmpresaActiva(empresa);
    setVisible(false);
  };

  const handleClear = () => {
    setEmpresaActiva(null);
    setVisible(false);
  };

  return (
    <>
      <TouchableOpacity style={[styles.selectorButton, empresaActiva && styles.selectorButtonActive]} onPress={handleOpen} activeOpacity={0.7}>
        <Ionicons name="business" size={16} color={empresaActiva ? '#fff' : Colors.primary} />
        <Text style={[styles.selectorText, empresaActiva && styles.selectorTextActive]} numberOfLines={1}>
          {empresaActiva ? empresaActiva.nombre : 'Sin empresa'}
        </Text>
        <Ionicons name="chevron-down" size={14} color={empresaActiva ? '#fff' : Colors.primary} />
      </TouchableOpacity>

      <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView style={styles.modal}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Operar como empresa</Text>
            <TouchableOpacity onPress={() => setVisible(false)}>
              <Text style={styles.modalClose}>Cerrar</Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity
            style={[styles.listItem, !empresaActiva && styles.listItemSelected]}
            onPress={handleClear}
          >
            <View style={styles.listItemContent}>
              <Ionicons name="globe-outline" size={22} color={Colors.textSecondary} style={{ marginRight: 12 }} />
              <View>
                <Text style={[styles.listItemText, !empresaActiva && styles.listItemTextSelected]}>
                  Vista global (Root)
                </Text>
                <Text style={styles.listItemSecondary}>Ver datos de todas las empresas</Text>
              </View>
            </View>
            {!empresaActiva && (
              <Ionicons name="checkmark-circle" size={22} color={Colors.primary} />
            )}
          </TouchableOpacity>

          <View style={styles.divider} />
          <Text style={styles.sectionLabel}>SELECCIONAR EMPRESA</Text>

          {loading ? (
            <View style={styles.loadingContainer}>
              <ActivityIndicator size="large" color={Colors.primary} />
            </View>
          ) : (
            <FlatList
              data={empresas}
              keyExtractor={(item) => item.id}
              contentContainerStyle={styles.listContent}
              ListEmptyComponent={
                <View style={styles.emptyContainer}>
                  <Text style={styles.emptyText}>No hay empresas registradas</Text>
                </View>
              }
              renderItem={({ item }) => {
                const isSelected = empresaActiva?.id === item.id;
                return (
                  <TouchableOpacity
                    style={[styles.listItem, isSelected && styles.listItemSelected]}
                    onPress={() => handleSelect(item)}
                    activeOpacity={0.6}
                  >
                    <View style={styles.listItemContent}>
                      <View style={[styles.iconBadge, { backgroundColor: Colors.primary + '15' }]}>
                        <Ionicons name="business" size={18} color={Colors.primary} />
                      </View>
                      <View style={{ flex: 1 }}>
                        <Text style={[styles.listItemText, isSelected && styles.listItemTextSelected]}>
                          {item.nombre}
                        </Text>
                        {item.rfc && <Text style={styles.listItemSecondary}>{item.rfc}</Text>}
                      </View>
                    </View>
                    {isSelected && (
                      <Ionicons name="checkmark-circle" size={22} color={Colors.primary} />
                    )}
                  </TouchableOpacity>
                );
              }}
            />
          )}
        </SafeAreaView>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  selectorButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary + '15',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 20,
    gap: 5,
    alignSelf: 'flex-start',
  },
  selectorButtonActive: {
    backgroundColor: Colors.primary,
  },
  selectorText: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    fontWeight: '600',
    maxWidth: 120,
  },
  selectorTextActive: {
    color: '#fff',
  },
  modal: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
    backgroundColor: Colors.card,
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
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginHorizontal: Spacing.md,
  },
  sectionLabel: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.textSecondary,
    letterSpacing: 0.5,
    paddingHorizontal: Spacing.lg,
    paddingTop: Spacing.md,
    paddingBottom: Spacing.sm,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  listContent: {
    paddingHorizontal: Spacing.md,
    paddingBottom: Spacing.lg,
  },
  listItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.card,
    paddingHorizontal: Spacing.lg,
    paddingVertical: 14,
    borderRadius: BorderRadius.md,
    marginBottom: 6,
    marginHorizontal: Spacing.md,
  },
  listItemSelected: {
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  listItemContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  listItemText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  listItemTextSelected: {
    fontWeight: '600',
    color: Colors.primary,
  },
  listItemSecondary: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  iconBadge: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingTop: 60,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
});
