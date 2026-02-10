# Plan de Implementación - Textil App Móvil

## Resumen del Proyecto

**Textil** es una aplicación móvil nativa iOS desarrollada en SwiftUI que gestiona operaciones de una empresa textil. Se conecta a Supabase como backend (autenticación + base de datos PostgreSQL).

El objetivo es migrar la aplicación a **React Native / Expo** para poder ejecutarla y probarla en dispositivos iOS y Android sin depender de Xcode ni macOS.

---

## Análisis del Código Existente

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Líneas de código | ~25,190 |
| Modelos de datos | 64 |
| Vistas (pantallas) | 94 |
| Servicios / Helpers | 15 |
| Framework UI | SwiftUI + SwiftData |
| Backend | Supabase (Auth + PostgreSQL) |
| Roles existentes | `superadmin`, `admin`, usuario regular |

### Tablas en Supabase (ya existentes)

| Tabla | Campos clave |
|-------|-------------|
| **perfiles** | id (uuid, FK auth), empresa_id (uuid), nombre, email, rol, aprobado (bool), activo (bool), created_at |
| **empresas** | id (uuid), nombre, aprobado (bool), activo (bool), created_at |
| **Usuarios** | id (uuid), created_at, email, nombre, rol, empresa, activo (bool) |

### Flujo de Autenticación Actual

1. El usuario ingresa email y contraseña
2. Se autentica contra Supabase Auth (`signInWithPassword`)
3. Se carga el perfil desde la tabla `perfiles` (con JOIN a `empresas`)
4. Si `activo == false` → se muestra pantalla de **usuario bloqueado**
5. Si `aprobado == false` → se muestra pantalla de **pendiente de aprobación**
6. Si todo OK → se muestra la app principal con pestañas filtradas por rol

### Sistema de Roles Actual

| Rol | Acceso |
|-----|--------|
| **Usuario regular** | Catálogos, Producción, Recibos, Órdenes, Compras, Inventarios, Perfil |
| **Admin** | Todo lo anterior + Costos, Costeos, Mezclilla, Servicios, Ventas, Salidas, Reingresos |
| **Superadmin** | Todo lo anterior + Gestión de Usuarios, Resúmenes de Producción y Compras |

---

## Módulos del Sistema (176 archivos)

### 1. Catálogos Comerciales
- Agentes (modelo + formulario + lista)
- Clientes (modelo + formulario + lista)
- Empresas (modelo + formulario + lista)
- Proveedores (modelo + formulario + lista)

### 2. Catálogos de Artículos
- Artículos, Colores, Departamentos, Líneas, Marcas, Modelos, Tallas, Telas, Unidades
- Cada uno con su modelo de datos, formulario de alta/edición y vista de lista

### 3. Costos (solo admin+)
- Costos Generales (entidad, detalle, tarjeta, lista, alta)
- Costos Mezclilla (entidad, detalle, lista, alta)
- Costeos (lista, historial, tarjeta por modelo)

### 4. Producción
- Producción (modelo, lista, detalle, tarjeta, fila, firma)
- Recibos de producción

### 5. Órdenes y Compras
- Órdenes de clientes (alta, edición, detalle, lista, exportación)
- Compras de clientes (modelo, detalle, fila, lista)
- Compras de insumos (lista)
- Órdenes de compra (modelo, detalle, vista)

### 6. Servicios (solo admin+)
- Solicitudes de servicios
- Recibos de compras/servicios
- Servicio (modelo + formulario + lista)

### 7. Inventarios
- Vista de inventarios
- Movimientos de inventario
- Helper y servicio de inventario

### 8. Ventas y Movimientos (solo admin+)
- Ventas a clientes (modelo, detalle, lista, nueva venta, PDF, Excel)
- Salidas de insumos (modelo, detalle, lista, nueva salida, PDF, Excel)
- Reingresos (modelo, detalle, lista, nuevo, PDF, Excel, helpers)

### 9. Usuarios y Seguridad (solo superadmin)
- Administración de usuarios (aprobar/bloquear)
- Vista de perfil con cierre de sesión
- Configuración de seguridad (contraseñas para editar/cancelar órdenes)

### 10. Resúmenes (solo superadmin)
- Resumen de producción (vista, detalle, tarjetas)
- Resumen de compras de clientes

---

## Fase 1 - Alcance Solicitado

**Objetivo:** Implementar el sistema de autenticación, gestión de usuarios y roles.

### Entregables

#### E1. Configuración del Proyecto
- Proyecto React Native / Expo configurado
- Dependencias instaladas (Supabase JS, React Navigation, AsyncStorage)
- Estructura de carpetas definida
- Conexión a Supabase existente

**Estimación: 2 horas**

---

#### E2. Pantalla de Login
- Campos de email y contraseña
- Validaciones (campos vacíos, formato de email)
- Manejo de errores en español:
  - "Email o contraseña incorrectos"
  - "Debes confirmar tu email primero"
  - "Falta el email"
- Indicador de carga durante autenticación
- Diseño oscuro coherente con la identidad de la app

**Estimación: 3 horas**

