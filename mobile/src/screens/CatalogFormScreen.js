import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert, Switch, TouchableOpacity, ActivityIndicator } from 'react-native';
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
      { key: 'pais', label: 'País' },
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
      { key: 'existencia', label: 'Existencia', keyboard: 'number-pad' },
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
      { key: 'descripcion', label: 'Descripción' },
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

const TELA_PRECIO_TIPOS = [
  'Blanco', 'Claro', 'Medio', 'Obscuro', 'Jaspe', 'Negro', 'Único precio'
];

export default function CatalogFormScreen({ route, navigation }) {
  const { catalogo, title, item } = route.params;
  const isEditing = !!item;

  const activeField = CATALOG_ACTIVE_FIELD[catalogo] || 'activo';
  const hasActive = !CATALOGS_WITHOUT_ACTIVE.includes(catalogo);
  const needsMarcaSelector = catalogo === 'modelos';
  const needsProveedorSelector = catalogo === 'telas';
  const needsPrecios = catalogo === 'telas';

  const sections = CATALOG_FIELDS[catalogo] || [{ section: 'Datos', fields: [{ key: 'nombre', label: 'Nombre', required: true }] }];

  const allFieldKeys = sections.flatMap(s => s.fields.map(f => f.key));
  const initialValues = {};
  for (const key of allFieldKeys) {
    initialValues[key] = item?.[key] != null ? String(item[key]) : '';
  }
  if (hasActive) {
    initialValues[activeField] = item?.[activeField] !== false;
  }
  if (needsMarcaSelector) {
    initialValues.marca_id = item?.marca_id || '';
  }
  if (needsProveedorSelector) {
    initialValues.proveedor_id = item?.proveedor_id || '';
  }

  const [values, setValues] = useState(initialValues);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [marcas, setMarcas] = useState([]);
  const [proveedores, setProveedores] = useState([]);
  const [precios, setPrecios] = useState({});
  const [loadingRelated, setLoadingRelated] = useState(false);

  useEffect(() => {
    const loadRelated = async () => {
      setLoadingRelated(true);
      try {
        if (needsMarcaSelector) {
          const data = await api.getCatalogItems('marcas');
          setMarcas(data.filter(m => m.activo !== false));
        }
        if (needsProveedorSelector) {
          const data = await api.getCatalogItems('proveedores');
          setProveedores(data.filter(p => p.activo !== false));
        }
        if (needsPrecios && isEditing && item?.id) {
          const data = await api.getTelaPrecios(item.id);
          const preciosMap = {};
          for (const p of data) {
            preciosMap[p.tipo] = String(p.precio);
          }
          setPrecios(preciosMap);
        }
      } catch (err) {
        console.error('Error loading related data:', err);
      } finally {
        setLoadingRelated(false);
      }
    };

    if (needsMarcaSelector || needsProveedorSelector || needsPrecios) {
      loadRelated();
    }
  }, []);

  const setValue = (key, val) => {
    setValues(prev => ({ ...prev, [key]: val }));
  };

  const setPrecio = (tipo, val) => {
    setPrecios(prev => ({ ...prev, [tipo]: val }));
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
      if (needsMarcaSelector) {
        data.marca_id = values.marca_id || null;
      }
      if (needsProveedorSelector) {
        data.proveedor_id = values.proveedor_id || null;
      }

      let savedItem;
      if (isEditing) {
        savedItem = await api.updateCatalogItem(catalogo, item.id, data);
      } else {
        savedItem = await api.createCatalogItem(catalogo, data);
      }

      if (needsPrecios && savedItem?.id) {
        const preciosArray = TELA_PRECIO_TIPOS
          .filter(tipo => precios[tipo] && precios[tipo].trim())
          .map(tipo => ({ tipo, precio: parseFloat(precios[tipo]) || 0 }));

        if (preciosArray.length > 0) {
          await api.saveTelaPrecios(savedItem.id, preciosArray);
        }
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

  const renderPickerSection = (label, selectedId, options, nameField, onSelect) => {
    const selected = options.find(o => o.id === selectedId);
    return (
      <View style={styles.pickerSection}>
        <Text style={styles.pickerLabel}>{label}</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.pickerScroll}>
          <TouchableOpacity
            style={[styles.pickerOption, !selectedId && styles.pickerOptionSelected]}
            onPress={() => onSelect('')}
          >
            <Text style={[styles.pickerOptionText, !selectedId && styles.pickerOptionTextSelected]}>
              Sin asignar
            </Text>
          </TouchableOpacity>
          {options.map(opt => (
            <TouchableOpacity
              key={opt.id}
              style={[styles.pickerOption, selectedId === opt.id && styles.pickerOptionSelected]}
              onPress={() => onSelect(opt.id)}
            >
              <Text style={[styles.pickerOptionText, selectedId === opt.id && styles.pickerOptionTextSelected]}>
                {opt[nameField]}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
        {selected && (
          <Text style={styles.pickerSelected}>{selected[nameField]}</Text>
        )}
      </View>
    );
  };

  if (loadingRelated) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color={Colors.primary} />
      </View>
    );
  }

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

      {needsMarcaSelector && marcas.length > 0 && (
        <>
          <SectionHeader title="Marca" />
          <View style={styles.card}>
            {renderPickerSection('Marca', values.marca_id, marcas, 'nombre', (id) => setValue('marca_id', id))}
          </View>
        </>
      )}

      {needsProveedorSelector && proveedores.length > 0 && (
        <>
          <SectionHeader title="Proveedor" />
          <View style={styles.card}>
            {renderPickerSection('Proveedor', values.proveedor_id, proveedores, 'nombre', (id) => setValue('proveedor_id', id))}
          </View>
        </>
      )}

      {needsPrecios && (
        <>
          <SectionHeader title="Precios de Referencia (MX)" />
          <View style={styles.card}>
            {TELA_PRECIO_TIPOS.map((tipo, i) => (
              <React.Fragment key={tipo}>
                {i > 0 && <View style={styles.divider} />}
                <View style={styles.precioRow}>
                  <Text style={styles.precioLabel}>{tipo}</Text>
                  <View style={styles.precioInputWrap}>
                    <Text style={styles.precioPrefix}>$</Text>
                    <Input
                      value={precios[tipo] || ''}
                      onChangeText={(text) => setPrecio(tipo, text)}
                      placeholder="0.00"
                      keyboardType="decimal-pad"
                      style={styles.precioInput}
                    />
                  </View>
                </View>
              </React.Fragment>
            ))}
          </View>
        </>
      )}

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
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
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
  pickerSection: {
    paddingVertical: Spacing.xs,
  },
  pickerLabel: {
    fontSize: FontSize.footnote,
    color: Colors.textSecondary,
    marginBottom: 6,
  },
  pickerScroll: {
    flexGrow: 0,
  },
  pickerOption: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: Colors.background,
    marginRight: 8,
    borderWidth: 1,
    borderColor: Colors.separator,
  },
  pickerOptionSelected: {
    backgroundColor: Colors.primary,
    borderColor: Colors.primary,
  },
  pickerOptionText: {
    fontSize: FontSize.footnote,
    color: Colors.text,
  },
  pickerOptionTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
  pickerSelected: {
    fontSize: FontSize.caption,
    color: Colors.primary,
    marginTop: 4,
  },
  precioRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 4,
  },
  precioLabel: {
    fontSize: FontSize.body,
    color: Colors.text,
    flex: 1,
  },
  precioInputWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    width: 120,
  },
  precioPrefix: {
    fontSize: FontSize.body,
    color: Colors.textSecondary,
    marginRight: 4,
  },
  precioInput: {
    flex: 1,
    textAlign: 'right',
  },
});
