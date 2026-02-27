import React, { useState, useEffect, useCallback } from 'react';
import {
  View, Text, StyleSheet, Modal, TouchableOpacity, FlatList,
  TextInput, ActivityIndicator, SafeAreaView, KeyboardAvoidingView, Platform
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

export default function CatalogPicker({
  label,
  catalogo,
  value,
  displayValue,
  onSelect,
  displayField = 'nombre',
  secondaryField,
  placeholder,
  allowCreate = true,
}) {
  const [visible, setVisible] = useState(false);
  const [items, setItems] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [newName, setNewName] = useState('');
  const [createError, setCreateError] = useState('');

  const loadItems = useCallback(async () => {
    setLoading(true);
    try {
      const data = await api.getCatalogItems(catalogo, search || undefined);
      setItems((data || []).filter(item => item.activo !== false));
    } catch (err) {
      console.error(`Error loading ${catalogo}:`, err);
    } finally {
      setLoading(false);
    }
  }, [catalogo, search]);

  useEffect(() => {
    if (visible) {
      loadItems();
    }
  }, [visible, loadItems]);

  const handleSelect = (item) => {
    onSelect(item);
    setVisible(false);
    setSearch('');
    setCreating(false);
  };

  const handleClear = () => {
    onSelect(null);
  };

  const handleCreate = async () => {
    if (!newName.trim()) return;
    setCreateError('');
    try {
      const created = await api.createCatalogItem(catalogo, { nombre: newName.trim() });
      setCreating(false);
      setNewName('');
      handleSelect(created);
    } catch (err) {
      setCreateError(err.message || 'Error al crear');
    }
  };

  const getDisplay = () => {
    if (displayValue) return displayValue;
    return placeholder || 'Seleccionar...';
  };

  const hasValue = !!value || !!displayValue;

  return (
    <View style={styles.container}>
      {label && <Text style={styles.label}>{label}</Text>}
      <TouchableOpacity
        style={[styles.selector, hasValue && styles.selectorActive]}
        onPress={() => setVisible(true)}
        activeOpacity={0.6}
      >
        <Text style={[styles.selectorText, !hasValue && styles.selectorPlaceholder]} numberOfLines={1}>
          {getDisplay()}
        </Text>
        <View style={styles.selectorRight}>
          {hasValue && (
            <TouchableOpacity onPress={handleClear} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
            </TouchableOpacity>
          )}
          <Ionicons name="chevron-down" size={18} color={Colors.textSecondary} style={{ marginLeft: 6 }} />
        </View>
      </TouchableOpacity>

      <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
        <SafeAreaView style={styles.modal}>
          <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>{label || 'Seleccionar'}</Text>
              <TouchableOpacity onPress={() => { setVisible(false); setCreating(false); setSearch(''); }}>
                <Text style={styles.modalClose}>Cerrar</Text>
              </TouchableOpacity>
            </View>

            <View style={styles.searchContainer}>
              <Ionicons name="search" size={18} color={Colors.textTertiary} />
              <TextInput
                style={styles.searchInput}
                value={search}
                onChangeText={setSearch}
                placeholder="Buscar..."
                placeholderTextColor={Colors.textTertiary}
                autoCapitalize="none"
                returnKeyType="search"
                onSubmitEditing={loadItems}
              />
              {search ? (
                <TouchableOpacity onPress={() => setSearch('')}>
                  <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
                </TouchableOpacity>
              ) : null}
            </View>

            {loading ? (
              <View style={styles.loadingContainer}>
                <ActivityIndicator size="large" color={Colors.primary} />
              </View>
            ) : (
              <FlatList
                data={items}
                keyExtractor={(item) => item.id}
                contentContainerStyle={styles.listContent}
                keyboardShouldPersistTaps="handled"
                ListEmptyComponent={
                  <View style={styles.emptyContainer}>
                    <Ionicons name="search-outline" size={40} color={Colors.textTertiary} />
                    <Text style={styles.emptyText}>Sin resultados</Text>
                  </View>
                }
                renderItem={({ item }) => {
                  const isSelected = value === item.id;
                  const primary = item[displayField] || item.nombre || item.nombre_comercial || '';
                  const secondary = secondaryField ? item[secondaryField] : null;
                  return (
                    <TouchableOpacity
                      style={[styles.listItem, isSelected && styles.listItemSelected]}
                      onPress={() => handleSelect(item)}
                      activeOpacity={0.6}
                    >
                      <View style={styles.listItemContent}>
                        <Text style={[styles.listItemText, isSelected && styles.listItemTextSelected]}>
                          {primary}
                        </Text>
                        {secondary ? (
                          <Text style={styles.listItemSecondary}>{secondary}</Text>
                        ) : null}
                      </View>
                      {isSelected && (
                        <Ionicons name="checkmark-circle" size={22} color={Colors.primary} />
                      )}
                    </TouchableOpacity>
                  );
                }}
              />
            )}

            {allowCreate && !creating && (
              <TouchableOpacity style={styles.createButton} onPress={() => { setCreating(true); setNewName(search); }}>
                <Ionicons name="add-circle-outline" size={20} color={Colors.primary} />
                <Text style={styles.createButtonText}>Crear nuevo</Text>
              </TouchableOpacity>
            )}

            {creating && (
              <View style={styles.createForm}>
                <TextInput
                  style={styles.createInput}
                  value={newName}
                  onChangeText={setNewName}
                  placeholder="Nombre del nuevo registro"
                  placeholderTextColor={Colors.textTertiary}
                  autoFocus
                />
                {createError ? <Text style={styles.createError}>{createError}</Text> : null}
                <View style={styles.createActions}>
                  <TouchableOpacity style={styles.createCancel} onPress={() => { setCreating(false); setCreateError(''); }}>
                    <Text style={styles.createCancelText}>Cancelar</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.createConfirm} onPress={handleCreate}>
                    <Text style={styles.createConfirmText}>Crear</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}
          </KeyboardAvoidingView>
        </SafeAreaView>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: Spacing.lg,
  },
  label: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    minHeight: 44,
  },
  selectorActive: {
    borderWidth: 1,
    borderColor: Colors.primary + '40',
  },
  selectorText: {
    fontSize: FontSize.lg,
    color: Colors.text,
    flex: 1,
  },
  selectorPlaceholder: {
    color: Colors.textTertiary,
  },
  selectorRight: {
    flexDirection: 'row',
    alignItems: 'center',
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    margin: Spacing.md,
    paddingHorizontal: Spacing.md,
    paddingVertical: Platform.OS === 'ios' ? Spacing.sm : 0,
  },
  searchInput: {
    flex: 1,
    fontSize: FontSize.body,
    color: Colors.text,
    paddingHorizontal: Spacing.sm,
    paddingVertical: Spacing.sm,
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
  },
  listItemSelected: {
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  listItemContent: {
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
  emptyContainer: {
    alignItems: 'center',
    paddingTop: 60,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
  createButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.separator,
    backgroundColor: Colors.card,
    gap: 6,
  },
  createButtonText: {
    fontSize: FontSize.body,
    color: Colors.primary,
    fontWeight: '600',
  },
  createForm: {
    padding: Spacing.md,
    borderTopWidth: 1,
    borderTopColor: Colors.separator,
    backgroundColor: Colors.card,
  },
  createInput: {
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    fontSize: FontSize.body,
    color: Colors.text,
    marginBottom: Spacing.sm,
  },
  createError: {
    color: Colors.error,
    fontSize: FontSize.caption,
    marginBottom: Spacing.sm,
  },
  createActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: Spacing.md,
  },
  createCancel: {
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.lg,
  },
  createCancelText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
  },
  createConfirm: {
    paddingVertical: Spacing.sm,
    paddingHorizontal: Spacing.lg,
    backgroundColor: Colors.primary,
    borderRadius: BorderRadius.sm,
  },
  createConfirmText: {
    fontSize: FontSize.body,
    color: '#fff',
    fontWeight: '600',
  },
});
