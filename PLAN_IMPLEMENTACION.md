# Plan de Implementacion — App Textil

## 1. Introduccion

Textil es un sistema de gestion para empresas textiles. Actualmente existe un codigo en SwiftUI que solo funciona en Xcode/macOS y sirve como referencia de diseno y logica.

El objetivo es construir una app movil (iOS y Android) que se conecte a Supabase para centralizar la informacion, compartir datos por empresa y controlar permisos por roles.

---

## 2. Objetivo

Resolver los siguientes requerimientos:

1. **Login con email y contrasena** vinculado a una empresa
2. **Datos compartidos**: todos los usuarios de la misma empresa ven la misma informacion
3. **Separacion entre empresas**: si un usuario cambia de empresa, ve informacion diferente
4. **Control por roles**: no todos los empleados ven lo mismo segun su rol

---

## 3. Situacion Actual

### Analisis del codigo de referencia

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Lineas de codigo | ~25,190 |
| Modelos de datos | 47 (locales) + 3 (servidor) |
| Vistas (pantallas) | 94 |
| Servicios / Helpers | 15 |

### Hallazgo importante: donde se guardan los datos

La gran mayoria de los datos del negocio se guardan **localmente en cada telefono**, no en el servidor.

**En el servidor (Supabase) — se comparten:**

| Tabla | Uso |
|-------|-----|
| perfiles | Datos del usuario (nombre, email, rol, empresa, aprobado, activo) |
| empresas | Catalogo de empresas |
| Usuarios | Referencia de usuarios |

Solo 5 de los 176 archivos se conectan a Supabase.

**En el telefono (SwiftData) — NO se comparten:**

Los otros **47 modelos** se guardan localmente en cada telefono:

| Categoria | Modelos |
|-----------|---------|
| Catalogos | Agente, Cliente, Empresa (local), Proveedor, Articulo, Color, Modelo, Talla, Tela, PrecioTela, Departamento, Linea, Marca, Unidad, Maquilero, Servicio, TipoTela |
| Ordenes | OrdenCliente, OrdenClienteDetalle, OrdenCompra, OrdenCompraDetalle |
| Compras | CompraCliente, CompraClienteDetalle |
| Produccion | Produccion, ReciboProduccion, ProduccionFirma |
| Recibos | ReciboCompra, ReciboCompraPago, ReciboCompraDetalle, PagoRecibo |
| Ventas | VentaCliente, VentaClienteDetalle |
| Salidas | SalidaInsumo, SalidaInsumoDetalle |
| Reingresos | Reingreso, ReingresoDetalle, ReingresoMovimiento |
| Costos | CostoMezclillaEntity, CostoGeneralEntity |

**Esto significa que si el usuario A crea un cliente en su telefono, el usuario B nunca lo va a ver.** Cada telefono tiene su propia base de datos aislada.

### Que existe y que no

| Elemento | Estado |
|----------|--------|
| Codigo Swift (SwiftUI) | Solo referencia, no se puede ejecutar aqui |
| Supabase (Backend) | Parcial, solo autenticacion y perfiles |
| Tablas de negocio en Supabase | No existen, todo esta en cada telefono |
| App movil | No existe, es lo que se va a construir |
| Datos compartidos por empresa | No existe, se construira en Fase 2 |

### Tablas que ya existen en Supabase

| Tabla | Campos clave |
|-------|-------------|
| perfiles | id, empresa_id, nombre, email, rol, aprobado, activo, created_at |
| empresas | id, nombre, aprobado, activo, created_at |
| Usuarios | id, created_at, email, nombre, rol, empresa, activo |

---

## 4. Que se necesita construir

### Flujo de autenticacion

1. El usuario abre la app y se verifica si hay sesion guardada
2. Si no hay sesion, se muestra pantalla de Login (email + contrasena)
3. Se autentica contra Supabase Auth
4. Se carga el perfil del usuario con datos de su empresa
5. La empresa_id del perfil determina que datos ve
6. Si esta desactivado, se muestra pantalla de usuario bloqueado
7. Si no esta aprobado, se muestra pantalla de pendiente
8. Si todo esta bien, se muestra la app con modulos filtrados por rol

### Roles

| Rol | Acceso |
|-----|--------|
| Usuario regular | Catalogos, Produccion, Recibos, Ordenes, Compras, Inventarios, Perfil |
| Admin | Todo lo anterior + Costos, Costeos, Mezclilla, Servicios, Ventas, Salidas, Reingresos |
| Superadmin | Todo lo anterior + Gestion de Usuarios, Gestion de Roles, Resumenes |

### Modulos del sistema

1. **Catalogos Comerciales** — Agentes, Clientes, Empresas, Proveedores
2. **Catalogos de Articulos** — Articulos, Colores, Departamentos, Lineas, Marcas, Modelos, Tallas, Telas, Unidades
3. **Costos** (solo admin+) — Costos Generales, Costos Mezclilla, Costeos
4. **Produccion** — Produccion, Recibos de produccion
5. **Ordenes y Compras** — Ordenes de clientes, Compras de clientes, Compras de insumos
6. **Servicios** (solo admin+) — Solicitudes, Recibos
7. **Inventarios** — Vista de inventarios, Movimientos
8. **Ventas y Movimientos** (solo admin+) — Ventas, Salidas de insumos, Reingresos
9. **Usuarios y Seguridad** (solo superadmin) — Administracion de usuarios, Perfil
10. **Resumenes** (solo superadmin) — Resumen de produccion, Resumen de compras

