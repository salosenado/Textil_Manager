# Plan de Implementación - Textil App Móvil

## Resumen del Proyecto

**Textil** es un sistema de gestión para una empresa textil. Actualmente existe como código fuente en SwiftUI (solo funciona en Xcode con macOS), pero **no hay ninguna app funcional corriendo en este momento**.

El objetivo es **construir desde cero** una app móvil en **React Native / Expo** que se conecte al backend de Supabase que ya existe con datos reales.

---

## ¿Qué ya existe?

| Elemento | Estado | Descripción |
|----------|--------|-------------|
| Código Swift (SwiftUI) | Solo referencia | 176 archivos Swift que sirven como guía del diseño original. No se pueden ejecutar aquí — requieren Xcode en macOS. |
| Supabase (Backend) | Funcionando | Autenticación y base de datos PostgreSQL ya configurados y operando. |
| Tablas en Supabase | Listas | `perfiles`, `empresas`, `Usuarios` ya creadas con datos. |
| App móvil React Native | **No existe** | Es lo que se va a construir en este plan. |
| Login funcional | **No existe** | Se construirá como parte de la Fase 1. |
| Gestión de usuarios | **No existe** | Se construirá como parte de la Fase 1. |

---

## Análisis del Código de Referencia (SwiftUI)

El código Swift sirve únicamente como **guía de diseño y lógica** para saber qué construir:

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Líneas de código | ~25,190 |
| Modelos de datos | 64 |
| Vistas (pantallas) | 94 |
| Servicios / Helpers | 15 |

---

## Tablas en Supabase (ya existentes y funcionando)

| Tabla | Campos clave |
|-------|-------------|
| **perfiles** | id (uuid, FK auth), empresa_id (uuid), nombre, email, rol, aprobado (bool), activo (bool), created_at |
| **empresas** | id (uuid), nombre, aprobado (bool), activo (bool), created_at |
| **Usuarios** | id (uuid), created_at, email, nombre, rol, empresa, activo (bool) |

---

## Flujo de Autenticación a Construir

1. El usuario abre la app → se verifica si hay sesión guardada
2. Si no hay sesión → se muestra **pantalla de Login** (email + contraseña)
3. Se autentica contra Supabase Auth
4. Se carga el perfil del usuario desde la tabla `perfiles` (con datos de su empresa)
5. Si `activo == false` → **pantalla de usuario bloqueado**
6. Si `aprobado == false` → **pantalla de pendiente de aprobación**
7. Si todo OK → **app principal** con pestañas filtradas según su rol

---

## Sistema de Roles a Implementar

| Rol | Acceso |
|-----|--------|
| **Usuario regular** | Catálogos, Producción, Recibos, Órdenes, Compras, Inventarios, Perfil |
| **Admin** | Todo lo anterior + Costos, Costeos, Mezclilla, Servicios, Ventas, Salidas, Reingresos |
| **Superadmin** | Todo lo anterior + Gestión de Usuarios, Gestión de Roles, Resúmenes |

---

## Módulos del Sistema Completo (referencia para fases futuras)

### 1. Catálogos Comerciales
- Agentes, Clientes, Empresas, Proveedores (cada uno con lista + formulario)

### 2. Catálogos de Artículos
- Artículos, Colores, Departamentos, Líneas, Marcas, Modelos, Tallas, Telas, Unidades

### 3. Costos (solo admin+)
- Costos Generales, Costos Mezclilla, Costeos

### 4. Producción
- Producción (lista, detalle, firma digital), Recibos de producción

### 5. Órdenes y Compras
- Órdenes de clientes, Compras de clientes, Compras de insumos

### 6. Servicios (solo admin+)
- Solicitudes de servicios, Recibos de compras/servicios

### 7. Inventarios
- Vista de inventarios, Movimientos

### 8. Ventas y Movimientos (solo admin+)
- Ventas a clientes, Salidas de insumos, Reingresos (con PDF y Excel)

