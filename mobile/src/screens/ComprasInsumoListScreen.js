import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, ActivityIndicator, TouchableOpacity, TextInput } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

const PERIODOS = [
  { key: '', label: 'Todos' },
  { key: 'semana', label: 'Semana' },
  { key: 'mes', label: 'Mes' },
  { key: 'anio', label: 'Año' },
];

function formatMX(valor) {
  const num = Number(valor) || 0;
  return `MX $${num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',')}`;
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function ComprasInsumoListScreen({ navigation }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');
  const [periodo, setPeriodo] = useState('');

  const loadItems = async (searchText, periodoVal) => {
    try {
      const data = await api.getComprasInsumo(searchText, periodoVal);
      setItems(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      setLoading(true);
      loadItems(search, periodo);
    }, [])
  );

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Compras de Insumo',
      headerRight: () => (
        <TouchableOpacity onPress={() => navigation.navigate('ComprasInsumoForm')}>
          <Ionicons name="add" size={28} color={Colors.primary} />
        </TouchableOpacity>
      ),
    });
  }, [navigation]);

  const handleSearch = (text) => {
    setSearch(text);
    loadItems(text, periodo);
  };

  const handlePeriodo = (val) => {
    setPeriodo(val);
    loadItems(search, val);
  };

  const calcTotal = (item) => {
    return Number(item.total) || 0;
  };

  const renderItem = ({ item }) => {
    return (
      <TouchableOpacity
        activeOpacity={0.7}
        style={styles.card}
        onPress={() => navigation.navigate('ComprasInsumoDetalle', { id: item.id })}
      >
        <View style={styles.row}>
          <View style={styles.info}>
            <View style={styles.nameRow}>
              <Text style={styles.folio}>OCI-{item.numero_compra}</Text>
            </View>
            <Text style={styles.proveedor} numberOfLines={1}>
              {item.proveedor_cliente || 'Sin proveedor'}
            </Text>
            <Text style={styles.subtitle}>
              {formatDate(item.fecha_creacion)}
            </Text>
          </View>
          <View style={styles.rightCol}>
            <Text style={styles.total}>{formatMX(calcTotal(item))}</Text>
            <Ionicons name="chevron-forward" size={18} color={Colors.textTertiary} />
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.searchContainer}>
        <Ionicons name="search" size={18} color={Colors.textTertiary} style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar por proveedor..."
          placeholderTextColor={Colors.textTertiary}
          value={search}
          onChangeText={handleSearch}
          returnKeyType="search"
        />
        {search.length > 0 && (
          <TouchableOpacity onPress={() => handleSearch('')}>
            <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.filterRow}>
        {PERIODOS.map((p) => (
          <TouchableOpacity
            key={p.key}
            style={[styles.filterChip, periodo === p.key && styles.filterChipActive]}
            onPress={() => handlePeriodo(p.key)}
          >
            <Text style={[styles.filterChipText, periodo === p.key && styles.filterChipTextActive]}>
              {p.label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {items.length === 0 ? (
        <View style={styles.centered}>
          <Ionicons name="cube-outline" size={48} color={Colors.textTertiary} />
          <Text style={styles.emptyText}>{search ? 'Sin resultados' : 'No hay compras de insumo'}</Text>
        </View>
      ) : (
        <FlatList
          contentContainerStyle={styles.list}
          data={items}
          keyExtractor={(item) => String(item.id)}
          renderItem={renderItem}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={() => {
                setRefreshing(true);
                loadItems(search, periodo);
              }}
            />
          }
        />
      )}
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
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.card,
    marginHorizontal: Spacing.md,
    marginTop: Spacing.sm,
    marginBottom: Spacing.xs,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.sm,
    height: 40,
  },
  searchIcon: {
    marginRight: Spacing.xs,
  },
  searchInput: {
    flex: 1,
    fontSize: FontSize.body,
    color: Colors.text,
    paddingVertical: 0,
  },
  filterRow: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    gap: 8,
  },
  filterChip: {
    paddingHorizontal: 14,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: Colors.card,
    borderWidth: 1,
    borderColor: Colors.separator,
  },
  filterChipActive: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  filterChipText: {
    fontSize: FontSize.footnote,
    color: Colors.text,
  },
  filterChipTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  list: {
    padding: Spacing.md,
    paddingTop: Spacing.xs,
  },
  card: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    marginBottom: Spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  info: {
    flex: 1,
  },
  nameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  folio: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  proveedor: {
    fontSize: FontSize.body,
    color: Colors.text,
    marginTop: 2,
  },
  subtitle: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 3,
  },
  rightCol: {
    alignItems: 'flex-end',
    gap: 4,
  },
  total: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.primary,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
});