---

#### E3. Contexto de Autenticación
- Proveedor de contexto global (`AuthContext`)
- Verificación automática de sesión existente al abrir la app
- Carga de perfil desde `perfiles` con JOIN a `empresas`
- Evaluación de estados: bloqueado, pendiente, activo
- Helpers de rol: `esAdmin`, `esSuperAdmin`
- Persistencia de sesión con AsyncStorage
- Función de cierre de sesión

**Estimación: 4 horas**

---

#### E4. Pantallas de Estado de Usuario
- **Pantalla "Usuario Bloqueado"**: Ícono, mensaje descriptivo, botón de cerrar sesión
- **Pantalla "Pendiente de Aprobación"**: Ícono, mensaje, botón "Verificar estado", botón de cerrar sesión

**Estimación: 2 horas**

---

#### E5. Navegación Principal con Filtrado por Rol
- Navegador de stack (flujo de autenticación)
- Navegador de pestañas (app principal)
- Pestañas visibles según rol del usuario:
  - Todos: Inicio, Perfil
  - Admin+: Pestañas adicionales según permisos
  - Superadmin: Gestión de Usuarios, Gestión de Roles
- Pantalla de carga mientras se verifica la sesión

**Estimación: 4 horas**

---

#### E6. Pantalla de Perfil
- Mostrar datos del usuario: nombre, email, rol, empresa, estado
- Botón de cerrar sesión
- Diseño con tarjeta informativa

**Estimación: 2 horas**

---

#### E7. Pantalla de Gestión de Usuarios (solo superadmin)
- Lista de todos los usuarios desde tabla `perfiles`
- Para cada usuario mostrar: nombre/email, rol, empresa
- Controles para:
  - Aprobar / Rechazar usuario (toggle `aprobado`)
  - Activar / Desactivar usuario (toggle `activo`)
  - Cambiar rol (selector: usuario, admin, superadmin)
- Búsqueda/filtrado de usuarios
- Confirmación antes de cambios críticos
- Recarga automática después de cada cambio

**Estimación: 6 horas**

---

#### E8. Pantalla de Gestión de Roles (solo superadmin)
- Vista de los roles disponibles y sus permisos
- Descripción de qué acceso tiene cada rol:
  - **Usuario regular**: módulos básicos
  - **Admin**: módulos básicos + costos, servicios, ventas
  - **Superadmin**: acceso completo + gestión de usuarios
- Visualización de cuántos usuarios tiene cada rol
- Posibilidad de asignar roles desde esta vista

**Estimación: 4 horas**

---

#### E9. Pruebas y Ajustes
- Pruebas de flujo completo de login
- Pruebas de bloqueo/aprobación de usuarios
- Pruebas de cambio de roles
- Verificación de filtrado de pestañas por rol
- Corrección de errores encontrados
- Ajustes de diseño y usabilidad

**Estimación: 4 horas**

---

#### E10. Documentación
- Documentación técnica del proyecto actualizada
- Instrucciones de configuración y despliegue
- Documentación de la estructura de carpetas
- Notas sobre variables de entorno y configuración de Supabase

**Estimación: 1 hora**

---

## Resumen de Esfuerzo - Fase 1

| # | Entregable | Horas |
|---|-----------|-------|
| E1 | Configuración del Proyecto | 2 |
| E2 | Pantalla de Login | 3 |
| E3 | Contexto de Autenticación | 4 |
| E4 | Pantallas de Estado (Bloqueado/Pendiente) | 2 |
| E5 | Navegación con Filtrado por Rol | 4 |
| E6 | Pantalla de Perfil | 2 |
| E7 | Gestión de Usuarios | 6 |
| E8 | Gestión de Roles | 4 |
| E9 | Pruebas y Ajustes | 4 |
| E10 | Documentación | 1 |
| | **TOTAL FASE 1** | **32 horas** |

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
| Autenticación | Supabase Auth |
| Base de datos | PostgreSQL (Supabase) |
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
│   │   └── supabaseClient.js
│   ├── auth/
│   │   └── AuthContext.js
│   ├── navigation/
│   │   └── AppNavigator.js
│   ├── screens/
│   │   ├── LoginScreen.js
│   │   ├── BlockedScreen.js
│   │   ├── PendingScreen.js
│   │   ├── ProfileScreen.js
│   │   └── admin/
│   │       ├── UserManagementScreen.js
│   │       └── RoleManagementScreen.js
│   └── components/
│       └── (componentes reutilizables)
├── App.js
├── app.json
└── package.json
```

---

## Notas Importantes

1. **El código Swift original se conserva** intacto en la carpeta `Textil/` como referencia.
2. **La base de datos en Supabase ya existe** y no se requieren migraciones para la Fase 1.
3. **Las políticas de seguridad (RLS)** en Supabase deben estar configuradas para proteger las tablas `perfiles` y `empresas` — verificar que solo superadmin pueda modificar otros perfiles.
4. **La app móvil se puede probar** directamente en un dispositivo físico (iPhone/Android) usando Expo Go y escaneando un código QR.