### 9. Usuarios y Seguridad (solo superadmin)
- Administración de usuarios, Perfil, Seguridad

### 10. Resúmenes (solo superadmin)
- Resumen de producción, Resumen de compras

---

## Fase 1 - Alcance: Login, Usuarios y Roles

**Todo se construye desde cero.** El código Swift solo se usa como referencia de la lógica.

### Entregables

#### E1. Configuración del Proyecto — 2 horas
- Crear proyecto React Native / Expo desde cero
- Instalar dependencias (Supabase JS, React Navigation, AsyncStorage)
- Definir estructura de carpetas
- Configurar conexión a Supabase existente

---

#### E2. Pantalla de Login (nueva) — 3 horas
- Construir pantalla de inicio de sesión con campos de email y contraseña
- Validaciones (campos vacíos, formato de email)
- Manejo de errores en español:
  - "Email o contraseña incorrectos"
  - "Debes confirmar tu email primero"
  - "Falta el email"
- Indicador de carga durante autenticación
- Diseño oscuro coherente con la identidad de la app

---

#### E3. Contexto de Autenticación (nuevo) — 4 horas
- Crear sistema central que maneje toda la lógica de sesión
- Verificación automática de sesión al abrir la app
- Carga de perfil desde `perfiles` con datos de `empresas`
- Evaluación de estados: bloqueado, pendiente, activo
- Funciones para saber el rol: `esAdmin`, `esSuperAdmin`
- Guardar sesión en el dispositivo (no tener que hacer login cada vez)
- Función de cierre de sesión

---

#### E4. Pantallas de Estado de Usuario (nuevas) — 2 horas
- **Pantalla "Usuario Bloqueado"**: Ícono, mensaje descriptivo, botón de cerrar sesión
- **Pantalla "Pendiente de Aprobación"**: Ícono, mensaje, botón "Verificar estado", botón de cerrar sesión

---

#### E5. Navegación Principal con Filtrado por Rol (nueva) — 4 horas
- Sistema de navegación entre pantallas
- Pestañas en la parte inferior filtradas según el rol del usuario:
  - Todos: Inicio, Perfil
  - Admin+: pestañas adicionales según permisos
  - Superadmin: Gestión de Usuarios, Gestión de Roles
- Pantalla de carga mientras se verifica la sesión

---

#### E6. Pantalla de Perfil (nueva) — 2 horas
- Mostrar datos del usuario: nombre, email, rol, empresa, estado (activo/inactivo)
- Botón de cerrar sesión
- Diseño con tarjeta informativa

---

#### E7. Pantalla de Gestión de Usuarios (nueva, solo superadmin) — 6 horas
- Lista de todos los usuarios desde tabla `perfiles`
- Para cada usuario mostrar: nombre/email, rol, empresa
- Controles para:
  - Aprobar / Rechazar usuario (toggle `aprobado`)
  - Activar / Desactivar usuario (toggle `activo`)
  - Cambiar rol (selector: usuario, admin, superadmin)
- Búsqueda/filtrado de usuarios
- Confirmación antes de cambios críticos
- Recarga automática después de cada cambio

---

#### E8. Pantalla de Gestión de Roles (nueva, solo superadmin) — 4 horas
- Vista de los roles disponibles y sus permisos
- Descripción clara de qué acceso tiene cada rol:
  - **Usuario regular**: módulos básicos
  - **Admin**: módulos básicos + costos, servicios, ventas
  - **Superadmin**: acceso completo + gestión de usuarios
- Visualización de cuántos usuarios tiene cada rol
- Posibilidad de asignar roles desde esta vista

---

#### E9. Pruebas y Ajustes — 4 horas
- Pruebas de flujo completo de login
- Pruebas de bloqueo/aprobación de usuarios
- Pruebas de cambio de roles
- Verificación de filtrado de pestañas por rol
- Corrección de errores encontrados
- Ajustes de diseño y usabilidad

---

#### E10. Documentación — 1 hora
- Documentación técnica del proyecto actualizada
- Instrucciones de configuración
- Documentación de la estructura de carpetas
- Notas sobre configuración de Supabase

