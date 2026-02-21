import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Switch } from 'react-native';
import { Colors, Spacing, FontSize, BorderRadius } from '../theme';
import { api } from '../services/api';
import Input from '../components/Input';
import Button from '../components/Button';
import SectionHeader from '../components/SectionHeader';

const CATALOG_FIELDS = {
  agentes: [
    { section: 'Datos del Agente', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'apellido', label: 'Apellido' },
      { key: 'comision', label: 'Comisión (%)', keyboard: 'decimal-pad' },
    ]},
    { section: 'Contacto', fields: [
      { key: 'telefono', label: 'Teléfono', keyboard: 'phone-pad' },
      { key: 'email', label: 'Email', keyboard: 'email-address' },
    ]},
  ],
  clientes: [
    { section: 'Datos del Cliente', fields: [
      { key: 'nombre_comercial', label: 'Nombre Comercial', required: true },
      { key: 'razon_social', label: 'Razón Social' },
      { key: 'rfc', label: 'RFC', autoCapitalize: 'characters' },
    ]},
    { section: 'Crédito', fields: [
      { key: 'plazo_dias', label: 'Plazo (días)', keyboard: 'number-pad' },
      { key: 'limite_credito', label: 'Límite de Crédito', keyboard: 'decimal-pad' },
    ]},
    { section: 'Contacto', fields: [
      { key: 'contacto', label: 'Contacto' },
      { key: 'telefono', label: 'Teléfono', keyboard: 'phone-pad' },
      { key: 'email', label: 'Email', keyboard: 'email-address' },
    ]},
    { section: 'Dirección', fields: [
      { key: 'calle', label: 'Calle' },
      { key: 'numero', label: 'Número' },
      { key: 'colonia', label: 'Colonia' },
      { key: 'ciudad', label: 'Ciudad' },
      { key: 'estado', label: 'Estado' },
      { key: 'codigo_postal', label: 'Código Postal', keyboard: 'number-pad' },
    ]},
    { section: 'Notas', fields: [
      { key: 'observaciones', label: 'Observaciones', multiline: true },
    ]},
  ],
  proveedores: [
    { section: 'Datos del Proveedor', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'contacto', label: 'Contacto' },
      { key: 'rfc', label: 'RFC', autoCapitalize: 'characters' },
      { key: 'plazo_pago_dias', label: 'Plazo de Pago (días)', keyboard: 'number-pad' },
    ]},
    { section: 'Teléfonos', fields: [
      { key: 'telefono_principal', label: 'Teléfono Principal', keyboard: 'phone-pad' },
      { key: 'telefono_secundario', label: 'Teléfono Secundario', keyboard: 'phone-pad' },
      { key: 'email', label: 'Email', keyboard: 'email-address' },
    ]},
    { section: 'Dirección', fields: [
      { key: 'calle', label: 'Calle' },
      { key: 'numero_exterior', label: 'Núm. Exterior' },
      { key: 'numero_interior', label: 'Núm. Interior' },
      { key: 'colonia', label: 'Colonia' },
      { key: 'ciudad', label: 'Ciudad' },
      { key: 'estado', label: 'Estado' },
      { key: 'codigo_postal', label: 'Código Postal', keyboard: 'number-pad' },
    ]},
  ],
  articulos: [
    { section: 'Datos del Artículo', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'sku', label: 'SKU' },
      { key: 'descripcion', label: 'Descripción', multiline: true },
    ]},
    { section: 'Precios', fields: [
      { key: 'precio_venta', label: 'Precio de Venta', keyboard: 'decimal-pad' },
      { key: 'costo', label: 'Costo', keyboard: 'decimal-pad' },
    ]},
  ],
  colores: [
    { section: 'Datos', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
    ]},
  ],
  tallas: [
    { section: 'Datos', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'orden', label: 'Orden', keyboard: 'number-pad' },
    ]},
  ],
  modelos: [
    { section: 'Datos del Modelo', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'codigo', label: 'Código' },
      { key: 'descripcion', label: 'Descripción', multiline: true },
    ]},
  ],
  marcas: [
    { section: 'Datos de la Marca', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'descripcion', label: 'Descripción', multiline: true },
      { key: 'dueno', label: 'Dueño' },
      { key: 'regalia_porcentaje', label: 'Regalía (%)', keyboard: 'decimal-pad' },
    ]},
  ],
  lineas: [
    { section: 'Datos', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
    ]},
  ],
  departamentos: [
    { section: 'Datos', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
    ]},
  ],
  unidades: [
    { section: 'Datos de la Unidad', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'abreviatura', label: 'Abreviatura' },
      { key: 'factor', label: 'Factor de Conversión', keyboard: 'decimal-pad' },
    ]},
  ],
  tipos_tela: [
    { section: 'Datos', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
    ]},
  ],
  telas: [
    { section: 'Datos de la Tela', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'composicion', label: 'Composición' },
      { key: 'descripcion', label: 'Descripción', multiline: true },
    ]},
  ],
  maquileros: [
    { section: 'Datos del Maquilero', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'contacto', label: 'Contacto' },
    ]},
    { section: 'Teléfonos', fields: [
      { key: 'telefono_principal', label: 'Teléfono Principal', keyboard: 'phone-pad' },
      { key: 'telefono_secundario', label: 'Teléfono Secundario', keyboard: 'phone-pad' },
    ]},
    { section: 'Dirección', fields: [
      { key: 'calle', label: 'Calle' },
      { key: 'numero_exterior', label: 'Núm. Exterior' },
      { key: 'numero_interior', label: 'Núm. Interior' },
      { key: 'colonia', label: 'Colonia' },
      { key: 'ciudad', label: 'Ciudad' },
      { key: 'estado', label: 'Estado' },
      { key: 'codigo_postal', label: 'Código Postal', keyboard: 'number-pad' },
    ]},
  ],
  servicios: [
    { section: 'Datos del Servicio', fields: [
      { key: 'nombre', label: 'Nombre', required: true },
      { key: 'descripcion', label: 'Descripción', multiline: true },
      { key: 'costo', label: 'Costo', keyboard: 'decimal-pad' },
    ]},
  ],
};

