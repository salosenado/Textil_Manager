import React from 'react';
import { View, TouchableOpacity, StyleSheet } from 'react-native';
import { Colors, BorderRadius, Spacing } from '../theme';

export default function Card({ children, style, onPress }) {
  const Wrapper = onPress ? TouchableOpacity : View;
  return (
    <Wrapper style={[styles.card, style]} onPress={onPress} activeOpacity={0.7}>
      {children}
    </Wrapper>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    padding: Spacing.lg,
    marginHorizontal: Spacing.lg,
    marginBottom: Spacing.md,
  },
});
