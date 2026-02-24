import React, { useState } from 'react';
import { View, Text, StyleSheet, KeyboardAvoidingView, Platform, ScrollView, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';

export default function ForgotPasswordScreen({ navigation }) {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [sent, setSent] = useState(false);

  async function handleRecover() {
    if (!email.trim()) {
      setError('Ingresa tu correo electrónico');
      return;
    }

    setError('');
    setLoading(true);
    try {
      await api.recuperarPassword(email.trim());
      setSent(true);
    } catch (err) {
      setError(err.message || 'Error al enviar la solicitud');
    } finally {
      setLoading(false);
    }
  }

  if (sent) {
    return (
      <View style={styles.container}>
        <View style={styles.sentContent}>
          <View style={styles.iconCircle}>
            <Ionicons name="mail-outline" size={48} color={Colors.primary} />
          </View>
          <Text style={styles.sentTitle}>Revisa tu correo</Text>
          <Text style={styles.sentMessage}>
            Si existe una cuenta con ese correo, recibirás instrucciones para restablecer tu contraseña.
          </Text>
          <Button
            title="Volver a Iniciar Sesión"
            onPress={() => navigation.navigate('Login')}
            style={styles.backButton}
          />
        </View>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={styles.header}>
          <View style={styles.iconCircle}>
            <Ionicons name="lock-open-outline" size={48} color={Colors.primary} />
          </View>
          <Text style={styles.title}>Recuperar Contraseña</Text>
          <Text style={styles.subtitle}>
            Ingresa el correo asociado a tu cuenta y te enviaremos instrucciones.
          </Text>
        </View>

        <View style={styles.form}>
          <Input
            label="Correo electrónico"
            value={email}
            onChangeText={setEmail}
            placeholder="tu@correo.com"
            keyboardType="email-address"
            autoCapitalize="none"
          />

          {error ? (
            <View style={styles.errorContainer}>
              <Text style={styles.errorText}>{error}</Text>
            </View>
          ) : null}

          <Button
            title="Enviar Instrucciones"
            onPress={handleRecover}
            loading={loading}
          />
        </View>

        <TouchableOpacity
          style={styles.loginLink}
          onPress={() => navigation.navigate('Login')}
        >
          <Text style={styles.loginLinkText}>
            <Text style={styles.loginLinkBold}>Volver a Iniciar Sesión</Text>
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  scroll: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: Spacing.xxl,
  },
  header: {
    alignItems: 'center',
    marginBottom: Spacing.xxl,
  },
  iconCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: Colors.primary + '15',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.lg,
  },
  title: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
  },
  subtitle: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    textAlign: 'center',
    marginTop: Spacing.sm,
    lineHeight: 22,
    paddingHorizontal: Spacing.lg,
  },
  form: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.xxl,
  },
  errorContainer: {
    backgroundColor: Colors.destructive + '15',
    borderRadius: BorderRadius.sm,
    padding: Spacing.md,
    marginBottom: Spacing.lg,
  },
  errorText: {
    color: Colors.destructive,
    fontSize: FontSize.md,
    textAlign: 'center',
  },
  loginLink: {
    alignItems: 'center',
    marginTop: Spacing.xl,
    paddingVertical: Spacing.md,
  },
  loginLinkText: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
  },
  loginLinkBold: {
    color: Colors.primary,
    fontWeight: '600',
  },
  sentContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: Spacing.xxxl,
  },
  sentTitle: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: Spacing.md,
  },
  sentMessage: {
    fontSize: FontSize.lg,
    color: Colors.textSecondary,
    textAlign: 'center',
    lineHeight: 24,
    marginBottom: Spacing.xxxl,
  },
  backButton: {
    minWidth: 250,
  },
});
