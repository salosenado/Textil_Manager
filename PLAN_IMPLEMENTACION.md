# Plan de Implementacion — App Textil

## 1. Introduccion

Textil es un sistema de gestion multi-tenant para empresas textiles. Se construira una app movil en React Native que funciona en iPhone y Android, conectada a Supabase como servidor central.

El sistema permite que multiples empresas usen la misma app, cada una viendo unicamente su propia informacion. Un usuario root tiene control total del sistema y puede dar acceso a nuevas empresas y usuarios.

El codigo Swift existente se conserva como referencia en la carpeta `legacy/`.

---

## 2. Objetivo

1. **Multi-tenant**: multiples empresas en una sola app, cada una con sus datos aislados
2. **Usuario root**: control total del sistema, crea empresas y aprueba usuarios
3. **Roles personalizables**: cada empresa puede crear sus propios roles basados en un listado de permisos
4. **Login con email y contrasena** vinculado a una empresa
5. **Datos compartidos**: todos los usuarios de la misma empresa ven la misma informacion
6. **Separacion total**: la Empresa A nunca ve datos de la Empresa B
7. **Compatibilidad**: funciona en iPhone y Android con el mismo codigo

---

## 3. Situacion Actual

### Codigo de referencia (carpeta legacy/)

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Lineas de codigo | ~25,190 |
| Modelos de datos | 47 (locales) + 3 (servidor) |
| Vistas (pantallas) | 94 |
| Servicios / Helpers | 15 |

Este codigo sirve como referencia para entender la logica de negocio y las pantallas que se deben construir.

### Donde se guardan los datos hoy

La gran mayoria de los datos del negocio se guardan **localmente en cada telefono**, no en el servidor.

**En el servidor (Supabase) — solo 3 tablas:**

| Tabla | Uso |
|-------|-----|
| perfiles | Datos del usuario (nombre, email, rol, empresa, aprobado, activo) |
| empresas | Catalogo de empresas |
| Usuarios | Referencia de usuarios |

**En el telefono — 47 modelos que NO se comparten:**

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

### Que existe y que falta

| Elemento | Estado |
|----------|--------|
| Codigo de referencia (Swift) | Disponible en carpeta legacy/ |
| Supabase (Backend) | Parcial, solo autenticacion y perfiles |
| Tablas de negocio en servidor | No existen, se crearan todas desde el inicio |
| Sistema multi-tenant | No existe, se debe construir |
| Roles y permisos personalizables | No existe, se debe construir |
| App React Native | No existe, se construira desde cero |

---

## 4. Arquitectura Multi-Tenant

### Como funciona

- Cada tabla del sistema tiene un campo **empresa_id**
- Cuando un usuario consulta datos, el sistema automaticamente filtra por su empresa
- Las politicas de seguridad en el servidor garantizan que una empresa nunca vea datos de otra
- El usuario root es la unica excepcion: puede ver y administrar todas las empresas

### Jerarquia de acceso

| Nivel | Alcance | Quien lo usa |
|-------|---------|-------------|
| **Root** | Todo el sistema, todas las empresas | Administrador general del sistema |
| **Roles de empresa** | Solo datos de su empresa | Empleados de cada empresa |

### Usuario Root

El root es un usuario especial que existe por encima de cualquier empresa. Puede:

- Ver informacion de **todas** las empresas
- Crear y activar/desactivar empresas
- Aprobar o rechazar nuevos usuarios
- Asignar usuarios a empresas
- Ver reportes globales del sistema

### Roles y Permisos Personalizables

Cada empresa puede crear sus propios roles de acuerdo a sus necesidades. El sistema funciona asi:

1. Existe un **listado maestro de permisos** (uno por cada accion del sistema)
2. El administrador de cada empresa puede **crear roles** y asignarles los permisos que quiera
3. Luego **asigna un rol a cada usuario** de su empresa
4. La app muestra u oculta modulos y acciones segun los permisos del rol asignado

**Listado de permisos del sistema:**

