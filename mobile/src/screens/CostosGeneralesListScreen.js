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
  const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
}

export default function CostosGeneralesListScreen({ navigation }) {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');
  const debounceRef = useRef(null);
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const loadItems = async (searchVal) => {
    try {
      const data = await api.getCostosGenerales(searchVal ?? debouncedSearch);
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
      title: 'Costos Generales',
      headerRight: () => (
        <TouchableOpacity onPress={() => navigation.navigate('CostoGeneralForm')}>
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
        onPress={() => navigation.navigate('CostoGeneralDetalle', { id: item.id })}
      >
        <View style={styles.cardHeader}>
          <Text style={styles.modeloText} numberOfLines={1}>
            {item.modelo || 'Sin modelo'}
          </Text>
        </View>
        {item.departamento_nombre ? (
          <Text style={styles.captionText} numberOfLines={1}>
            <Ionicons name="business-outline" size={12} color={Colors.textSecondary} /> {item.departamento_nombre}
          </Text>
        ) : null}
        {item.linea_nombre ? (
          <Text style={styles.captionText} numberOfLines={1}>Línea: {item.linea_nombre}</Text>
        ) : null}
        {item.tallas ? (
          <Text style={styles.captionText} numberOfLines={1}>Tallas: {item.tallas}</Text>
        ) : null}
        <View style={styles.cardFooter}>
          <Text style={styles.dateText}>{formatDate(item.fecha || item.created_at)}</Text>
          <View style={styles.totalsCol}>
            <Text style={styles.totalLabel}>Total + 15%</Text>
            <Text style={styles.totalText}>{formatMoney(totalConGastos)}</Text>
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
          placeholder="Buscar modelo, descripción..."
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
            {search ? 'Sin resultados' : 'No hay costos generales'}
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
    alignItems: 'flex-end',
    marginTop: Spacing.xs,
  },
  dateText: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
  },
  totalsCol: {
    alignItems: 'flex-end',
  },
  totalLabel: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
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
