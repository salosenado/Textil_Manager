# Plan de Implementacion — App Textil

## 1. Introduccion

Textil es un sistema de gestion para empresas textiles. Actualmente existe un codigo en SwiftUI que funciona en Xcode/macOS.

El objetivo es conectar la app a Supabase para centralizar la informacion, compartir datos por empresa y controlar permisos por roles.

Existen dos caminos posibles para lograrlo, y este documento presenta la comparacion entre ambos.

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
| Codigo Swift (SwiftUI) | Funciona en Xcode/Mac, pantallas y logica ya hechas |
| Supabase (Backend) | Parcial, solo autenticacion y perfiles |
| Tablas de negocio en Supabase | No existen, todo esta en cada telefono |
| Datos compartidos por empresa | No existe, se debe construir |

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

## 5. Comparacion de Opciones

### Opcion A: Seguir con Swift (solo iPhone)

Se conserva el codigo Swift actual y se modifica para conectar los 47 modelos al servidor. Las pantallas ya estan hechas, solo hay que cambiar de donde leen y escriben los datos.

**Ventajas:**
- Las 94 pantallas ya estan construidas
- Solo hay que modificar los modelos y la capa de datos
- Menos trabajo total

**Desventajas:**
- Solo funciona en iPhone (no Android)
- Se necesita Mac con Xcode para desarrollar y probar

### Opcion B: Migrar a React Native (iPhone + Android)

Se construye la app desde cero en React Native/Expo. Se toma el codigo Swift como referencia para replicar las pantallas y la logica.

**Ventajas:**
- Funciona en iPhone Y Android
- Una sola base de codigo para ambas plataformas

**Desventajas:**
- Se reconstruyen las 94 pantallas desde cero
- Mas horas de trabajo en total
- Curva de aprendizaje si el equipo solo conoce Swift

### Tabla comparativa de horas

| Fase | Opcion A: Swift (solo iPhone) | Opcion B: React Native (iPhone + Android) |
|------|-------------------------------|------------------------------------------|
| Fase 1 — Login, Usuarios y Roles | 20 hrs | 32 hrs |
| Fase 2 — Migracion de datos al servidor | 22 hrs | 22 hrs |
| | | |
| **Total Fases 1-2** | **42 hrs** | **54 hrs** |

**Diferencia Fase 1:** Con Swift son menos horas porque las pantallas de login, perfil y gestion de usuarios ya existen parcialmente. Con React Native se construyen desde cero.

**La Fase 2 es igual en ambos casos** porque el trabajo es en Supabase (crear tablas, politicas de seguridad) y eso no depende de la tecnologia de la app.

---

## 6. Plan de Proyecto

### Fase 1 — Login, Usuarios y Roles

**Opcion A: Swift (20 horas)**

| # | Entregable | Horas |
|---|-----------|-------|
| E1 | Ajustar proyecto Swift para nueva arquitectura de datos | 2 |
| E2 | Ajustar pantalla de Login existente (validaciones, errores en espanol) | 2 |
| E3 | Modificar sistema de autenticacion (empresa_id, roles, estados) | 3 |
| E4 | Ajustar pantallas de estado (bloqueado, pendiente) | 1 |
| E5 | Modificar navegacion para filtrado por rol | 3 |
| E6 | Ajustar pantalla de Perfil | 1 |
| E7 | Ajustar Gestion de Usuarios — solo superadmin | 4 |
| E8 | Crear Gestion de Roles — solo superadmin | 3 |
| E9 | Pruebas en Xcode/dispositivo | 1 |
| | **Total Fase 1 (Swift)** | **20** |

**Opcion B: React Native (32 horas)**

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
| | **Total Fase 1 (React Native)** | **32** |

---

### Fase 2 — Migracion de Datos al Servidor (22 horas, igual en ambas opciones)

Esta fase es necesaria para que todos los de la misma empresa vean la misma informacion.

| # | Entregable | Horas |
|---|-----------|-------|
| E11 | Diseno de las ~47 tablas en Supabase (con empresa_id, relaciones) | 6 |
| E12 | Creacion de tablas en Supabase (migraciones, indices) | 4 |
| E13 | Politicas de seguridad para que cada empresa solo vea sus datos | 4 |
| E14 | Funciones para leer/escribir datos desde la app (filtrado automatico por empresa) | 8 |
| | **Total Fase 2** | **22** |

---

