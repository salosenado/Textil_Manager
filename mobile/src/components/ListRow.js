import React from 'react';
import { TouchableOpacity, View, Text, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize } from '../theme';

export default function ListRow({ title, subtitle, icon, iconColor, rightText, rightColor, onPress, showChevron = true, badge }) {
  const Container = onPress ? TouchableOpacity : View;

  return (
    <Container style={styles.row} onPress={onPress} activeOpacity={0.6}>
      {icon && (
        <View style={[styles.iconContainer, { backgroundColor: (iconColor || Colors.primary) + '20' }]}>
          <Ionicons name={icon} size={20} color={iconColor || Colors.primary} />
        </View>
      )}
      <View style={styles.content}>
        <Text style={styles.title} numberOfLines={1}>{title}</Text>
        {subtitle && <Text style={styles.subtitle} numberOfLines={1}>{subtitle}</Text>}
      </View>
      {badge && (
        <View style={[styles.badge, { backgroundColor: badge.color || Colors.primary }]}>
          <Text style={styles.badgeText}>{badge.text}</Text>
        </View>
      )}
      {rightText && (
        <Text style={[styles.rightText, rightColor && { color: rightColor }]}>{rightText}</Text>
      )}
      {showChevron && onPress && (
        <Ionicons name="chevron-forward" size={18} color={Colors.textTertiary} />
      )}
    </Container>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    minHeight: 48,
  },
  iconContainer: {
    width: 32,
    height: 32,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: Spacing.md,
  },
  content: {
    flex: 1,
  },
  title: {
    fontSize: FontSize.lg,
    color: Colors.text,
  },
  subtitle: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginTop: 2,
  },
  rightText: {
    fontSize: FontSize.sm,
    color: Colors.textSecondary,
    marginRight: Spacing.sm,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 10,
    marginRight: Spacing.sm,
  },
  badgeText: {
    color: Colors.white,
    fontSize: FontSize.xs,
    fontWeight: '600',
  },
});
