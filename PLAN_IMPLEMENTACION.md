# Plan de Implementación - Textil App Móvil

## Resumen del Proyecto

**Textil** es un sistema de gestión para una empresa textil. Actualmente existe como código fuente en SwiftUI (solo funciona en Xcode con macOS), pero **no hay ninguna app funcional corriendo en este momento**.

El objetivo es **construir desde cero** una app móvil en **React Native / Expo** que se conecte al backend de Supabase que ya existe con datos reales.

---

## HALLAZGO CRÍTICO: ¿Dónde se guardan los datos?

Al revisar el código original, se encontró lo siguiente:

### Datos en Supabase (servidor — compartidos)
Solo **3 tablas** están en el servidor y se comparten entre usuarios:

| Tabla | Uso |
|-------|-----|
| `perfiles` | Datos del usuario (nombre, email, rol, empresa, aprobado, activo) |
| `empresas` | Catálogo de empresas |
| `Usuarios` | Referencia de usuarios |

Solo **5 archivos** de los 176 se conectan a Supabase: `SuperbaseClient`, `AuthViewModel`, `LoginView`, `PerfilViewModel`, `UsuariosAdminView`.

### Datos en SwiftData (teléfono — NO compartidos)
Los otros **47 modelos** de datos se guardan **localmente en cada teléfono** usando SwiftData:

| Categoría | Modelos que se guardan solo en el teléfono |
|-----------|-------------------------------------------|
| Catálogos | Agente, Cliente, Empresa (local), Proveedor, Articulo, Color, Modelo, Talla, Tela, PrecioTela, Departamento, Linea, Marca, Unidad, Maquilero, Servicio, TipoTela |
| Órdenes | OrdenCliente, OrdenClienteDetalle, OrdenCompra, OrdenCompraDetalle |
| Compras | CompraCliente, CompraClienteDetalle |
| Producción | Produccion, ReciboProduccion, ProduccionFirma |
| Recibos | ReciboCompra, ReciboCompraPago, ReciboCompraDetalle, PagoRecibo |
| Ventas | VentaCliente, VentaClienteDetalle |
| Salidas | SalidaInsumo, SalidaInsumoDetalle |
| Reingresos | Reingreso, ReingresoDetalle, ReingresoMovimiento |
| Costos | CostoMezclillaEntity, CostoGeneralEntity |

### ¿Qué significa esto?

**La información NO se comparte entre usuarios ni entre dispositivos.** Si el usuario A crea un cliente en su teléfono, el usuario B nunca lo va a ver. Cada teléfono tiene su propia base de datos aislada.

Algunos modelos como `VentaCliente`, `SalidaInsumo` y `Reingreso` tienen un campo `empresa` como texto, pero es solo una referencia local — no filtra datos desde un servidor.

---

## ¿Qué se necesita para lograr lo que piden?

Lo que quieren es:

1. **Login con email, contraseña y empresa** → Supabase Auth ya lo soporta parcialmente (email + contraseña sí, empresa se obtiene del perfil)
2. **Todos los de la misma empresa ven la misma información** → Esto requiere **migrar los 47 modelos locales a tablas en Supabase** con un campo `empresa_id` para filtrar
3. **Si cambia de empresa, ve la información de la otra empresa** → Requiere que los datos estén en el servidor y se filtren por `empresa_id`
4. **Roles de empleados** → Ya existe parcialmente en la tabla `perfiles` (campo `rol`), solo hay que implementar el filtrado en la app

### Trabajo adicional necesario: Migración de datos al servidor

Para que los datos se compartan, se necesita:
1. **Crear las tablas en Supabase** para cada uno de los 47 modelos que hoy son locales
2. **Agregar `empresa_id`** a cada tabla para poder filtrar por empresa
3. **Configurar políticas de seguridad (RLS)** para que cada usuario solo vea datos de su empresa
4. **Cambiar la app** para que lea/escriba de Supabase en lugar del almacenamiento local

---

## ¿Qué ya existe?

| Elemento | Estado | Descripción |
|----------|--------|-------------|
| Código Swift (SwiftUI) | Solo referencia | 176 archivos. No se pueden ejecutar aquí. |
| Supabase (Backend) | Parcial | Solo autenticación y perfiles. Los datos de negocio NO están en el servidor. |
| Tablas de negocio en Supabase | **No existen** | Clientes, órdenes, producción, ventas, etc. solo están en cada teléfono. |
| App móvil React Native | **No existe** | Es lo que se va a construir. |
| Login funcional | **No existe** | Se construirá en Fase 1. |
| Datos compartidos por empresa | **No existe** | Se construirá en Fase 2+. |

---

## Análisis del Código de Referencia (SwiftUI)

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Líneas de código | ~25,190 |
| Modelos con `@Model` (locales) | 47 |
| Modelos con Supabase (servidor) | 3 |
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
5. La `empresa_id` del perfil determina qué datos ve el usuario
6. Si `activo == false` → **pantalla de usuario bloqueado**
7. Si `aprobado == false` → **pantalla de pendiente de aprobación**
8. Si todo OK → **app principal** con pestañas filtradas según su rol
9. Todos los datos se filtran por la `empresa_id` del usuario logueado

---

## Sistema de Roles a Implementar

