import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';

const quickLinks = [
  { id: 'catalogos', title: 'Catálogos', icon: 'list-outline', color: Colors.primary, permiso: 'catalogos.ver', screen: 'OperacionTab' },
  { id: 'ordenes', title: 'Órdenes', icon: 'document-text-outline', color: Colors.orange, permiso: 'ordenes.ver', screen: 'OperacionTab' },
  { id: 'produccion', title: 'Producción', icon: 'construct-outline', color: Colors.success, permiso: 'produccion.ver', screen: 'OperacionTab' },
  { id: 'ventas', title: 'Ventas', icon: 'cart-outline', color: Colors.purple, permiso: 'ventas.ver', screen: 'VentasTab' },
  { id: 'compras', title: 'Compras', icon: 'bag-outline', color: Colors.teal, permiso: 'compras.ver', screen: 'ComprasTab' },
  { id: 'usuarios', title: 'Usuarios', icon: 'people-outline', color: Colors.warning, permiso: 'usuarios.ver', screen: 'AdminTab' },
];

export default function HomeScreen({ navigation }) {
  const { user, tienePermiso } = useAuth();

  const visibleLinks = quickLinks.filter(link => tienePermiso(link.permiso));

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.greeting}>
        <Text style={styles.greetingText}>Hola,</Text>
        <Text style={styles.userName}>{user?.nombre || 'Usuario'}</Text>
      </View>

      {user?.es_root && (
        <View style={styles.rootBadge}>
          <Ionicons name="shield-checkmark" size={16} color={Colors.white} />
          <Text style={styles.rootText}>Administrador del Sistema</Text>
        </View>
      )}

      <Text style={styles.sectionTitle}>Acceso Rápido</Text>
      <View style={styles.grid}>
        {visibleLinks.map(link => (
          <TouchableOpacity
            key={link.id}
            style={styles.gridItem}
            activeOpacity={0.7}
            onPress={() => {
              if (link.screen === 'AdminTab') {
                navigation.navigate('AdminTab', { screen: 'UsuariosScreen' });
              } else {
                navigation.navigate(link.screen);
              }
            }}
          >
            <View style={[styles.gridIcon, { backgroundColor: link.color + '20' }]}>
              <Ionicons name={link.icon} size={28} color={link.color} />
            </View>
            <Text style={styles.gridLabel}>{link.title}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <Text style={styles.sectionTitle}>Resumen</Text>
      <View style={styles.summaryCard}>
        <Text style={styles.summaryText}>Las estadísticas del sistema se mostrarán aquí conforme se agreguen los módulos.</Text>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  content: {
    padding: Spacing.lg,
    paddingTop: Spacing.xl,
  },
  greeting: {
    marginBottom: Spacing.lg,
  },
  greetingText: {
    fontSize: FontSize.xl,
    color: Colors.textSecondary,
  },
  userName: {
    fontSize: FontSize.largeTitle,
    fontWeight: '700',
    color: Colors.text,
  },
  rootBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.sm,
    alignSelf: 'flex-start',
    marginBottom: Spacing.xl,
    gap: 6,
  },
  rootText: {
    color: Colors.white,
    fontSize: FontSize.sm,
    fontWeight: '600',
  },
  sectionTitle: {
    fontSize: FontSize.xl,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: Spacing.md,
    marginTop: Spacing.md,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
  },
  gridItem: {
    width: '30%',
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
    alignItems: 'center',
  },
  gridIcon: {
    width: 52,
    height: 52,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.sm,
  },
  gridLabel: {
    fontSize: FontSize.sm,
    fontWeight: '500',
    color: Colors.text,
    textAlign: 'center',
  },
  summaryCard: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.xl,
  },
  summaryText: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});
