import React, { useState } from 'react';
import { View, Text, TextInput, StyleSheet, TouchableOpacity } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, BorderRadius, Spacing, FontSize } from '../theme';

export default function Input({ label, value, onChangeText, placeholder, secureTextEntry, keyboardType, autoCapitalize, editable = true, multiline = false, style }) {
  const [hidden, setHidden] = useState(true);
  const isPassword = secureTextEntry === true;

  return (
    <View style={styles.container}>
      {label && <Text style={styles.label}>{label}</Text>}
      <View style={styles.inputRow}>
        <TextInput
          style={[styles.input, multiline && styles.multiline, !editable && styles.disabled, isPassword && styles.inputWithIcon, style]}
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={Colors.textTertiary}
          secureTextEntry={isPassword && hidden}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize || 'none'}
          editable={editable}
          multiline={multiline}
        />
        {isPassword && (
          <TouchableOpacity
            style={styles.eyeButton}
            onPress={() => setHidden(prev => !prev)}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <Ionicons
              name={hidden ? 'eye-off-outline' : 'eye-outline'}
              size={22}
              color={Colors.textSecondary}
            />
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: Spacing.lg,
  },
  label: {
    fontSize: FontSize.sm,
    fontWeight: '600',
    color: Colors.textSecondary,
    marginBottom: Spacing.xs,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  inputRow: {
    position: 'relative',
    justifyContent: 'center',
  },
  input: {
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    fontSize: FontSize.lg,
    color: Colors.text,
    minHeight: 44,
  },
  inputWithIcon: {
    paddingRight: 44,
  },
  multiline: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  disabled: {
    opacity: 0.6,
  },
  eyeButton: {
    position: 'absolute',
    right: 12,
    height: 44,
    justifyContent: 'center',
  },
});
