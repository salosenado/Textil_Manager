import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';

const SECTIONS = [
  {
    title: 'Ventas',
    icon: 'cart',
    color: Colors.orange,
    items: [
      { key: 'OrdenesClienteList', label: 'Órdenes de Cliente', icon: 'document-text-outline', description: 'Pedidos y órdenes de venta' },
    ],
  },
  {
    title: 'Compras',
    icon: 'bag',
    color: Colors.teal,
    items: [
      { key: 'ComprasClienteList', label: 'Compras de Cliente', icon: 'people-outline', description: 'Órdenes de compra a proveedores' },
      { key: 'ComprasInsumoList', label: 'Compras de Insumo', icon: 'cube-outline', description: 'Compras de materiales e insumos' },
    ],
  },
];

export default function OrdenesHomeScreen({ navigation }) {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {SECTIONS.map((section) => (
        <View key={section.title} style={styles.section}>
          <View style={styles.sectionHeader}>
            <Ionicons name={section.icon} size={16} color={section.color} />
            <Text style={styles.sectionTitle}>{section.title}</Text>
          </View>
          <View style={styles.card}>
            {section.items.map((item, i) => (
              <React.Fragment key={item.key}>
                {i > 0 && <View style={styles.divider} />}
                <TouchableOpacity
                  style={styles.row}
                  activeOpacity={0.6}
                  onPress={() => navigation.navigate(item.key)}
                >
                  <View style={styles.rowLeft}>
                    <View style={[styles.iconContainer, { backgroundColor: section.color + '20' }]}>
                      <Ionicons name={item.icon} size={20} color={section.color} />
                    </View>
                    <View style={styles.rowTextContainer}>
                      <Text style={styles.rowText}>{item.label}</Text>
                      <Text style={styles.rowDescription}>{item.description}</Text>
                    </View>
                  </View>
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
  rowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  iconContainer: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  rowTextContainer: {
    flex: 1,
  },
  rowText: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  rowDescription: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
});
