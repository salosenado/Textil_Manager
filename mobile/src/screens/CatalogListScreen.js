import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, FlatList, RefreshControl, ActivityIndicator, TouchableOpacity, TextInput, Alert } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';

const CATALOG_SUBTITLES = {
  agentes: (item) => [item.apellido, item.telefono, item.email].filter(Boolean).join(' · '),
  clientes: (item) => [item.contacto, item.telefono, item.email].filter(Boolean).join(' · '),
  proveedores: (item) => [item.contacto, item.telefono_principal, item.email].filter(Boolean).join(' · '),
  articulos: (item) => [item.sku, item.descripcion].filter(Boolean).join(' · '),
  modelos: (item) => [item.codigo, item.descripcion].filter(Boolean).join(' · '),
  marcas: (item) => [item.dueno, item.regalia_porcentaje ? `${item.regalia_porcentaje}%` : null].filter(Boolean).join(' · '),
  unidades: (item) => [item.abreviatura, item.factor ? `Factor: ${item.factor}` : null].filter(Boolean).join(' · '),
  telas: (item) => [item.composicion, item.descripcion].filter(Boolean).join(' · '),
  maquileros: (item) => [item.contacto, item.telefono_principal].filter(Boolean).join(' · '),
  servicios: (item) => [item.descripcion, item.costo ? `$${Number(item.costo).toFixed(2)}` : null].filter(Boolean).join(' · '),
  tallas: (item) => item.orden ? `Orden: ${item.orden}` : '',
};

const CATALOG_NAME_FIELD = {
  clientes: 'nombre_comercial',
};

const CATALOG_ACTIVE_FIELD = {
  telas: 'activa',
};

export default function CatalogListScreen({ route, navigation }) {
  const { catalogo, title } = route.params;
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState('');

  const nameField = CATALOG_NAME_FIELD[catalogo] || 'nombre';
  const activeField = CATALOG_ACTIVE_FIELD[catalogo] || 'activo';

  const loadItems = async (searchText) => {
    try {
      const data = await api.getCatalogItems(catalogo, searchText);
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
      loadItems(search);
    }, [catalogo])
  );

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title,
      headerRight: () => (
        <TouchableOpacity onPress={() => navigation.navigate('CatalogForm', { catalogo, title })}>
          <Ionicons name="add" size={28} color={Colors.primary} />
        </TouchableOpacity>
      ),
    });
  }, [navigation, title, catalogo]);

  const handleSearch = (text) => {
    setSearch(text);
    loadItems(text);
  };

  const handleDelete = (item) => {
    const name = item[nameField];
    Alert.alert(
      'Eliminar',
      `¿Estás seguro de eliminar "${name}"?`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCatalogItem(catalogo, item.id);
              loadItems(search);
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  const getSubtitle = CATALOG_SUBTITLES[catalogo] || (() => '');

  const renderItem = ({ item }) => {
    const isActive = item[activeField] !== false;
    const subtitle = getSubtitle(item);

    return (
      <TouchableOpacity
        activeOpacity={0.7}
        style={styles.card}
        onPress={() => navigation.navigate('CatalogForm', { catalogo, title, item })}
        onLongPress={() => handleDelete(item)}
      >
        <View style={styles.row}>
          <View style={styles.info}>
            <View style={styles.nameRow}>
              <Text style={styles.nombre}>{item[nameField]}</Text>
              {!isActive && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>Inactivo</Text>
                </View>
              )}
            </View>
            {subtitle ? <Text style={styles.subtitle} numberOfLines={1}>{subtitle}</Text> : null}
          </View>
          <Ionicons name="chevron-forward" size={18} color={Colors.textTertiary} />
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
          placeholder="Buscar..."
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
          <Ionicons name="folder-open-outline" size={48} color={Colors.textTertiary} />
          <Text style={styles.emptyText}>{search ? 'Sin resultados' : `No hay ${title.toLowerCase()}`}</Text>
        </View>
      ) : (
        <FlatList
          contentContainerStyle={styles.list}
          data={items}
          keyExtractor={(item) => item.id}
          renderItem={renderItem}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadItems(search); }} />}
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
  nombre: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  badge: {
    backgroundColor: Colors.error + '20',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
  },
  badgeText: {
    fontSize: FontSize.caption,
    color: Colors.error,
    fontWeight: '600',
  },
  subtitle: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 3,
  },
  emptyText: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginTop: Spacing.md,
  },
});
