import React, { useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, ActivityIndicator, TouchableOpacity, TextInput, ScrollView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

const ESTADOS = [
  { key: 'activas', label: 'Activas' },
  { key: 'canceladas', label: 'Canceladas' },
  { key: 'todas', label: 'Todas' },
];

function formatMoney(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function getStatus(item) {
  if (item.cancelada) return { label: 'Cancelada', color: Colors.error };
  const recibido = parseInt(item.total_recibido) || 0;
  const cortadas = parseInt(item.pz_cortadas) || 0;
  if (recibido === 0) return { label: 'En producción', color: Colors.error };
  if (recibido < cortadas) return { label: 'Parcial', color: Colors.orange };
  return { label: 'Completa', color: Colors.success };
}

export default function ProduccionListScreen({ navigation }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');
  const [estado, setEstado] = useState('activas');
  const debounceRef = useRef(null);
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const loadItems = async (searchVal) => {
    try {
      const data = await api.getProducciones({ search: searchVal ?? debouncedSearch, estado });
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
      loadItems(debouncedSearch);
    }, [debouncedSearch, estado])
  );

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Producción',
      headerRight: () => (
        <TouchableOpacity onPress={() => navigation.navigate('ProduccionForm')}>
          <Ionicons name="add" size={28} color={Colors.primary} />
        </TouchableOpacity>
      ),
    });
  }, [navigation]);

  const handleSearch = (text) => {
    setSearch(text);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setDebouncedSearch(text);
    }, 400);
  };

  const handleRefresh = () => {
    setRefreshing(true);
    loadItems(debouncedSearch);
  };

  const renderFilterChips = (options, selected, onSelect) => (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipsScroll} contentContainerStyle={styles.chipsContainer}>
      {options.map((opt) => (
        <TouchableOpacity
          key={opt.key}
          style={[styles.chip, selected === opt.key && styles.chipActive]}
          onPress={() => onSelect(opt.key)}
          activeOpacity={0.7}
        >
          <Text style={[styles.chipText, selected === opt.key && styles.chipTextActive]}>{opt.label}</Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );

  const renderItem = ({ item }) => {
    const status = getStatus(item);
    const recibido = parseInt(item.total_recibido) || 0;
    const cortadas = parseInt(item.pz_cortadas) || 0;
    const total = (parseFloat(item.pz_cortadas) || 0) * (parseFloat(item.costo_maquila) || 0);

    return (
      <TouchableOpacity
        activeOpacity={0.7}
        style={styles.card}
        onPress={() => navigation.navigate('ProduccionDetalle', { id: item.id })}
      >
        <View style={styles.cardHeader}>
          <View style={styles.cardLeft}>
            <Text style={styles.modeloText} numberOfLines={1}>
              {item.modelo_nombre || item.articulo_nombre || 'Sin modelo'}
            </Text>
          </View>
          <View style={[styles.badge, { backgroundColor: status.color + '20' }]}>
            <Text style={[styles.badgeText, { color: status.color }]}>{status.label}</Text>
          </View>
        </View>

        <Text style={styles.captionText} numberOfLines={1}>
          <Ionicons name="person-outline" size={12} color={Colors.textSecondary} /> {item.maquilero_nombre || 'Sin maquilero'}
        </Text>
        {item.articulo_nombre ? (
          <Text style={styles.captionText} numberOfLines={1}>Artículo: {item.articulo_nombre}</Text>
        ) : null}
        {item.cliente_nombre ? (
          <Text style={styles.captionText} numberOfLines={1}>Cliente: {item.cliente_nombre}</Text>
        ) : null}
        {item.orden_maquila ? (
          <Text style={styles.omText}>{item.orden_maquila}</Text>
        ) : null}

        <View style={styles.cardFooter}>
          <Text style={styles.pzText}>{recibido}/{cortadas} PZ</Text>
          <Text style={styles.totalText}>{formatMoney(total)}</Text>
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
          placeholder="Buscar modelo, maquilero, cliente..."
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

      {renderFilterChips(ESTADOS, estado, setEstado)}

      {items.length === 0 ? (
        <View style={styles.centered}>
          <Ionicons name="construct-outline" size={48} color={Colors.textTertiary} />
          <Text style={styles.emptyText}>
            {search ? 'Sin resultados' : 'No hay producciones'}
          </Text>
        </View>
      ) : (
        <FlatList
          contentContainerStyle={styles.list}
          data={items}
          keyExtractor={(item) => String(item.id)}
          renderItem={renderItem}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
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
  chipsScroll: {
    flexGrow: 0,
  },
  chipsContainer: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    gap: Spacing.sm,
    flexDirection: 'row',
  },
  chip: {
    paddingHorizontal: Spacing.md,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: Colors.card,
  },
  chipActive: {
    backgroundColor: Colors.primary,
  },
  chipText: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  chipTextActive: {
    color: Colors.white,
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
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  cardLeft: {
    flex: 1,
    marginRight: Spacing.sm,
  },
  modeloText: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  badgeText: {
    fontSize: FontSize.caption,
    fontWeight: '600',
  },
  captionText: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 2,
  },
  omText: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    fontWeight: '500',
    marginTop: 2,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: Spacing.xs,
  },
  pzText: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    fontWeight: '500',
  },
  totalText: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.success,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
});
