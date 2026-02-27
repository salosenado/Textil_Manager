import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Platform, Modal, SafeAreaView } from 'react-native';
import RNDateTimePicker from '@react-native-community/datetimepicker';
import { Ionicons } from '@expo/vector-icons';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';

function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function formatDisplay(date) {
  const months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
  return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`;
}

function parseDate(str) {
  if (!str) return null;
  const parts = str.split('-');
  if (parts.length !== 3) return null;
  const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
  return isNaN(d.getTime()) ? null : d;
}

export default function DatePicker({ label, value, onChange, placeholder, minimumDate, maximumDate }) {
  const [show, setShow] = useState(false);
  const currentDate = parseDate(value) || new Date();
  const hasValue = !!value && !!parseDate(value);

  const handleChange = (event, selectedDate) => {
    if (Platform.OS === 'android') {
      setShow(false);
    }
    if (event.type === 'dismissed') return;
    if (selectedDate) {
      onChange(formatDate(selectedDate));
    }
  };

  const handleClear = () => {
    onChange('');
  };

  const handleConfirmIOS = () => {
    setShow(false);
  };

  if (Platform.OS === 'web') {
    return (
      <View style={styles.container}>
        {label && <Text style={styles.label}>{label}</Text>}
        <TouchableOpacity
          style={[styles.selector, hasValue && styles.selectorActive]}
          onPress={() => {
            const input = document.createElement('input');
            input.type = 'date';
            input.value = value || '';
            input.onchange = (e) => {
              if (e.target.value) {
                onChange(e.target.value);
              }
            };
            input.click();
          }}
          activeOpacity={0.6}
        >
          <Ionicons name="calendar-outline" size={18} color={hasValue ? Colors.primary : Colors.textTertiary} style={{ marginRight: 8 }} />
          <Text style={[styles.selectorText, !hasValue && styles.selectorPlaceholder]} numberOfLines={1}>
            {hasValue ? formatDisplay(parseDate(value)) : (placeholder || 'Seleccionar fecha')}
          </Text>
          {hasValue && (
            <TouchableOpacity onPress={handleClear} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
            </TouchableOpacity>
          )}
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {label && <Text style={styles.label}>{label}</Text>}
      <TouchableOpacity
        style={[styles.selector, hasValue && styles.selectorActive]}
        onPress={() => setShow(true)}
        activeOpacity={0.6}
      >
        <Ionicons name="calendar-outline" size={18} color={hasValue ? Colors.primary : Colors.textTertiary} style={{ marginRight: 8 }} />
        <Text style={[styles.selectorText, !hasValue && styles.selectorPlaceholder]} numberOfLines={1}>
          {hasValue ? formatDisplay(parseDate(value)) : (placeholder || 'Seleccionar fecha')}
        </Text>
        <View style={styles.selectorRight}>
          {hasValue && (
            <TouchableOpacity onPress={handleClear} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
              <Ionicons name="close-circle" size={18} color={Colors.textTertiary} />
            </TouchableOpacity>
          )}
        </View>
      </TouchableOpacity>

      {show && Platform.OS === 'android' && (
        <RNDateTimePicker
          value={currentDate}
          mode="date"
          display="default"
          onChange={handleChange}
          minimumDate={minimumDate}
          maximumDate={maximumDate}
        />
      )}

      {show && Platform.OS === 'ios' && (
        <Modal transparent animationType="slide">
          <View style={styles.modalOverlay}>
            <SafeAreaView style={styles.modalContent}>
              <View style={styles.modalHeader}>
                <Text style={styles.modalTitle}>{label || 'Fecha'}</Text>
                <TouchableOpacity onPress={handleConfirmIOS}>
                  <Text style={styles.modalDone}>Listo</Text>
                </TouchableOpacity>
              </View>
              <RNDateTimePicker
                value={currentDate}
                mode="date"
                display="spinner"
                onChange={handleChange}
                minimumDate={minimumDate}
                maximumDate={maximumDate}
                style={styles.iosPicker}
                locale="es-MX"
              />
            </SafeAreaView>
          </View>
        </Modal>
      )}
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
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.inputBg,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.md,
    minHeight: 44,
  },
  selectorActive: {
    borderWidth: 1,
    borderColor: Colors.primary + '40',
  },
  selectorText: {
    fontSize: FontSize.lg,
    color: Colors.text,
    flex: 1,
  },
  selectorPlaceholder: {
    color: Colors.textTertiary,
  },
  selectorRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  modalOverlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  modalContent: {
    backgroundColor: Colors.card,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: Colors.separator,
  },
  modalTitle: {
    fontSize: FontSize.headline,
    fontWeight: '600',
    color: Colors.text,
  },
  modalDone: {
    fontSize: FontSize.body,
    fontWeight: '600',
    color: Colors.primary,
  },
  iosPicker: {
    height: 220,
  },
});