| Modulo | Permisos disponibles |
|--------|---------------------|
| Catalogos | ver_catalogos, crear_catalogos, editar_catalogos, eliminar_catalogos |
| Ordenes | ver_ordenes, crear_ordenes, editar_ordenes, eliminar_ordenes |
| Compras | ver_compras, crear_compras, editar_compras, eliminar_compras |
| Produccion | ver_produccion, crear_produccion, editar_produccion |
| Recibos | ver_recibos, crear_recibos, editar_recibos |
| Costos | ver_costos, crear_costos, editar_costos |
| Inventarios | ver_inventarios, crear_movimientos |
| Ventas | ver_ventas, crear_ventas, editar_ventas |
| Salidas | ver_salidas, crear_salidas |
| Reingresos | ver_reingresos, crear_reingresos |
| Servicios | ver_servicios, crear_servicios, editar_servicios |
| Reportes | ver_reportes |
| Usuarios | ver_usuarios, crear_usuarios, editar_usuarios, gestionar_roles |

**Ejemplo:** Una empresa podria crear un rol "Vendedor" que solo tenga los permisos `ver_catalogos`, `ver_ordenes`, `crear_ordenes` y `ver_ventas`. Otro rol "Jefe de Produccion" podria tener `ver_catalogos`, `ver_produccion`, `crear_produccion`, `ver_recibos` y `crear_recibos`.

### Flujo de autenticacion

1. El usuario abre la app y se verifica si hay sesion guardada
2. Si no hay sesion, se muestra pantalla de Login (email + contrasena)
3. Se autentica contra Supabase Auth
4. Se carga el perfil del usuario con su empresa y rol
5. Si es root, se muestra panel de administracion global
6. Si es usuario de empresa:
   - Se verifica si esta activo y aprobado
   - Si esta desactivado → pantalla de usuario bloqueado
   - Si no esta aprobado → pantalla de pendiente
   - Si todo esta bien → se cargan sus permisos y se muestra la app filtrada

### Modulos del sistema

1. **Catalogos** — Agentes, Clientes, Empresas, Proveedores, Articulos, Colores, Departamentos, Lineas, Marcas, Modelos, Tallas, Telas, Unidades, Maquileros, Servicios
2. **Ordenes y Compras** — Ordenes de clientes, Compras de clientes, Compras de insumos
3. **Produccion** — Produccion, Recibos de produccion
4. **Costos** — Costos Generales, Costos Mezclilla, Costeos
5. **Inventarios** — Vista de inventarios, Movimientos
6. **Ventas y Movimientos** — Ventas, Salidas de insumos, Reingresos
7. **Servicios** — Solicitudes, Recibos de servicio
8. **Reportes** — Resumen de produccion, Resumen de compras, Resumen por cliente, Resumen por maquilero
9. **Administracion de Empresa** — Usuarios, Roles y Permisos, Perfil
10. **Panel Root** — Gestion de empresas, Aprobacion de usuarios, Reportes globales

---

## 5. Plan de Proyecto

### Fase 1 — Base del Sistema: Tablas, Auth, Roles y Multi-Tenant (40 horas)

Se construye toda la base del sistema de una sola vez: las tablas en el servidor, la autenticacion, el sistema de roles/permisos y la estructura multi-tenant.

| # | Entregable | Horas |
|---|-----------|-------|
| E1 | Configuracion del proyecto (React Native/Expo, Supabase, navegacion) | 2 |
| E2 | Diseno y creacion de todas las tablas en Supabase (~50 tablas con empresa_id) | 8 |
| E3 | Politicas de seguridad multi-tenant (cada empresa solo ve sus datos) | 4 |
| E4 | Tablas de roles y permisos (roles, permisos, rol_permisos) | 3 |
| E5 | Pantalla de Login (email + contrasena, validaciones, errores en espanol) | 3 |
| E6 | Sistema de autenticacion (sesion, perfil, empresa_id, carga de permisos) | 4 |
| E7 | Pantallas de estado (usuario bloqueado y pendiente de aprobacion) | 2 |
| E8 | Navegacion principal con filtrado dinamico por permisos | 4 |
| E9 | Pantalla de Perfil (datos del usuario, cerrar sesion) | 2 |
| E10 | Gestion de Usuarios de empresa (lista, aprobar, activar, asignar rol) | 4 |
| E11 | Gestion de Roles de empresa (crear rol, asignar permisos, eliminar rol) | 4 |
| | **Total Fase 1** | **40** |

