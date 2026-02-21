import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl, ActivityIndicator } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import Card from '../components/Card';
import ListRow from '../components/ListRow';
import SectionHeader from '../components/SectionHeader';

export default function RootPanelScreen({ navigation }) {
  const { user } = useAuth();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadStats = async () => {
    try {
      const data = await api.getEmpresasStats();
      setStats(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadStats();
    }, [])
  );

  const onRefresh = () => {
    setRefreshing(true);
    loadStats();
  };

  if (loading) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      <View style={styles.header}>
        <Text style={styles.welcome}>Panel de Administración</Text>
        <Text style={styles.subtitle}>Bienvenido, {user?.nombre}</Text>
      </View>

      <View style={styles.statsGrid}>
        <View style={styles.statCard}>
          <View style={[styles.statIcon, { backgroundColor: Colors.primary + '20' }]}>
            <Ionicons name="business" size={24} color={Colors.primary} />
          </View>
          <Text style={styles.statNumber}>{stats?.empresas?.total || 0}</Text>
          <Text style={styles.statLabel}>Empresas</Text>
          <Text style={styles.statSub}>{stats?.empresas?.activas || 0} activas</Text>
        </View>
        <View style={styles.statCard}>
          <View style={[styles.statIcon, { backgroundColor: Colors.success + '20' }]}>
            <Ionicons name="people" size={24} color={Colors.success} />
          </View>
          <Text style={styles.statNumber}>{stats?.usuarios?.total || 0}</Text>
          <Text style={styles.statLabel}>Usuarios</Text>
          <Text style={styles.statSub}>{stats?.usuarios?.activos || 0} activos</Text>
        </View>
      </View>

      {stats?.pendientes > 0 && (
        <Card style={styles.alertCard} onPress={() => navigation.navigate('AprobacionUsuarios')}>
          <View style={styles.alertRow}>
            <View style={[styles.alertIcon, { backgroundColor: Colors.warning + '20' }]}>
              <Ionicons name="alert-circle" size={24} color={Colors.warning} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.alertTitle}>{stats.pendientes} usuario{stats.pendientes > 1 ? 's' : ''} pendiente{stats.pendientes > 1 ? 's' : ''}</Text>
              <Text style={styles.alertSub}>Requieren aprobación</Text>
            </View>
            <Ionicons name="chevron-forward" size={20} color={Colors.textTertiary} />
          </View>
        </Card>
      )}

      <SectionHeader title="Gestión del Sistema" />
      <Card style={styles.menuCard}>
        <ListRow
          title="Empresas"
          subtitle="Crear, editar y administrar empresas"
          icon="business-outline"
          iconColor={Colors.primary}
          onPress={() => navigation.navigate('EmpresasScreen')}
        />
        <View style={styles.separator} />
        <ListRow
          title="Usuarios Pendientes"
          subtitle="Aprobar nuevos usuarios"
          icon="person-add-outline"
          iconColor={Colors.warning}
          onPress={() => navigation.navigate('AprobacionUsuarios')}
          badge={stats?.pendientes > 0 ? { text: String(stats.pendientes), color: Colors.warning } : null}
        />
        <View style={styles.separator} />
        <ListRow
          title="Todos los Usuarios"
          subtitle="Ver usuarios de todas las empresas"
          icon="people-outline"
          iconColor={Colors.success}
          onPress={() => navigation.navigate('UsuariosGlobal')}
        />
        <View style={styles.separator} />
        <ListRow
          title="Reportes Globales"
          subtitle="Resumen de todo el sistema"
          icon="bar-chart-outline"
          iconColor={Colors.purple}
          onPress={() => navigation.navigate('ReportesGlobales')}
        />
      </Card>

      <View style={{ height: 40 }} />
    </ScrollView>
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
  },
  header: {
    paddingHorizontal: Spacing.md,
    paddingTop: Spacing.lg,
    paddingBottom: Spacing.sm,
  },
  welcome: {
    fontSize: FontSize.largeTitle,
    fontWeight: 'bold',
    color: Colors.text,
  },
  subtitle: {
    fontSize: FontSize.subheadline,
    color: Colors.textSecondary,
    marginTop: 4,
  },
  statsGrid: {
    flexDirection: 'row',
    paddingHorizontal: Spacing.md,
    gap: Spacing.sm,
    marginTop: Spacing.md,
  },
  statCard: {
    flex: 1,
    backgroundColor: Colors.card,
    borderRadius: 16,
    padding: Spacing.md,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 3,
    elevation: 1,
  },
  statIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  statNumber: {
    fontSize: 28,
    fontWeight: 'bold',
    color: Colors.text,
  },
  statLabel: {
    fontSize: FontSize.subheadline,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  statSub: {
    fontSize: FontSize.caption,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  alertCard: {
    marginHorizontal: Spacing.md,
    marginTop: Spacing.md,
    paddingVertical: Spacing.sm,
  },
  alertRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: Spacing.sm,
  },
  alertIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
  },
  alertTitle: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.warning,
  },
  alertSub: {
    fontSize: FontSize.caption,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  menuCard: {
    paddingHorizontal: 0,
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
  },
  separator: {
    height: 1,
    backgroundColor: Colors.separator,
    marginLeft: 56,
  },
});
