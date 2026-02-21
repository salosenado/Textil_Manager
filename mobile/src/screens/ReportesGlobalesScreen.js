import React, { useState, useCallback } from 'react';
import { View, Text, StyleSheet, ScrollView, RefreshControl, ActivityIndicator } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';
import { api } from '../services/api';
import Card from '../components/Card';
import SectionHeader from '../components/SectionHeader';

export default function ReportesGlobalesScreen() {
  const [stats, setStats] = useState(null);
  const [empresas, setEmpresas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const loadData = async () => {
    try {
      const [statsData, empresasData] = await Promise.all([
        api.getEmpresasStats(),
        api.getEmpresas(),
      ]);
      setStats(statsData);
      setEmpresas(empresasData);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadData();
    }, [])
  );

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
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadData(); }} />}
    >
      <SectionHeader title="Resumen General" />
      <View style={styles.statsGrid}>
        <ReportCard
          icon="business"
          color={Colors.primary}
          title="Empresas"
          value={stats?.empresas?.total || 0}
          subtitle={`${stats?.empresas?.activas || 0} activas`}
        />
        <ReportCard
          icon="people"
          color={Colors.success}
          title="Usuarios"
          value={stats?.usuarios?.total || 0}
          subtitle={`${stats?.usuarios?.activos || 0} activos`}
        />
        <ReportCard
          icon="alert-circle"
          color={Colors.warning}
          title="Pendientes"
          value={stats?.pendientes || 0}
          subtitle="por aprobar"
        />
        <ReportCard
          icon="shield"
          color={Colors.purple}
          title="Roles"
          value={stats?.roles || 0}
          subtitle="configurados"
        />
      </View>

      <SectionHeader title="Empresas por Usuarios" />
      <Card style={styles.tableCard}>
        <View style={styles.tableHeader}>
          <Text style={[styles.tableHeaderText, { flex: 2 }]}>Empresa</Text>
          <Text style={[styles.tableHeaderText, { flex: 1, textAlign: 'center' }]}>Total</Text>
          <Text style={[styles.tableHeaderText, { flex: 1, textAlign: 'center' }]}>Activos</Text>
          <Text style={[styles.tableHeaderText, { flex: 1, textAlign: 'center' }]}>Estado</Text>
        </View>
        {empresas.map((e, i) => (
          <React.Fragment key={e.id}>
            {i > 0 && <View style={styles.tableDivider} />}
            <View style={styles.tableRow}>
              <Text style={[styles.tableCell, { flex: 2, fontWeight: '500' }]} numberOfLines={1}>{e.nombre}</Text>
              <Text style={[styles.tableCell, { flex: 1, textAlign: 'center' }]}>{e.total_usuarios || 0}</Text>
              <Text style={[styles.tableCell, { flex: 1, textAlign: 'center' }]}>{e.usuarios_activos || 0}</Text>
              <View style={{ flex: 1, alignItems: 'center' }}>
                <View style={[styles.statusDot, { backgroundColor: e.activo ? Colors.success : Colors.error }]} />
              </View>
            </View>
          </React.Fragment>
        ))}
        {empresas.length === 0 && (
          <Text style={styles.emptyText}>No hay empresas registradas</Text>
        )}
      </Card>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

function ReportCard({ icon, color, title, value, subtitle }) {
  return (
    <View style={styles.reportCard}>
      <View style={[styles.reportIcon, { backgroundColor: color + '20' }]}>
        <Ionicons name={icon} size={22} color={color} />
      </View>
      <Text style={styles.reportValue}>{value}</Text>
      <Text style={styles.reportTitle}>{title}</Text>
      <Text style={styles.reportSub}>{subtitle}</Text>
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
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: Spacing.md,
    gap: Spacing.sm,
  },
  reportCard: {
    width: '47%',
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
  reportIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  reportValue: {
    fontSize: 28,
    fontWeight: 'bold',
    color: Colors.text,
  },
  reportTitle: {
    fontSize: FontSize.subheadline,
    color: Colors.text,
    fontWeight: '500',
    marginTop: 2,
  },
  reportSub: {
    fontSize: FontSize.caption,
    color: Colors.textTertiary,
    marginTop: 2,
  },
  tableCard: {
    marginHorizontal: Spacing.md,
  },
  tableHeader: {
    flexDirection: 'row',
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
    marginBottom: 4,
  },
  tableHeaderText: {
    fontSize: FontSize.caption,
    fontWeight: '600',
    color: Colors.textSecondary,
    textTransform: 'uppercase',
  },
  tableRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
  },
  tableDivider: {
    height: 1,
    backgroundColor: Colors.separator,
  },
  tableCell: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  emptyText: {
    textAlign: 'center',
    color: Colors.textTertiary,
    fontSize: FontSize.body,
    paddingVertical: Spacing.md,
  },
});