---

## 5. Plan de Proyecto

### Fase 1 — Login, Usuarios y Roles (32 horas)

| # | Entregable | Horas |
|---|-----------|-------|
| E1 | Configuracion del proyecto (React Native/Expo, Supabase, navegacion) | 2 |
| E2 | Pantalla de Login (email + contrasena, validaciones, errores en espanol) | 3 |
| E3 | Sistema de autenticacion (sesion, perfil, empresa_id, roles, estados) | 4 |
| E4 | Pantallas de estado (usuario bloqueado y pendiente de aprobacion) | 2 |
| E5 | Navegacion principal con filtrado por rol | 4 |
| E6 | Pantalla de Perfil (datos del usuario, cerrar sesion) | 2 |
| E7 | Gestion de Usuarios — solo superadmin (lista, aprobar, activar, cambiar rol) | 6 |
| E8 | Gestion de Roles — solo superadmin (permisos por rol, asignar) | 4 |
| E9 | Pruebas y ajustes | 4 |
| E10 | Documentacion | 1 |
| | **Total Fase 1** | **32** |

**Cronograma:**

| Semana | Actividades |
|--------|-------------|
| Semana 1 | Configuracion + Login + Autenticacion |
| Semana 2 | Pantallas de estado + Navegacion + Perfil |
| Semana 3 | Gestion de usuarios + Gestion de roles |
| Semana 4 | Pruebas y ajustes + Documentacion |

---

### Fase 2 — Migracion de Datos al Servidor (22 horas)

Esta fase es necesaria para que todos los de la misma empresa vean la misma informacion.

| # | Entregable | Horas |
|---|-----------|-------|
| E11 | Diseno de las ~47 tablas en Supabase (con empresa_id, relaciones) | 6 |
| E12 | Creacion de tablas en Supabase (migraciones, indices) | 4 |
| E13 | Politicas de seguridad para que cada empresa solo vea sus datos | 4 |
| E14 | Funciones para leer/escribir datos desde la app (filtrado automatico por empresa) | 8 |
| | **Total Fase 2** | **22** |

**Cronograma:**

| Semana | Actividades |
|--------|-------------|
| Semana 5 | Diseno + creacion de tablas |
| Semana 6 | Politicas de seguridad + capa de datos |

---

### Fases Futuras — Pantallas de cada modulo

| Fase | Modulos | Horas |
|------|---------|-------|
| Fase 3 | Catalogos (Agentes, Clientes, Proveedores, Articulos, etc.) | 40-50 |
| Fase 4 | Ordenes de clientes + Compras | 30-40 |
| Fase 5 | Produccion + Recibos | 25-30 |
| Fase 6 | Costos y Costeos | 20-25 |
| Fase 7 | Inventarios + Salidas + Reingresos | 25-30 |
| Fase 8 | Ventas + PDF/Excel | 20-25 |
| Fase 9 | Servicios + Solicitudes | 15-20 |
| Fase 10 | Resumenes y Reportes | 15-20 |
| Fase 11 | Firmas digitales + Funcionalidad avanzada | 10-15 |

---

## 6. Resumen de Horas

| Fase | Descripcion | Horas |
|------|-------------|-------|
| Fase 1 | Login, Usuarios y Roles | 32 |
| Fase 2 | Migracion de datos al servidor | 22 |
| Fases 3-11 | Pantallas de todos los modulos | 200-255 |
| | **Total estimado** | **254-309** |

---

## 7. Supuestos y Consideraciones

1. Se cuenta con acceso al proyecto de Supabase (URL y clave ya disponibles).
2. Las tablas existentes (perfiles, empresas, Usuarios) se mantienen sin cambios.
3. La autenticacion con Supabase Auth ya esta configurada.
4. El codigo Swift se usa solo como referencia, no se reutiliza directamente.
5. La app se puede probar en dispositivos fisicos con Expo Go (escanear QR).
6. La Fase 2 es obligatoria para que funcione el modelo de datos compartidos por empresa.
7. empresa_id es la llave de todo el sistema: cada tabla debe tener este campo para filtrar por empresa.
8. Las politicas de seguridad garantizan que la Empresa A nunca vea datos de la Empresa B.
9. Hoy los datos viven solo en cada telefono. Para compartirlos, todo debe moverse al servidor.

---

## 8. Tecnologias

| Componente | Tecnologia |
|-----------|-----------|
| App movil | React Native + Expo |
| Backend | Supabase (ya existente) |
| Autenticacion | Supabase Auth |
| Base de datos | PostgreSQL via Supabase |
| Navegacion | React Navigation |
| Estado global | React Context API |
| Sesion local | AsyncStorage |
| Idioma | Espanol (Mexico) |

---

## 9. Estructura de Carpetas

```
textil-mobile/
    src/
        api/
            supabaseClient.js
        auth/
            AuthContext.js
        navigation/
            AppNavigator.js
        screens/
            LoginScreen.js
            BlockedScreen.js
            PendingScreen.js
            ProfileScreen.js
            admin/
                UserManagementScreen.js
                RoleManagementScreen.js
        components/
    App.js
    app.json
    package.json
```
