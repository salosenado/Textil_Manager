import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';
import { useAuth } from '../context/AuthContext';
import Button from '../components/Button';

export default function BlockedScreen() {
  const { logout, user } = useAuth();
  const isPending = user && !user.aprobado;

  return (
    <View style={styles.container}>
      <View style={styles.content}>
        <View style={[styles.iconCircle, { backgroundColor: isPending ? Colors.warning + '20' : Colors.destructive + '20' }]}>
          <Ionicons
            name={isPending ? 'time-outline' : 'lock-closed-outline'}
            size={48}
            color={isPending ? Colors.warning : Colors.destructive}
          />
        </View>
        <Text style={styles.title}>
          {isPending ? 'Cuenta Pendiente' : 'Cuenta Bloqueada'}
        </Text>
        <Text style={styles.message}>
          {isPending
            ? 'Tu cuenta está pendiente de aprobación por un administrador. Te notificaremos cuando sea aprobada.'
            : 'Tu cuenta ha sido desactivada. Contacta al administrador de tu empresa para más información.'}
        </Text>
        <Button
          title="Cerrar Sesión"
          onPress={logout}
          variant="secondary"
          style={styles.button}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    justifyContent: 'center',
    alignItems: 'center',
  },
  content: {
    alignItems: 'center',
    paddingHorizontal: Spacing.xxxl,
  },
  iconCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.xxl,
  },
  title: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  message: {
    fontSize: FontSize.lg,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: Spacing.xxxl,
  },
  button: {
    minWidth: 200,
  },
});
