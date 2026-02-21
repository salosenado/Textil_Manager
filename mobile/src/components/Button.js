import React from 'react';
import { TouchableOpacity, Text, StyleSheet, ActivityIndicator } from 'react-native';
import { Colors, BorderRadius, Spacing, FontSize } from '../theme';

export default function Button({ title, onPress, variant = 'primary', loading = false, disabled = false, style }) {
  const isDestructive = variant === 'destructive';
  const isSecondary = variant === 'secondary';

  return (
    <TouchableOpacity
      style={[
        styles.button,
        isDestructive && styles.destructive,
        isSecondary && styles.secondary,
        (disabled || loading) && styles.disabled,
        style,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
      activeOpacity={0.7}
    >
      {loading ? (
        <ActivityIndicator color={isSecondary ? Colors.primary : Colors.white} />
      ) : (
        <Text style={[
          styles.text,
          isDestructive && styles.destructiveText,
          isSecondary && styles.secondaryText,
        ]}>
          {title}
        </Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: Colors.primary,
    borderRadius: BorderRadius.sm,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.xl,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 48,
  },
  destructive: {
    backgroundColor: Colors.destructive,
  },
  secondary: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: Colors.primary,
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    color: Colors.white,
    fontSize: FontSize.lg,
    fontWeight: '600',
  },
  destructiveText: {
    color: Colors.white,
  },
  secondaryText: {
    color: Colors.primary,
  },
});
