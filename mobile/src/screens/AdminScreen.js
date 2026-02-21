import React from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing } from '../theme';
import { useAuth } from '../context/AuthContext';
import Card from '../components/Card';
import ListRow from '../components/ListRow';
import SectionHeader from '../components/SectionHeader';

export default function AdminScreen({ navigation }) {
  const { tienePermiso } = useAuth();

  return (
    <ScrollView style={styles.container}>
      <SectionHeader title="Gestión" />
      <Card style={styles.card}>
        {tienePermiso('usuarios.ver') && (
          <>
            <ListRow
              title="Usuarios"
              subtitle="Administrar usuarios de la empresa"
              icon="people-outline"
              iconColor={Colors.primary}
              onPress={() => navigation.navigate('UsuariosScreen')}
            />
            <View style={styles.separator} />
          </>
        )}
        {tienePermiso('usuarios.editar') && (
          <ListRow
            title="Roles"
            subtitle="Administrar roles y permisos"
            icon="shield-outline"
            iconColor={Colors.purple}
            onPress={() => navigation.navigate('RolesScreen')}
          />
        )}
      </Card>

      <SectionHeader title="Configuración" />
      <Card style={styles.card}>
        <ListRow
          title="Perfil"
          subtitle="Ver y editar tu perfil"
          icon="person-outline"
          iconColor={Colors.success}
          onPress={() => navigation.navigate('PerfilScreen')}
        />
      </Card>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  card: {
    paddingHorizontal: 0,
    paddingVertical: Spacing.sm,
  },
  separator: {
    height: 1,
    backgroundColor: Colors.separator,
    marginLeft: 56,
  },
});