### Fases Futuras — Pantallas de cada modulo (pendientes de estimar a detalle)

Estas fases se planificaran una vez completadas las Fases 1 y 2. Las horas son estimaciones iniciales que se refinaran conforme avance el proyecto.

| Fase | Modulos | Swift (est.) | React Native (est.) |
|------|---------|-------------|---------------------|
| Fase 3 | Catalogos | 15-20 | 40-50 |
| Fase 4 | Ordenes y Compras | 12-15 | 30-40 |
| Fase 5 | Produccion y Recibos | 10-12 | 25-30 |
| Fase 6 | Costos y Costeos | 8-10 | 20-25 |
| Fase 7 | Inventarios y Movimientos | 10-12 | 25-30 |
| Fase 8 | Ventas y Exportacion | 8-10 | 20-25 |
| Fase 9 | Servicios y Solicitudes | 6-8 | 15-20 |
| Fase 10 | Resumenes y Reportes | 6-8 | 15-20 |
| Fase 11 | Firmas y Funcionalidad avanzada | 5-7 | 10-15 |

Las horas de Swift son menores porque las pantallas ya existen; solo se modificarian para leer/escribir del servidor en vez del telefono. Con React Native se construyen todas desde cero.

---

### Detalle de cada fase futura

**Fase 3 — Catalogos (15-20 hrs Swift / 40-50 hrs React Native)**

Conectar todos los catalogos del sistema al servidor para que se compartan entre usuarios de la misma empresa. Incluye:

- **Agentes:** Lista, crear, editar y eliminar agentes de venta
- **Clientes:** Lista, crear, editar y eliminar clientes con sus datos de contacto
- **Proveedores:** Lista, crear, editar y eliminar proveedores
- **Articulos:** Catalogo de productos con sus propiedades (talla, color, modelo)
- **Colores, Tallas, Modelos, Marcas, Lineas:** Catalogos auxiliares que se usan al crear articulos
- **Telas y Tipos de Tela:** Catalogo de materiales con precios
- **Departamentos y Unidades:** Clasificaciones internas de la empresa
- **Maquileros:** Talleres externos que procesan produccion

Cada catalogo tendra busqueda, filtrado por empresa y validaciones.

**Fase 4 — Ordenes y Compras (12-15 hrs Swift / 30-40 hrs React Native)**

El flujo completo de ordenes de clientes y compras de insumos. Incluye:

- **Ordenes de clientes:** Crear orden con detalle de articulos, cantidades, precios y fechas de entrega
- **Detalle de orden:** Desglose por articulo, color, talla y cantidad
- **Seguimiento de estado:** Pendiente, en proceso, completada, cancelada
- **Compras de insumos:** Registro de compras a proveedores con detalle de materiales
- **Compras de clientes:** Registro de compras especiales por pedido de cliente
- **Edicion y movimientos:** Modificar ordenes existentes, registrar cambios

**Fase 5 — Produccion y Recibos (10-12 hrs Swift / 25-30 hrs React Native)**

Control de la produccion enviada a maquileros y recepcion de producto terminado. Incluye:

- **Registro de produccion:** Envio de material a maquileros con detalle de articulos y cantidades
- **Recibos de produccion:** Registro de lo que regresa del maquilero (cantidades recibidas vs enviadas)
- **Recibos de compras:** Registro de recepcion de insumos comprados a proveedores
- **Pagos:** Registro de pagos a maquileros y proveedores
- **Vista de detalle:** Consulta del estado de cada lote de produccion

**Fase 6 — Costos y Costeos (8-10 hrs Swift / 20-25 hrs React Native)**

Calculo de costos de produccion. Solo visible para administradores. Incluye:

- **Costos generales:** Registro de costos por articulo (insumos, telas, mano de obra)
- **Costos de mezclilla:** Calculo especializado para productos de mezclilla con sus variables propias
- **Costeos:** Historial de costeos realizados, comparacion entre versiones
- **Detalle de insumos y telas:** Desglose de cada componente del costo

**Fase 7 — Inventarios y Movimientos (10-12 hrs Swift / 25-30 hrs React Native)**

Control de existencias y movimientos de mercancia. Incluye:

- **Vista de inventarios:** Existencias actuales por articulo, color y talla
- **Salidas de insumos:** Registro de material que sale del almacen (a produccion o venta)
- **Reingresos:** Registro de mercancia que regresa al almacen (devoluciones, sobrantes)
- **Movimientos:** Historial de entradas y salidas con fecha, motivo y responsable
- **Detalle por articulo:** Consulta de movimientos de un articulo especifico

