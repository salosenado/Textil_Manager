import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { Colors, Spacing, FontSize } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';
import Card from '../components/Card';

export default function EmpresaFormScreen({ route, navigation }) {
  const { empresa, onRefresh } = route.params || {};
  const isEditing = !!empresa;

  const [nombre, setNombre] = useState(empresa?.nombre || '');
  const [rfc, setRfc] = useState(empresa?.rfc || '');
  const [direccion, setDireccion] = useState(empresa?.direccion || '');
  const [telefono, setTelefono] = useState(empresa?.telefono || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSave = async () => {
    if (!nombre.trim()) {
      setError('El nombre es requerido');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const data = { nombre, rfc, direccion, telefono };
      if (isEditing) {
        await api.updateEmpresa(empresa.id, data);
      } else {
        await api.createEmpresa(data);
      }
      if (onRefresh) onRefresh();
      navigation.goBack();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      <SectionHeader title="Datos de la Empresa" />
      <Card style={styles.formCard}>
        <Input
          label="Nombre"
          value={nombre}
          onChangeText={setNombre}
          placeholder="Nombre de la empresa"
        />
        <View style={styles.divider} />
        <Input
          label="RFC"
          value={rfc}
          onChangeText={setRfc}
          placeholder="RFC (opcional)"
          autoCapitalize="characters"
        />
        <View style={styles.divider} />
        <Input
          label="Dirección"
          value={direccion}
          onChangeText={setDireccion}
          placeholder="Dirección (opcional)"
          multiline
        />
        <View style={styles.divider} />
        <Input
          label="Teléfono"
          value={telefono}
          onChangeText={setTelefono}
          placeholder="Teléfono (opcional)"
          keyboardType="phone-pad"
        />
      </Card>

      {error ? (
        <Text style={styles.error}>{error}</Text>
      ) : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : 'Crear Empresa'}
          onPress={handleSave}
          loading={loading}
        />
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  formCard: {
    marginHorizontal: Spacing.md,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginVertical: Spacing.xs,
  },
  error: {
    color: Colors.error,
    fontSize: FontSize.footnote,
    textAlign: 'center',
    marginTop: Spacing.md,
    paddingHorizontal: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
