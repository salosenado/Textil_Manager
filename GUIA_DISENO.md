# Guía de Diseño — Textil

Extraída del código SwiftUI original para mantener consistencia al migrar a React Native.

---

## 1. Paleta de Colores

| Uso | SwiftUI Original | Equivalente React Native |
|-----|-----------------|-------------------------|
| Fondo principal | `Color(.systemGroupedBackground)` | `#F2F2F7` (gris muy claro) |
| Fondo de tarjetas/secciones | `Color(.systemBackground)` | `#FFFFFF` |
| Fondo de inputs | `Color(.secondarySystemBackground)` | `#F2F2F7` |
| Fondo formularios | `Color(.systemGray6)` | `#F2F2F7` |
| Texto principal | `.primary` | `#000000` |
| Texto secundario | `.secondary` | `#8E8E93` |
| Texto error/inactivo | `.red` | `#FF3B30` |
| Acento/botones principales | `.borderedProminent` (azul iOS) | `#007AFF` |
| Sombras | `.black.opacity(0.05)` | `rgba(0,0,0,0.05)` |
| Dividers | `Divider()` | `#C6C6C8` con opacidad |
| Header material | `.ultraThinMaterial` | Fondo semitransparente con blur |

---

## 2. Tipografía

| Elemento | SwiftUI | Tamaño aprox. | Peso |
|----------|---------|---------------|------|
| Título de pantalla | `.largeTitle` | 34pt | Bold |
| Título de navegación | `.navigationTitle` | 17pt (inline) / 34pt (large) | Bold |
| Título de sección | `.subheadline` | 15pt | Regular |
| Nombre en lista | `.headline` | 17pt | Semibold |
| Subtexto en lista | `.caption` | 12pt | Regular |
| Texto de formulario | Default | 17pt | Regular |
| Labels en botones | Default | 17pt | Semibold |
| Texto de footer | `.footnote` | 13pt | Regular |

---

## 3. Espaciado

| Concepto | Valor |
|----------|-------|
| Padding general horizontal | 16pt |
| Padding vertical contenido | 16pt |
| Espaciado entre secciones de formulario | 24pt |
| Espaciado entre items en lista | 6pt vertical |
| Espaciado interno de sección | 12pt |
| Espaciado en grid (accesos rápidos) | 20pt |

---

## 4. Componentes Reutilizables

### 4.1 FormSection (Sección de Formulario)
Componente principal para agrupar campos en formularios.

**Estructura:**
- Título en `.subheadline` color secundario, con padding horizontal
- Contenido con padding interno
- Fondo `secondarySystemBackground` (gris claro)
- Esquinas redondeadas 16pt
- Campos separados por `Divider()`

**Ejemplo visual:**
```
TÍTULO DE SECCIÓN          ← gris, 15pt
┌────────────────────────┐
│ Campo 1                │  ← fondo gris claro
│ ─────────────────────  │  ← Divider
│ Campo 2                │
│ ─────────────────────  │
│ Campo 3                │
└────────────────────────┘  ← esquinas redondeadas 16pt
```

### 4.2 Tarjeta de Lista (Card)
Para items en listas tipo catálogo.

**Estructura:**
- VStack alineado a la izquierda, spacing 6pt
- Título en `.headline`
- Subtexto en `.caption` color secundario
- Padding interno
- Fondo blanco
- Esquinas redondeadas 16pt
- Sombra suave (0.05 opacidad, radio 3)
- Chevron derecho para navegación

### 4.3 Sección de Catálogo (CatalogSection)
Para el menú de catálogos agrupados.

**Estructura:**
- Icono + título en `.subheadline` color secundario
- Lista de items con texto + chevron derecho
- Items separados por Divider con padding izquierdo
- Fondo blanco, esquinas redondeadas 16pt
- Sombra suave

### 4.4 Accesos Rápidos (Dashboard)
Grid de 2 columnas con tarjetas de acceso rápido.

**Estructura:**
- Icono centrado
- Texto debajo del icono
- Esquinas redondeadas
- Sombra suave
- Grid de 2 columnas, spacing 20pt

---

## 5. Patrones de Pantalla

### 5.1 Login
```
[Espaciador]

"Iniciar sesión"              ← .largeTitle, bold

[ Email input              ]  ← fondo gris, esquinas 10pt
[ Contraseña input         ]  ← SecureField, mismo estilo

[Mensaje de error en rojo]    ← Solo si hay error

[ ===== Entrar ====== ]       ← Botón prominente azul, ancho completo

"Crear cuenta"                ← Link de navegación

───────────────────────
"¿No tienes cuenta?"          ← .footnote, gris
"Contáctanos..."

[WhatsApp] [Email] [Llamar]   ← Iconos con labels
```

### 5.2 Lista de Catálogo (ej: Agentes, Clientes)
```
← Atrás    TÍTULO        [+]   ← Toolbar con botón agregar

┌─────────────────────────────┐
│ Nombre Completo             │  ← .headline
│ Detalle secundario          │  ← .caption, gris
└─────────────────────────────┘  ← Card con sombra suave

┌─────────────────────────────┐
│ Otro Item                   │
│ Subtexto                    │
└─────────────────────────────┘
```