const CATALOG_ACTIVE_FIELD = {
  telas: 'activa',
};

const CATALOGS_WITHOUT_ACTIVE = ['unidades', 'tallas'];

export default function CatalogFormScreen({ route, navigation }) {
  const { catalogo, title, item } = route.params;
  const isEditing = !!item;

  const activeField = CATALOG_ACTIVE_FIELD[catalogo] || 'activo';
  const hasActive = !CATALOGS_WITHOUT_ACTIVE.includes(catalogo);

  const sections = CATALOG_FIELDS[catalogo] || [{ section: 'Datos', fields: [{ key: 'nombre', label: 'Nombre', required: true }] }];

  const allFieldKeys = sections.flatMap(s => s.fields.map(f => f.key));
  const initialValues = {};
  for (const key of allFieldKeys) {
    initialValues[key] = item?.[key] != null ? String(item[key]) : '';
  }
  if (hasActive) {
    initialValues[activeField] = item?.[activeField] !== false;
  }

  const [values, setValues] = useState(initialValues);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const setValue = (key, val) => {
    setValues(prev => ({ ...prev, [key]: val }));
  };

  React.useLayoutEffect(() => {
    navigation.setOptions({
      title: isEditing ? `Editar ${title}` : `Nuevo`,
    });
  }, [navigation, title, isEditing]);

  const handleSave = async () => {
    const requiredFields = sections.flatMap(s => s.fields.filter(f => f.required));
    for (const field of requiredFields) {
      if (!values[field.key] || !String(values[field.key]).trim()) {
        setError(`El campo "${field.label}" es requerido`);
        return;
      }
    }

    setLoading(true);
    setError('');

    try {
      const data = {};
      for (const key of allFieldKeys) {
        if (values[key] !== '') {
          data[key] = values[key];
        }
      }
      if (hasActive) {
        data[activeField] = values[activeField];
      }

      if (isEditing) {
        await api.updateCatalogItem(catalogo, item.id, data);
      } else {
        await api.createCatalogItem(catalogo, data);
      }
      navigation.goBack();
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = () => {
    const nameField = catalogo === 'clientes' ? 'nombre_comercial' : 'nombre';
    Alert.alert(
      'Eliminar',
      `¿Estás seguro de eliminar "${item[nameField]}"? Esta acción no se puede deshacer.`,
      [
        { text: 'Cancelar', style: 'cancel' },
        {
          text: 'Eliminar',
          style: 'destructive',
          onPress: async () => {
            try {
              await api.deleteCatalogItem(catalogo, item.id);
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', err.message);
            }
          },
        },
      ]
    );
  };

  return (
    <ScrollView style={styles.container} keyboardShouldPersistTaps="handled">
      {sections.map((section) => (
        <React.Fragment key={section.section}>
          <SectionHeader title={section.section} />
          <View style={styles.card}>
            {section.fields.map((field, i) => (
              <React.Fragment key={field.key}>
                {i > 0 && <View style={styles.divider} />}
                <Input
                  label={field.label + (field.required ? ' *' : '')}
                  value={values[field.key]}
                  onChangeText={(text) => setValue(field.key, text)}
                  placeholder={field.label}
                  keyboardType={field.keyboard || 'default'}
                  autoCapitalize={field.autoCapitalize || 'sentences'}
                  multiline={field.multiline}
                />
              </React.Fragment>
            ))}
          </View>
        </React.Fragment>
      ))}

      {hasActive && (
        <>
          <SectionHeader title="Estado" />
          <View style={styles.card}>
            <View style={styles.toggleRow}>
              <Text style={styles.toggleLabel}>Activo</Text>
              <Switch
                value={values[activeField]}
                onValueChange={(val) => setValue(activeField, val)}
                trackColor={{ false: Colors.separator, true: Colors.primary + '80' }}
                thumbColor={values[activeField] ? Colors.primary : '#f4f3f4'}
              />
            </View>
          </View>
        </>
      )}

      {error ? (
        <Text style={styles.error}>{error}</Text>
      ) : null}

      <View style={styles.buttonContainer}>
        <Button
          title={isEditing ? 'Guardar Cambios' : `Crear ${title}`}
          onPress={handleSave}
          loading={loading}
        />
        {isEditing && (
          <>
            <View style={{ height: Spacing.sm }} />
            <Button
              title="Eliminar"
              onPress={handleDelete}
              variant="destructive"
            />
          </>
        )}
      </View>

      <View style={{ height: 40 }} />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  card: {
    backgroundColor: Colors.card,
    borderRadius: BorderRadius.lg,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    marginHorizontal: Spacing.md,
  },
  divider: {
    height: 1,
    backgroundColor: Colors.separator,
    marginVertical: Spacing.xs,
  },
  toggleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: Spacing.xs,
  },
  toggleLabel: {
    fontSize: FontSize.body,
    color: Colors.text,
  },
  error: {
    color: Colors.error,
    fontSize: FontSize.footnote,
    textAlign: 'center',
    marginTop: Spacing.md,
    paddingHorizontal: Spacing.md,
  },
  buttonContainer: {
    paddingHorizontal: Spacing.md,
    marginTop: Spacing.lg,
  },
});