---

### Fase 2 — Panel Root (12 horas)

Pantallas exclusivas para el usuario root que administra todo el sistema.

| # | Entregable | Horas |
|---|-----------|-------|
| E12 | Panel principal root (vista global de empresas y usuarios) | 3 |
| E13 | Gestion de empresas (crear, activar/desactivar, ver detalle) | 3 |
| E14 | Aprobacion de usuarios nuevos (aprobar, rechazar, asignar empresa) | 3 |
| E15 | Reportes globales (resumen de todas las empresas) | 3 |
| | **Total Fase 2** | **12** |

---

### Fase 3 — Catalogos (40-50 horas)

Construir todas las pantallas de catalogos conectadas al servidor. Incluye:

- **Agentes:** Lista, crear, editar y eliminar agentes de venta
- **Clientes:** Lista, crear, editar y eliminar clientes con sus datos de contacto
- **Proveedores:** Lista, crear, editar y eliminar proveedores
- **Articulos:** Catalogo de productos con sus propiedades (talla, color, modelo)
- **Colores, Tallas, Modelos, Marcas, Lineas:** Catalogos auxiliares que se usan al crear articulos
- **Telas y Tipos de Tela:** Catalogo de materiales con precios
- **Departamentos y Unidades:** Clasificaciones internas de la empresa
- **Maquileros:** Talleres externos que procesan produccion

Cada catalogo tendra busqueda, filtrado por empresa y validaciones.

---

### Fase 4 — Ordenes y Compras (30-40 horas)

El flujo completo de ordenes de clientes y compras de insumos. Incluye:

- **Ordenes de clientes:** Crear orden con detalle de articulos, cantidades, precios y fechas de entrega
- **Detalle de orden:** Desglose por articulo, color, talla y cantidad
- **Seguimiento de estado:** Pendiente, en proceso, completada, cancelada
- **Compras de insumos:** Registro de compras a proveedores con detalle de materiales
- **Compras de clientes:** Registro de compras especiales por pedido de cliente
- **Edicion y movimientos:** Modificar ordenes existentes, registrar cambios

---

### Fase 5 — Produccion y Recibos (25-30 horas)

Control de la produccion enviada a maquileros y recepcion de producto terminado. Incluye:

- **Registro de produccion:** Envio de material a maquileros con detalle de articulos y cantidades
- **Recibos de produccion:** Registro de lo que regresa del maquilero (cantidades recibidas vs enviadas)
- **Recibos de compras:** Registro de recepcion de insumos comprados a proveedores
- **Pagos:** Registro de pagos a maquileros y proveedores
- **Vista de detalle:** Consulta del estado de cada lote de produccion

---

### Fase 6 — Costos y Costeos (20-25 horas)

Calculo de costos de produccion. Requiere permiso `ver_costos`. Incluye:

- **Costos generales:** Registro de costos por articulo (insumos, telas, mano de obra)
- **Costos de mezclilla:** Calculo especializado para productos de mezclilla con sus variables propias
- **Costeos:** Historial de costeos realizados, comparacion entre versiones
- **Detalle de insumos y telas:** Desglose de cada componente del costo

---

### Fase 7 — Inventarios y Movimientos (25-30 horas)

Control de existencias y movimientos de mercancia. Incluye:

- **Vista de inventarios:** Existencias actuales por articulo, color y talla
- **Salidas de insumos:** Registro de material que sale del almacen (a produccion o venta)
- **Reingresos:** Registro de mercancia que regresa al almacen (devoluciones, sobrantes)
- **Movimientos:** Historial de entradas y salidas con fecha, motivo y responsable
- **Detalle por articulo:** Consulta de movimientos de un articulo especifico

---

### Fase 8 — Ventas y Exportacion (20-25 horas)