### 5.3 Formulario (ej: Nuevo Agente, Nuevo Cliente)
```
Cancelar   TÍTULO      Guardar   ← Toolbar

SECCIÓN TÍTULO                    ← subheadline, gris
┌────────────────────────────┐
│ Campo 1                    │
│ ─────────────────────────  │
│ Campo 2                    │
└────────────────────────────┘

OTRA SECCIÓN
┌────────────────────────────┐
│ Campo 3                    │
│ ─────────────────────────  │
│ Campo 4                    │
└────────────────────────────┘

┌────────────────────────────┐
│ Activo              [ON]   │   ← Toggle
└────────────────────────────┘
```

### 5.4 Navegación Principal (TabBar)
4 tabs principales:

| Tab | Icono | Contenido |
|-----|-------|-----------|
| Operación | `gearshape.2.fill` | Costos, Producción, Recibos, Inventarios, Diseño |
| Compras | `cart.fill` | Compras Clientes, Compras Insumos, Servicios |
| Ventas | `(ventas icon)` | Órdenes, Ventas, Salidas, Reingresos, Comisiones |
| Admin | `building.2.fill` | Financiero, Reportes, Catálogos, Usuarios, Ajustes |

Cada tab contiene un NavigationStack con una List de NavigationLinks.

### 5.5 Dashboard (Inicio)
```
"Bienvenido a"                   ← .headline, gris
"Textil Manager"                 ← .largeTitle, bold
"Nombre del usuario"             ← .subheadline, gris

"Accesos rápidos"                ← .title3, bold

┌─────────┐ ┌─────────┐
│  Icono  │ │  Icono  │        ← Grid 2 columnas
│  Label  │ │  Label  │
└─────────┘ └─────────┘
┌─────────┐ ┌─────────┐
│  Icono  │ │  Icono  │
│  Label  │ │  Label  │
└─────────┘ └─────────┘
```

### 5.6 Detalle con Totales (Orden, Venta)
```
SECCIÓN HEADER
┌────────────────────────────┐
│ # de Venta        Venta #1 │
│ Fecha captura     16 Feb   │
│ Fecha entrega     [picker] │
└────────────────────────────┘

SECCIÓN PRODUCTO               ← Form con Pickers
┌────────────────────────────┐
│ Artículo      [Seleccionar]│
│ Modelo        [Seleccionar]│
│ Cantidad      [___]        │
│ Precio Unit.  [___]        │
└────────────────────────────┘

RESUMEN                        ← Al fondo
┌────────────────────────────┐
│ Subtotal          $X,XXX   │
│ IVA (16%)           $XXX   │
│ Total             $X,XXX   │  ← Bold
└────────────────────────────┘
```

---

## 6. Comportamientos de UI

### Navegación
- **NavigationStack** con push/pop estándar
- **Título grande** (`.large`) en pantallas principales
- **Título inline** en sub-pantallas y formularios
- **Sheet modal** para formularios de "Nuevo..." (se abre desde abajo)

### Formularios
- **Cancelar** a la izquierda del toolbar
- **Guardar** a la derecha del toolbar, en semibold
- Campos de texto con placeholder descriptivo
- Valores monetarios con formato "MX $" y campo numérico a la derecha
- Toggle para estado Activo/Inactivo siempre al final del formulario
- Fondo general gris claro (`systemGray6`)

### Listas
- Ordenadas alfabéticamente por nombre (ascendente)
- Items inactivos muestran badge "Inactivo" en rojo
- Botón "+" en toolbar derecho para agregar nuevo
- Navegación a detalle/edición al tocar un item
- `ContentUnavailableView` cuando la lista está vacía (icono + mensaje)

### Moneda
- Formato: `MX $ X,XXX.XX`
- Función helper `formatoMX(_ valor: Double) -> String`
- Usa `String(format: "%.2f", valor)` para 2 decimales

### Permisos (visibilidad)
- Secciones/botones se ocultan según rol del usuario
- `authVM.esAdmin` → muestra opciones de admin
- `authVM.esSuperAdmin` → muestra gestión de usuarios
- Items con `.mostrarSi(condicion)` modifier

---

## 7. Header de la App

```
┌──────────────────────────────────┐
│ Nombre de Empresa    ← headline │  ← Material semitransparente
│ Rol del usuario      ← caption  │
└──────────────────────────────────┘
```

---

## 8. Catálogos — Agrupación

Los catálogos se organizan en 4 grupos con iconos:

| Grupo | Icono | Catálogos |
|-------|-------|-----------|
| Comerciales | `briefcase.fill` | Agentes, Clientes, Empresas, Proveedores |
| Artículo | `tag.fill` | Artículos, Colores, Departamentos, Líneas, Marcas, Modelos, Tallas, Telas, Unidades |
| Operativos | `gearshape.fill` | Maquileros |
| Servicios | `wrench.and.screwdriver.fill` | Servicios |

Los items dentro de cada grupo se ordenan alfabéticamente.

---

## 9. Resumen de Principios

1. **Consistencia iOS nativa** — Seguir los patrones de diseño de iOS (colores del sistema, tipografía SF, esquinas redondeadas)
2. **Fondo gris, tarjetas blancas** — Patrón grouped para separar contenido visualmente
3. **Secciones con título** — Todo formulario agrupa campos en secciones con título gris
4. **Esquinas redondeadas 16pt** — En tarjetas, secciones y inputs
5. **Sombras sutiles** — Solo 0.05 de opacidad, radio 3-4
6. **Navegación predecible** — Push para detalles, modal para crear nuevo
7. **Roles determinan visibilidad** — No deshabilitar, sino ocultar lo que no aplica
8. **Formato monetario MX** — Siempre con prefijo "MX $" y 2 decimales
