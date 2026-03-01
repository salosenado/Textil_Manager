import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, TextInput } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { useAuth } from '../context/AuthContext';
import { api } from '../services/api';
import Card from '../components/Card';
import Input from '../components/Input';
import Button from '../components/Button';
import ListRow from '../components/ListRow';
import SectionHeader from '../components/SectionHeader';

export default function ProfileScreen({ navigation }) {
  const { user, logout } = useAuth();
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleChangePassword() {
    if (!currentPassword || !newPassword || !confirmPassword) {
      Alert.alert('Error', 'Completa todos los campos');
      return;
    }
    if (newPassword.length < 6) {
      Alert.alert('Error', 'La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (newPassword !== confirmPassword) {
      Alert.alert('Error', 'Las contraseñas no coinciden');
      return;
    }

    setLoading(true);
    try {
      await api.changePassword(currentPassword, newPassword);
      Alert.alert('Listo', 'Contraseña actualizada correctamente');
      setShowPasswordForm(false);
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err) {
      Alert.alert('Error', err.message);
    } finally {
      setLoading(false);
    }
  }

  const [showDeleteForm, setShowDeleteForm] = useState(false);
  const [deletePassword, setDeletePassword] = useState('');
  const [deletingAccount, setDeletingAccount] = useState(false);

  function handleLogout() {
    Alert.alert('Cerrar Sesión', '¿Estás seguro?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Cerrar Sesión', style: 'destructive', onPress: logout },
    ]);
  }

  function handleDeleteAccount() {
    if (!deletePassword) {
      Alert.alert('Error', 'Ingresa tu contraseña para confirmar');
      return;
    }

    Alert.alert(
      'Eliminar Cuenta',
      'Esta acción es permanente. Se eliminarán todos tus datos y no podrás recuperar tu cuenta. ¿Estás seguro?',
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar mi cuenta',
          style: 'destructive',
          onPress: async () => {
            setDeletingAccount(true);
            try {
              await api.deleteAccount(deletePassword);
              Alert.alert('Cuenta eliminada', 'Tu cuenta ha sido eliminada correctamente.', [
                { text: 'OK', onPress: logout },
              ]);
            } catch (err) {
              Alert.alert('Error', err.message);
            } finally {
              setDeletingAccount(false);
            }
          },
        },
      ]
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>
            {user?.nombre?.charAt(0)?.toUpperCase() || 'U'}
          </Text>
        </View>
        <Text style={styles.name}>{user?.nombre}</Text>
        <Text style={styles.email}>{user?.email}</Text>
        {user?.es_root && (
          <View style={styles.rootBadge}>
            <Ionicons name="shield-checkmark" size={14} color={Colors.white} />
            <Text style={styles.rootText}>Root</Text>
          </View>
        )}
      </View>

      <SectionHeader title="Información" />
      <Card>
        <ListRow title="Nombre" rightText={user?.nombre} showChevron={false} />
        <View style={styles.separator} />
        <ListRow title="Correo" rightText={user?.email} showChevron={false} />
      </Card>

      <SectionHeader title="Seguridad" />
      <Card>
        <ListRow
          title="Cambiar Contraseña"
          icon="lock-closed-outline"
          iconColor={Colors.primary}
          onPress={() => setShowPasswordForm(!showPasswordForm)}
          showChevron={!showPasswordForm}
        />
        {showPasswordForm && (
          <View style={styles.passwordForm}>
            <Input
              label="Contraseña actual"
              value={currentPassword}
              onChangeText={setCurrentPassword}
              secureTextEntry
              placeholder="••••••••"
            />
            <Input
              label="Nueva contraseña"
              value={newPassword}
              onChangeText={setNewPassword}
              secureTextEntry
              placeholder="Mínimo 6 caracteres"
            />
            <Input
              label="Confirmar contraseña"
              value={confirmPassword}
              onChangeText={setConfirmPassword}
              secureTextEntry
              placeholder="••••••••"
            />
            <Button
              title="Actualizar Contraseña"
              onPress={handleChangePassword}
              loading={loading}
            />
          </View>
        )}
      </Card>

      <View style={styles.logoutSection}>
        <Button
          title="Cerrar Sesión"
          onPress={handleLogout}
          variant="destructive"
        />
      </View>

      {!user?.es_root && (
        <>
          <SectionHeader title="Zona de Peligro" />
          <Card style={styles.dangerCard}>
            <ListRow
              title="Eliminar mi cuenta"
              icon="trash-outline"
              iconColor={Colors.destructive}
              onPress={() => setShowDeleteForm(!showDeleteForm)}
              showChevron={!showDeleteForm}
            />
            {showDeleteForm && (
              <View style={styles.deleteForm}>
                <Text style={styles.deleteWarning}>
                  Al eliminar tu cuenta se borrarán permanentemente todos tus datos. Esta acción no se puede deshacer.
                </Text>
                <Input
                  label="Confirma tu contraseña"
                  value={deletePassword}
                  onChangeText={setDeletePassword}
                  secureTextEntry
                  placeholder="Ingresa tu contraseña"
                />
                <Button
                  title="Eliminar mi cuenta permanentemente"
                  onPress={handleDeleteAccount}
                  variant="destructive"
                  loading={deletingAccount}
                />
              </View>
            )}
          </Card>
          <View style={{ height: 40 }} />
        </>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    alignItems: 'center',
    paddingVertical: Spacing.xxl,
    paddingTop: Spacing.xxxl,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: Colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.md,
  },
  avatarText: {
    fontSize: FontSize.largeTitle,
    fontWeight: '700',
    color: Colors.white,
  },
  name: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
  },
  email: {
    fontSize: FontSize.md,
    color: Colors.textSecondary,
    marginTop: Spacing.xs,
  },
  rootBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary,
    paddingHorizontal: Spacing.md,
    paddingVertical: 4,
    borderRadius: 12,
    marginTop: Spacing.sm,
    gap: 4,
  },
  rootText: {
    color: Colors.white,
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
  separator: {
    height: 1,
    backgroundColor: Colors.separator,
    marginLeft: Spacing.lg,
  },
  passwordForm: {
    paddingTop: Spacing.md,
  },
  logoutSection: {
    padding: Spacing.lg,
    paddingBottom: Spacing.lg,
  },
  dangerCard: {
    borderWidth: 1,
    borderColor: Colors.destructive + '30',
  },
  deleteForm: {
    paddingTop: Spacing.md,
  },
  deleteWarning: {
    fontSize: FontSize.footnote,
    color: Colors.destructive,
    marginBottom: Spacing.md,
    lineHeight: 18,
  },
});