**Fase 8 — Ventas y Exportacion (8-10 hrs Swift / 20-25 hrs React Native)**

Registro de ventas y generacion de documentos. Solo visible para administradores. Incluye:

- **Ventas a clientes:** Registro de venta con detalle de articulos, cantidades y precios
- **Detalle de venta:** Desglose por articulo, color, talla
- **Exportacion a PDF:** Generacion de documentos de venta en formato PDF
- **Exportacion a Excel:** Generacion de reportes en formato Excel para analisis
- **Movimientos de venta:** Historial de cambios en cada venta

**Fase 9 — Servicios y Solicitudes (6-8 hrs Swift / 15-20 hrs React Native)**

Gestion de servicios externos. Solo visible para administradores. Incluye:

- **Catalogo de servicios:** Lista de servicios disponibles (lavado, bordado, estampado, etc.)
- **Solicitudes de servicio:** Crear solicitud con detalle de lo que se necesita
- **Recibos de servicio:** Registro de recepcion del servicio completado
- **Seguimiento:** Estado de cada solicitud (pendiente, en proceso, completada)

**Fase 10 — Resumenes y Reportes (6-8 hrs Swift / 15-20 hrs React Native)**

Vistas consolidadas de informacion. Solo visible para superadministradores. Incluye:

- **Resumen de produccion:** Vista general de toda la produccion (enviada, recibida, pendiente)
- **Resumen por cliente:** Ordenes, compras y ventas de cada cliente
- **Resumen por maquilero:** Produccion enviada y recibida de cada maquilero
- **Resumen de compras:** Detalle de compras y pagos a proveedores

**Fase 11 — Firmas digitales y Funcionalidad avanzada (5-7 hrs Swift / 10-15 hrs React Native)**

Funciones adicionales para completar el sistema. Incluye:

- **Firmas digitales:** Captura de firma en pantalla para recibos de produccion (confirmacion de entrega/recepcion)
- **Formatos de seguridad:** Configuraciones de acceso y permisos adicionales
- **Ajustes finales:** Optimizacion, manejo de errores y pulido general de la app

---

## 7. Resumen de Horas (solo Fases 1 y 2)

| | Opcion A: Swift (solo iPhone) | Opcion B: React Native (iPhone + Android) |
|--|-------------------------------|------------------------------------------|
| Fase 1 — Login, Usuarios y Roles | 20 hrs | 32 hrs |
| Fase 2 — Migracion de datos al servidor | 22 hrs | 22 hrs |
| **Total** | **42 hrs** | **54 hrs** |

Las fases futuras (3-11) se estimaran a detalle una vez completadas las primeras dos fases y no estan incluidas en este total.

---

## 8. Supuestos y Consideraciones

1. Se cuenta con acceso al proyecto de Supabase (URL y clave ya disponibles).
2. Las tablas existentes (perfiles, empresas, Usuarios) se mantienen sin cambios.
3. La autenticacion con Supabase Auth ya esta configurada.
4. La Fase 2 es obligatoria para que funcione el modelo de datos compartidos por empresa.
5. empresa_id es la llave de todo el sistema: cada tabla debe tener este campo para filtrar por empresa.
6. Las politicas de seguridad garantizan que la Empresa A nunca vea datos de la Empresa B.
7. Hoy los datos viven solo en cada telefono. Para compartirlos, todo debe moverse al servidor.

### Si eligen Opcion A (Swift):
8. Se necesita Mac con Xcode instalado para compilar y probar.
9. La app solo estara disponible para iPhone/iPad.

### Si eligen Opcion B (React Native):
10. La app se puede probar en dispositivos fisicos con Expo Go (escanear QR).
11. Funciona en iPhone Y Android con el mismo codigo.

---

## 9. Tecnologias

### Opcion A: Swift

| Componente | Tecnologia |
|-----------|-----------|
| App movil | SwiftUI (codigo existente) |
| Backend | Supabase (ya existente) |
| Autenticacion | Supabase Auth |
| Base de datos | PostgreSQL via Supabase |
| Almacenamiento local | Se reemplaza SwiftData por llamadas a Supabase |
| Idioma | Espanol (Mexico) |

### Opcion B: React Native

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
