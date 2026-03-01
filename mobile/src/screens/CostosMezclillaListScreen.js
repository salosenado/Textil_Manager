import React, { useState, useCallback, useRef } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, ActivityIndicator, TouchableOpacity, TextInput } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

function formatMoney(value) {
  const num = parseFloat(value) || 0;
  return 'MX $' + num.toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateStr) {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  return d.toLocaleDateString('es-MX', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function CostosMezclillaListScreen({ navigation }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');
  const debounceRef = useRef(null);
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const loadItems = async (searchVal) => {
    try {
      const data = await api.getCostosMezclilla(searchVal ?? debouncedSearch);
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
    }, [debouncedSearch])
  );

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: 'Costos Mezclilla',
      headerRight: () => (
        <TouchableOpacity onPress={() => navigation.navigate('CostoMezclillaForm')}>
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

  const renderItem = ({ item }) => {
    const total = parseFloat(item.total) || 0;
    const totalConGastos = parseFloat(item.total_con_gastos) || 0;

    return (
      <TouchableOpacity
        activeOpacity={0.7}
        style={styles.card}
        onPress={() => navigation.navigate('CostoMezclillaDetalle', { id: item.id })}
      >
        <View style={styles.cardHeader}>
          <View style={styles.cardLeft}>
            <Text style={styles.modeloText} numberOfLines={1}>
              {item.modelo || 'Sin modelo'}
            </Text>
          </View>
        </View>

        {item.tela ? (
          <Text style={styles.captionText} numberOfLines={1}>
            <Ionicons name="layers-outline" size={12} color={Colors.textSecondary} /> {item.tela}
          </Text>
        ) : null}

        {item.fecha ? (
          <Text style={styles.captionText}>{formatDate(item.fecha)}</Text>
        ) : null}

        <View style={styles.cardFooter}>
          <Text style={styles.subtotalText}>Total: {formatMoney(total)}</Text>
          <Text style={styles.totalText}>{formatMoney(totalConGastos)}</Text>
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
          placeholder="Buscar modelo, tela..."
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

      {items.length === 0 ? (
        <View style={styles.centered}>
          <Ionicons name="calculator-outline" size={48} color={Colors.textTertiary} />
          <Text style={styles.emptyText}>
            {search ? 'Sin resultados' : 'No hay costos de mezclilla'}
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
  captionText: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginBottom: 2,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: Spacing.xs,
  },
  subtotalText: {
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