| Rol | Acceso |
|-----|--------|
| **Usuario regular** | Catálogos, Producción, Recibos, Órdenes, Compras, Inventarios, Perfil |
| **Admin** | Todo lo anterior + Costos, Costeos, Mezclilla, Servicios, Ventas, Salidas, Reingresos |
| **Superadmin** | Todo lo anterior + Gestión de Usuarios, Gestión de Roles, Resúmenes |

---

## Fase 1 - Login, Usuarios y Roles (32 horas)

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
- Obtener la `empresa_id` del usuario para filtrar datos en fases futuras
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

## Fase 2 - Migración de Datos al Servidor (nueva, requerida)

**Esta fase es necesaria** para lograr que todos los usuarios de la misma empresa vean la misma información.

#### E11. Diseño de tablas en Supabase — 6 horas
- Diseñar las ~47 tablas que hoy son locales
- Agregar campo `empresa_id` a cada tabla
- Definir relaciones entre tablas (foreign keys)
- Documentar el esquema completo

#### E12. Crear tablas en Supabase — 4 horas
- Ejecutar las migraciones para crear todas las tablas
- Configurar índices para rendimiento
- Verificar integridad referencial

#### E13. Políticas de seguridad (RLS) — 4 horas
- Configurar Row Level Security en cada tabla
- Regla principal: cada usuario solo ve datos de su `empresa_id`
- Permisos de escritura según rol
- Pruebas de seguridad

#### E14. Capa de datos en la app — 8 horas
- Crear funciones para leer/escribir cada tabla desde la app
- Filtrar automáticamente por `empresa_id` del usuario logueado
- Manejo de errores y estados de carga

---

## Resumen de Esfuerzo - Fase 2

| # | Entregable | Horas |
|---|-----------|-------|
| E11 | Diseño de tablas en Supabase | 6 |
| E12 | Crear tablas en Supabase | 4 |
| E13 | Políticas de seguridad (RLS) | 4 |
| E14 | Capa de datos en la app | 8 |
| | **TOTAL FASE 2** | **22 horas** |

---

## Fases Futuras (construcción de pantallas)

Una vez que la Fase 2 esté lista (datos en servidor), se pueden construir las pantallas de cada módulo:

| Fase | Módulos | Estimación |
|------|---------|------------|
| Fase 3 | Catálogos completos (Agentes, Clientes, Empresas, Proveedores, Artículos, etc.) | 40-50 hrs |
| Fase 4 | Órdenes de clientes + Compras | 30-40 hrs |
| Fase 5 | Producción + Recibos | 25-30 hrs |
| Fase 6 | Costos y Costeos | 20-25 hrs |
| Fase 7 | Inventarios + Salidas + Reingresos | 25-30 hrs |
| Fase 8 | Ventas + Generación de PDF/Excel | 20-25 hrs |
| Fase 9 | Servicios + Solicitudes | 15-20 hrs |
| Fase 10 | Resúmenes y Reportes | 15-20 hrs |
| Fase 11 | Firmas digitales + Funcionalidad avanzada | 10-15 hrs |
| | **TOTAL FASES 3-11** | **~200-255 hrs** |

---

## Resumen General de Todo el Proyecto

| Fase | Descripción | Horas |
|------|-------------|-------|
| Fase 1 | Login, Usuarios y Roles | 32 |
| Fase 2 | Migración de datos al servidor | 22 |
| Fases 3-11 | Pantallas de todos los módulos | 200-255 |
| | **TOTAL COMPLETO** | **~254-309 hrs** |

---

## Tecnologías Propuestas

| Componente | Tecnología |
|-----------|-----------|
| Framework móvil | React Native + Expo |
| Backend | Supabase (ya existente, se amplía) |
| Autenticación | Supabase Auth (ya configurado) |
| Base de datos | PostgreSQL vía Supabase |
| Navegación | React Navigation (Stack + Tabs) |
| Estado global | React Context API |
| Persistencia local | AsyncStorage (solo sesión) |
| Idioma de la app | Español (México) |

---

## Estructura de Carpetas Propuesta

```
textil-mobile/
├── src/
│   ├── api/
│   │   └── supabaseClient.js        ← Conexión a Supabase
│   ├── auth/
│   │   └── AuthContext.js            ← Lógica de sesión, roles y empresa
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
2. **La base de datos en Supabase necesita ampliarse.** Hoy solo tiene 3 tablas (perfiles, empresas, Usuarios). Se necesitan ~47 tablas más para los datos de negocio.
3. **Hoy los datos viven en cada teléfono.** Eso significa que si un usuario crea un cliente, solo él lo ve. Para compartir información por empresa, TODO debe moverse al servidor (Fase 2).
4. **La `empresa_id` es la llave.** Cada dato en el servidor debe tener el campo `empresa_id` para filtrar qué empresa ve qué información.
5. **Las políticas de seguridad (RLS)** en Supabase garantizarán que un usuario de la Empresa A nunca vea datos de la Empresa B.
6. **La app móvil se puede probar** directamente en un dispositivo físico (iPhone/Android) usando Expo Go y escaneando un código QR.
7. **Todo se construye desde cero** — no hay código funcional previo ejecutable, solo el backend parcial de Supabase.