---

## Resumen de Esfuerzo - Fase 1

| # | Entregable | Estado actual | Horas |
|---|-----------|---------------|-------|
| E1 | Configuración del Proyecto | No existe | 2 |
| E2 | Pantalla de Login | No existe | 3 |
| E3 | Contexto de Autenticación | No existe | 4 |
| E4 | Pantallas de Estado (Bloqueado/Pendiente) | No existe | 2 |
| E5 | Navegación con Filtrado por Rol | No existe | 4 |
| E6 | Pantalla de Perfil | No existe | 2 |
| E7 | Gestión de Usuarios | No existe | 6 |
| E8 | Gestión de Roles | No existe | 4 |
| E9 | Pruebas y Ajustes | — | 4 |
| E10 | Documentación | — | 1 |
| | **TOTAL FASE 1** | | **32 horas** |

---

## Fases Futuras (fuera de este alcance)

| Fase | Módulos | Estimación aproximada |
|------|---------|----------------------|
| Fase 2 | Catálogos completos (Agentes, Clientes, Empresas, Proveedores, Artículos, etc.) | 40-50 hrs |
| Fase 3 | Órdenes de clientes + Compras | 30-40 hrs |
| Fase 4 | Producción + Recibos | 25-30 hrs |
| Fase 5 | Costos y Costeos | 20-25 hrs |
| Fase 6 | Inventarios + Salidas + Reingresos | 25-30 hrs |
| Fase 7 | Ventas + Generación de PDF/Excel | 20-25 hrs |
| Fase 8 | Servicios + Solicitudes | 15-20 hrs |
| Fase 9 | Resúmenes y Reportes | 15-20 hrs |
| Fase 10 | Firmas digitales + Funcionalidad avanzada | 10-15 hrs |
| | **TOTAL ESTIMADO (todas las fases)** | **~230-285 hrs** |

---

## Tecnologías Propuestas

| Componente | Tecnología |
|-----------|-----------|
| Framework móvil | React Native + Expo |
| Backend | Supabase (ya existente) |
| Autenticación | Supabase Auth (ya configurado) |
| Base de datos | PostgreSQL vía Supabase (ya existente) |
| Navegación | React Navigation (Stack + Tabs) |
| Estado global | React Context API |
| Persistencia local | AsyncStorage |
| Idioma de la app | Español (México) |

---

## Estructura de Carpetas Propuesta

```
textil-mobile/
├── src/
│   ├── api/
│   │   └── supabaseClient.js        ← Conexión a Supabase
│   ├── auth/
│   │   └── AuthContext.js            ← Lógica de sesión y roles
│   ├── navigation/
│   │   └── AppNavigator.js           ← Navegación entre pantallas
│   ├── screens/
│   │   ├── LoginScreen.js            ← Pantalla de login
│   │   ├── BlockedScreen.js          ← Usuario bloqueado
│   │   ├── PendingScreen.js          ← Pendiente de aprobación
│   │   ├── ProfileScreen.js          ← Perfil del usuario
│   │   └── admin/
│   │       ├── UserManagementScreen.js  ← Gestión de usuarios
│   │       └── RoleManagementScreen.js  ← Gestión de roles
│   └── components/
│       └── (componentes reutilizables)
├── App.js
├── app.json
└── package.json
```

---

## Notas Importantes

1. **El código Swift original se conserva** intacto en la carpeta `Textil/` solo como referencia de diseño y lógica.
2. **La base de datos en Supabase ya existe** y no se requieren migraciones para la Fase 1.
3. **Las políticas de seguridad (RLS)** en Supabase deben verificarse para que solo superadmin pueda modificar otros perfiles.
4. **La app móvil se puede probar** directamente en un dispositivo físico (iPhone/Android) usando Expo Go y escaneando un código QR.
5. **Todo lo de la Fase 1 se construye desde cero** — no hay código funcional previo, solo el backend de Supabase.
