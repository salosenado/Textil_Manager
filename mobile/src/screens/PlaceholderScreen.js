import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';

export default function PlaceholderScreen({ route }) {
  const { title, icon, color } = route.params || {};

  return (
    <View style={styles.container}>
      <View style={[styles.iconCircle, { backgroundColor: (color || Colors.primary) + '15' }]}>
        <Ionicons name={icon || 'construct-outline'} size={48} color={color || Colors.primary} />
      </View>
      <Text style={styles.title}>{title || 'Módulo'}</Text>
      <Text style={styles.subtitle}>Este módulo estará disponible próximamente</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Spacing.xxxl,
  },
  iconCircle: {
    width: 100,
    height: 100,
    borderRadius: 50,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.xl,
  },
  title: {
    fontSize: FontSize.xxl,
    fontWeight: '700',
    color: Colors.text,
    marginBottom: Spacing.sm,
  },
  subtitle: {
    fontSize: FontSize.lg,
    color: Colors.textSecondary,
    textAlign: 'center',
  },
});
