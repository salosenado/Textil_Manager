import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';

const CATALOG_GROUPS = [
  {
    title: 'Comerciales',
    icon: 'briefcase',
    color: Colors.primary,
    items: [
      { key: 'agentes', label: 'Agentes' },
      { key: 'clientes', label: 'Clientes' },
      { key: 'proveedores', label: 'Proveedores' },
    ],
  },
  {
    title: 'Artículo',
    icon: 'pricetag',
    color: Colors.orange,
    items: [
      { key: 'articulos', label: 'Artículos' },
      { key: 'colores', label: 'Colores' },
      { key: 'departamentos', label: 'Departamentos' },
      { key: 'lineas', label: 'Líneas' },
      { key: 'marcas', label: 'Marcas' },
      { key: 'modelos', label: 'Modelos' },
      { key: 'tallas', label: 'Tallas' },
      { key: 'telas', label: 'Telas' },
      { key: 'tipos_tela', label: 'Tipos de Tela' },
      { key: 'unidades', label: 'Unidades' },
    ],
  },
  {
    title: 'Operativos',
    icon: 'construct',
    color: Colors.teal,
    items: [
      { key: 'maquileros', label: 'Maquileros' },
    ],
  },
  {
    title: 'Servicios',
    icon: 'build',
    color: Colors.purple,
    items: [
      { key: 'servicios', label: 'Servicios' },
    ],
  },
];

export default function CatalogosHomeScreen({ navigation }) {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {CATALOG_GROUPS.map((group) => (
        <View key={group.title} style={styles.section}>
          <View style={styles.sectionHeader}>
            <Ionicons name={group.icon} size={16} color={group.color} />
            <Text style={styles.sectionTitle}>{group.title}</Text>
          </View>
          <View style={styles.card}>
            {group.items.map((item, i) => (
              <React.Fragment key={item.key}>
                {i > 0 && <View style={styles.divider} />}
                <TouchableOpacity
                  style={styles.row}
                  activeOpacity={0.6}
                  onPress={() => navigation.navigate('CatalogList', { catalogo: item.key, title: item.label })}
                >
                  <Text style={styles.rowText}>{item.label}</Text>
                  <Ionicons name="chevron-forward" size={18} color={Colors.textTertiary} />
                </TouchableOpacity>
              </React.Fragment>
            ))}
          </View>
        </View>
      ))}
      <View style={{ height: 30 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: Spacing.md,
  },
  section: {
    marginBottom: Spacing.md,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: Spacing.sm,
    marginBottom: Spacing.xs,
  },
  sectionTitle: {
    fontSize: FontSize.subheadline,
    color: Colors.textSecondary,
    textTransform: 'uppercase',
    fontWeight: '500',
  },
  card: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: Spacing.md,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginLeft: 0,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 13,
  },
  rowText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
});