Registro de ventas y generacion de documentos. Requiere permiso `ver_ventas`. Incluye:

- **Ventas a clientes:** Registro de venta con detalle de articulos, cantidades y precios
- **Detalle de venta:** Desglose por articulo, color, talla
- **Exportacion a PDF:** Generacion de documentos de venta en formato PDF
- **Exportacion a Excel:** Generacion de reportes en formato Excel para analisis
- **Movimientos de venta:** Historial de cambios en cada venta

---

### Fase 9 — Servicios y Solicitudes (15-20 horas)

Gestion de servicios externos. Requiere permiso `ver_servicios`. Incluye:

- **Catalogo de servicios:** Lista de servicios disponibles (lavado, bordado, estampado, etc.)
- **Solicitudes de servicio:** Crear solicitud con detalle de lo que se necesita
- **Recibos de servicio:** Registro de recepcion del servicio completado
- **Seguimiento:** Estado de cada solicitud (pendiente, en proceso, completada)

---

### Fase 10 — Reportes (15-20 horas)

Vistas consolidadas de informacion. Requiere permiso `ver_reportes`. Incluye:

- **Resumen de produccion:** Vista general de toda la produccion (enviada, recibida, pendiente)
- **Resumen por cliente:** Ordenes, compras y ventas de cada cliente
- **Resumen por maquilero:** Produccion enviada y recibida de cada maquilero
- **Resumen de compras:** Detalle de compras y pagos a proveedores

---

### Fase 11 — Firmas digitales y Funcionalidad avanzada (10-15 horas)

Funciones adicionales para completar el sistema. Incluye:

- **Firmas digitales:** Captura de firma en pantalla para recibos de produccion (confirmacion de entrega/recepcion)
- **Ajustes finales:** Optimizacion, manejo de errores y pulido general de la app

---

## 6. Resumen de Horas

| Fase | Descripcion | Horas estimadas |
|------|-------------|----------------|
| Fase 1 | Base del sistema (tablas, auth, roles, multi-tenant) | 40 |
| Fase 2 | Panel Root | 12 |
| Fase 3 | Catalogos | 40-50 |
| Fase 4 | Ordenes y Compras | 30-40 |
| Fase 5 | Produccion y Recibos | 25-30 |
| Fase 6 | Costos y Costeos | 20-25 |
| Fase 7 | Inventarios y Movimientos | 25-30 |
| Fase 8 | Ventas y Exportacion | 20-25 |
| Fase 9 | Servicios y Solicitudes | 15-20 |
| Fase 10 | Reportes | 15-20 |
| Fase 11 | Firmas y Funcionalidad avanzada | 10-15 |
| | | |
| **Total Fases 1-2** | **Fundamentos del sistema** | **52 hrs** |
| **Total Fases 3-11** | **Modulos del negocio** | **200-255 hrs** |
| **Total General** | **Todo el proyecto** | **252-307 hrs** |

---

## 7. Supuestos y Consideraciones

1. Se cuenta con acceso al proyecto de Supabase (URL y clave ya disponibles).
2. Las tablas existentes (perfiles, empresas, Usuarios) se mantienen y se adaptan al nuevo esquema.
3. La autenticacion con Supabase Auth ya esta configurada.
4. **Todas las tablas se crean desde la Fase 1**, no se espera a fases posteriores.
5. **empresa_id** es la llave de todo el sistema: cada tabla tiene este campo para filtrar por empresa.
6. Las politicas de seguridad garantizan que la Empresa A nunca vea datos de la Empresa B.
7. El **usuario root** existe por encima de las empresas y tiene acceso total al sistema.
8. Cada empresa puede **crear sus propios roles** y asignar permisos segun sus necesidades.
9. Los permisos controlan que ve y que puede hacer cada usuario dentro de su empresa.
10. La app se puede probar en dispositivos fisicos con Expo Go (escanear QR).
11. Funciona en iPhone y Android con el mismo codigo.
12. El codigo Swift existente se conserva como referencia en la carpeta legacy/.

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
| Plataformas | iPhone + Android |
