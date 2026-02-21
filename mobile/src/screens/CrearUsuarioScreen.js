import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import Card from '../components/Card';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

export default function CrearUsuarioScreen({ route, navigation }) {
  const { onRefresh } = route.params || {};
  const { user: currentUser } = useAuth();
  const [nombre, setNombre] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleCreate() {
    if (!nombre.trim() || !email.trim() || !password.trim()) {
      Alert.alert('Error', 'Completa todos los campos');
      return;
    }
    if (password.length < 6) {
      Alert.alert('Error', 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setLoading(true);
    try {
      await api.createUsuario({
        nombre: nombre.trim(),
        email: email.trim(),
        password,
      });
      Alert.alert('Listo', 'Usuario creado correctamente');
      if (onRefresh) onRefresh();
      navigation.goBack();
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      <SectionHeader title="Datos del usuario" />
      <Card>
        <Input
          label="Nombre completo"
          value={nombre}
          onChangeText={setNombre}
          placeholder="Juan Pérez"
          autoCapitalize="words"
        />
        <Input
          label="Correo electrónico"
          value={email}
          onChangeText={setEmail}
          placeholder="juan@empresa.com"
          keyboardType="email-address"
        />
        <Input
          label="Contraseña"
          value={password}
          onChangeText={setPassword}
          placeholder="Mínimo 6 caracteres"
          secureTextEntry
        />
        <Button
          title="Crear Usuario"
          onPress={handleCreate}
          loading={loading}
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
});
