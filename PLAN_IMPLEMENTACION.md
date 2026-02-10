# DESARROLLO DE APP MOVIL TEXTIL
# CON GESTION MULTIEMPRESA

## TEXTIL

### Febrero 2026

---

## Tabla de Contenidos

| Sección | Página |
|---------|--------|
| CONTROL DE CAMBIOS | 1 |
| 1. INTRODUCCION | 2 |
| 2. OBJETIVO | 2 |
| 3. AUDIENCIAS | 2 |
| 4. SITUACION ACTUAL | 3 |
| 5. ALCANCE | 5 |
| 6. PLAN DE PROYECTO | 8 |
| 7. INVERSION ECONOMICA | 11 |
| 8. SUPUESTOS Y CONSIDERACIONES | 12 |
| 9. ANEXOS | 13 |

---

## Control de Cambios

| Version | Fecha | Autor | Detalle |
|---------|-------|-------|---------|
| 1.0.0 | 09/Febrero/2026 | Replit Agent | Creacion de documento |
| 2.0.0 | 10/Febrero/2026 | Replit Agent | Analisis de almacenamiento de datos y hallazgos |

---

## 1. Introduccion

Como parte del proceso de modernizacion de la aplicacion Textil, se preparo la siguiente propuesta que atiende la solicitud de desarrollo de una **App Movil Multiplataforma** (iOS y Android) con gestion centralizada de datos por empresa.

Actualmente existe un codigo fuente en SwiftUI (solo ejecutable en Xcode/macOS) que sirve como referencia de diseno y logica. El objetivo es construir desde cero una aplicacion movil en **React Native / Expo** que se conecte al backend de **Supabase** (ya existente) para centralizar toda la informacion, permitir el acceso compartido por empresa y controlar los permisos mediante roles de usuario.

Este documento describe el alcance completo de la solucion, la situacion actual del sistema, la estimacion del esfuerzo requerido y el plan de proyecto propuesto.

---

## 2. Objetivo

El documento tiene la finalidad de describir el alcance de la solucion que resolvera los siguientes requerimientos:

1. **Acceso mediante credenciales**: Login con email y contrasena vinculado a una empresa
2. **Datos compartidos por empresa**: Todos los usuarios de la misma empresa ven la misma informacion
3. **Separacion entre empresas**: Si un usuario cambia de empresa, ve informacion diferente
4. **Control por roles**: No todos los empleados pueden ver la misma informacion segun su rol

Asi como la estimacion del esfuerzo requerido para llevar a cabo la propuesta de valor.

---

## 3. Audiencias

- Lideres funcionales del negocio textil
- Administradores del sistema
- Usuarios finales de la aplicacion
- Equipo de desarrollo

---

## 4. Situacion Actual

### 4.1 Analisis del Codigo de Referencia

Se analizo el codigo fuente original en SwiftUI con los siguientes resultados:

| Concepto | Detalle |
|----------|---------|
| Archivos Swift | 176 |
| Lineas de codigo | ~25,190 |
| Modelos de datos | 47 (locales) + 3 (servidor) |
| Vistas (pantallas) | 94 |
| Servicios / Helpers | 15 |

### 4.2 Hallazgo Critico: Almacenamiento de Datos

Al revisar el codigo original, se encontro que la gran mayoria de los datos del negocio se guardan **localmente en cada telefono** y NO en el servidor. A continuacion el detalle:

#### Datos en el Servidor (Supabase) — Compartidos

Solo **3 tablas** estan en el servidor y se comparten entre usuarios:

| Tabla | Uso |
|-------|-----|
| perfiles | Datos del usuario (nombre, email, rol, empresa, aprobado, activo) |
| empresas | Catalogo de empresas |
| Usuarios | Referencia de usuarios |

Solo 5 de los 176 archivos se conectan a Supabase: SuperbaseClient, AuthViewModel, LoginView, PerfilViewModel, UsuariosAdminView.

#### Datos en el Telefono (SwiftData) — NO Compartidos

Los otros **47 modelos** de datos se guardan localmente en cada telefono:

| Categoria | Modelos almacenados solo en el telefono |
|-----------|----------------------------------------|
| Catalogos | Agente, Cliente, Empresa (local), Proveedor, Articulo, Color, Modelo, Talla, Tela, PrecioTela, Departamento, Linea, Marca, Unidad, Maquilero, Servicio, TipoTela |
| Ordenes | OrdenCliente, OrdenClienteDetalle, OrdenCompra, OrdenCompraDetalle |
| Compras | CompraCliente, CompraClienteDetalle |
| Produccion | Produccion, ReciboProduccion, ProduccionFirma |
| Recibos | ReciboCompra, ReciboCompraPago, ReciboCompraDetalle, PagoRecibo |
| Ventas | VentaCliente, VentaClienteDetalle |
| Salidas | SalidaInsumo, SalidaInsumoDetalle |
| Reingresos | Reingreso, ReingresoDetalle, ReingresoMovimiento |
| Costos | CostoMezclillaEntity, CostoGeneralEntity |

### 4.3 Implicaciones

La informacion **NO se comparte entre usuarios ni entre dispositivos**. Si el usuario A crea un cliente en su telefono, el usuario B nunca lo vera. Cada telefono tiene su propia base de datos aislada.

Algunos modelos como VentaCliente, SalidaInsumo y Reingreso tienen un campo "empresa" como texto, pero es solo una referencia local, no filtra datos desde un servidor.

### 4.4 Estado Actual Resumido

| Elemento | Estado | Descripcion |
|----------|--------|-------------|
| Codigo Swift (SwiftUI) | Solo referencia | 176 archivos. No se pueden ejecutar en este entorno. |
| Supabase (Backend) | Parcial | Solo autenticacion y perfiles funcionando. |
| Tablas de negocio en Supabase | No existen | Clientes, ordenes, produccion, ventas, etc. solo estan en cada telefono. |
| App movil React Native | No existe | Es lo que se va a construir. |
| Login funcional en la app | No existe | Se construira en Fase 1. |
| Datos compartidos por empresa | No existe | Se construira en Fase 2. |

### 4.5 Tablas Existentes en Supabase

| Tabla | Campos clave |
|-------|-------------|
| perfiles | id (uuid, FK auth), empresa_id (uuid), nombre, email, rol, aprobado (bool), activo (bool), created_at |
| empresas | id (uuid), nombre, aprobado (bool), activo (bool), created_at |
| Usuarios | id (uuid), created_at, email, nombre, rol, empresa, activo (bool) |

---

## 5. Alcance

### 5.1 Generalidades de la Solucion

Se construira desde cero una aplicacion movil multiplataforma (iOS y Android) utilizando React Native / Expo, conectada al backend de Supabase existente. La solucion contempla:

1. **Sistema de autenticacion**: Login con email y contrasena, verificacion de sesion, estados de usuario (activo, bloqueado, pendiente)
2. **Gestion centralizada de datos**: Migracion de los 47 modelos locales a tablas en Supabase con campo empresa_id para filtrado por empresa
3. **Control de acceso por roles**: Filtrado de modulos y funcionalidades segun el rol del usuario (usuario regular, admin, superadmin)
4. **Seguridad a nivel de base de datos**: Politicas de seguridad (RLS) para garantizar que cada empresa solo acceda a sus propios datos

### 5.2 Flujo de Autenticacion

1. El usuario abre la app y se verifica si hay sesion guardada
2. Si no hay sesion, se muestra pantalla de Login (email + contrasena)
3. Se autentica contra Supabase Auth
4. Se carga el perfil del usuario desde la tabla perfiles (con datos de su empresa)
5. La empresa_id del perfil determina que datos ve el usuario
6. Si activo == false, se muestra pantalla de usuario bloqueado
7. Si aprobado == false, se muestra pantalla de pendiente de aprobacion
8. Si todo esta correcto, se muestra la app principal con modulos filtrados segun su rol
9. Todos los datos se filtran automaticamente por la empresa_id del usuario logueado

### 5.3 Sistema de Roles

| Rol | Acceso |
|-----|--------|
| Usuario regular | Catalogos, Produccion, Recibos, Ordenes, Compras, Inventarios, Perfil |
| Admin | Todo lo anterior + Costos, Costeos, Mezclilla, Servicios, Ventas, Salidas, Reingresos |
| Superadmin | Todo lo anterior + Gestion de Usuarios, Gestion de Roles, Resumenes |

### 5.4 Modulos del Sistema Completo

#### Modulo 1: Catalogos Comerciales
Agentes, Clientes, Empresas, Proveedores (cada uno con lista + formulario)

#### Modulo 2: Catalogos de Articulos
Articulos, Colores, Departamentos, Lineas, Marcas, Modelos, Tallas, Telas, Unidades

#### Modulo 3: Costos (solo admin+)
Costos Generales, Costos Mezclilla, Costeos

#### Modulo 4: Produccion
Produccion (lista, detalle, firma digital), Recibos de produccion

#### Modulo 5: Ordenes y Compras
Ordenes de clientes, Compras de clientes, Compras de insumos

#### Modulo 6: Servicios (solo admin+)
Solicitudes de servicios, Recibos de compras/servicios

#### Modulo 7: Inventarios
Vista de inventarios, Movimientos

#### Modulo 8: Ventas y Movimientos (solo admin+)
Ventas a clientes, Salidas de insumos, Reingresos (con PDF y Excel)

#### Modulo 9: Usuarios y Seguridad (solo superadmin)
Administracion de usuarios, Perfil, Seguridad

#### Modulo 10: Resumenes (solo superadmin)
Resumen de produccion, Resumen de compras

### 5.5 Componentes a Desarrollar

La arquitectura propuesta esta basada en el analisis del codigo de referencia y los requerimientos del negocio. Se consideran los siguientes componentes:

1. **App Movil React Native / Expo**: Aplicacion multiplataforma que funcionara en iOS y Android. Incluye todas las pantallas, navegacion y logica de presentacion.

2. **Capa de Autenticacion**: Sistema completo de login, verificacion de sesion, manejo de estados del usuario (bloqueado, pendiente, activo) y control de roles.

3. **Migracion de Base de Datos**: Creacion de las ~47 tablas en Supabase que hoy son locales, con el campo empresa_id en cada una para habilitar el filtrado por empresa.

4. **Politicas de Seguridad (RLS)**: Configuracion de Row Level Security en cada tabla de Supabase para garantizar que un usuario de la Empresa A nunca vea datos de la Empresa B.

5. **Capa de Servicios de Datos**: Funciones reutilizables para leer y escribir datos desde la app hacia Supabase, con filtrado automatico por empresa_id.

---

## 6. Plan de Proyecto

### 6.1 Fase 1 — Login, Usuarios y Roles

Todo se construye desde cero. El codigo Swift solo se usa como referencia de la logica.

#### E1. Configuracion del Proyecto — 2 horas
- Crear proyecto React Native / Expo desde cero
- Instalar dependencias (Supabase JS, React Navigation, AsyncStorage)
- Definir estructura de carpetas
- Configurar conexion a Supabase existente

#### E2. Pantalla de Login — 3 horas
- Construir pantalla de inicio de sesion con campos de email y contrasena
- Validaciones (campos vacios, formato de email)
- Manejo de errores en espanol
- Indicador de carga durante autenticacion
- Diseno oscuro coherente con la identidad de la app

#### E3. Contexto de Autenticacion — 4 horas
- Crear sistema central que maneje toda la logica de sesion
- Verificacion automatica de sesion al abrir la app
- Carga de perfil desde perfiles con datos de empresas
- Obtener la empresa_id del usuario para filtrar datos en fases futuras
- Evaluacion de estados: bloqueado, pendiente, activo
- Funciones para determinar el rol: esAdmin, esSuperAdmin
- Guardar sesion en el dispositivo
- Funcion de cierre de sesion

#### E4. Pantallas de Estado de Usuario — 2 horas
- Pantalla "Usuario Bloqueado": Icono, mensaje descriptivo, boton de cerrar sesion
- Pantalla "Pendiente de Aprobacion": Icono, mensaje, boton "Verificar estado", boton de cerrar sesion

#### E5. Navegacion Principal con Filtrado por Rol — 4 horas
- Sistema de navegacion entre pantallas
- Pestanas en la parte inferior filtradas segun el rol del usuario
- Pantalla de carga mientras se verifica la sesion

#### E6. Pantalla de Perfil — 2 horas
- Mostrar datos del usuario: nombre, email, rol, empresa, estado
- Boton de cerrar sesion
- Diseno con tarjeta informativa

#### E7. Gestion de Usuarios (solo superadmin) — 6 horas
- Lista de todos los usuarios desde tabla perfiles
- Para cada usuario mostrar: nombre/email, rol, empresa
- Controles para aprobar/rechazar, activar/desactivar y cambiar rol
- Busqueda/filtrado de usuarios
- Confirmacion antes de cambios criticos
- Recarga automatica despues de cada cambio

#### E8. Gestion de Roles (solo superadmin) — 4 horas
- Vista de los roles disponibles y sus permisos
- Descripcion clara de que acceso tiene cada rol
- Visualizacion de cuantos usuarios tiene cada rol
- Posibilidad de asignar roles desde esta vista

#### E9. Pruebas y Ajustes — 4 horas
- Pruebas de flujo completo de login
- Pruebas de bloqueo/aprobacion de usuarios
- Pruebas de cambio de roles
- Verificacion de filtrado de pestanas por rol
- Correccion de errores encontrados
- Ajustes de diseno y usabilidad

#### E10. Documentacion — 1 hora
- Documentacion tecnica del proyecto actualizada
- Instrucciones de configuracion
- Documentacion de la estructura de carpetas

### Cronograma Fase 1

| Semana | Actividades |
|--------|-------------|
| Semana 1 | E1 Configuracion + E2 Login + E3 Autenticacion |
| Semana 2 | E4 Pantallas de estado + E5 Navegacion + E6 Perfil |
| Semana 3 | E7 Gestion de usuarios + E8 Gestion de roles |
| Semana 4 | E9 Pruebas y ajustes + E10 Documentacion |

---

### 6.2 Fase 2 — Migracion de Datos al Servidor

Esta fase es necesaria para lograr que todos los usuarios de la misma empresa vean la misma informacion.

#### E11. Diseno de Tablas en Supabase — 6 horas
- Disenar las ~47 tablas que hoy son locales
- Agregar campo empresa_id a cada tabla
- Definir relaciones entre tablas (foreign keys)
- Documentar el esquema completo

#### E12. Creacion de Tablas en Supabase — 4 horas
- Ejecutar las migraciones para crear todas las tablas
- Configurar indices para rendimiento
- Verificar integridad referencial

#### E13. Politicas de Seguridad (RLS) — 4 horas
- Configurar Row Level Security en cada tabla
- Regla principal: cada usuario solo ve datos de su empresa_id
- Permisos de escritura segun rol
- Pruebas de seguridad

#### E14. Capa de Datos en la App — 8 horas
- Crear funciones para leer/escribir cada tabla desde la app
- Filtrar automaticamente por empresa_id del usuario logueado
- Manejo de errores y estados de carga

### Cronograma Fase 2

| Semana | Actividades |
|--------|-------------|
| Semana 5 | E11 Diseno de tablas + E12 Creacion de tablas |
| Semana 6 | E13 Politicas de seguridad + E14 Capa de datos |

---

### 6.3 Fases Futuras — Construccion de Pantallas

Una vez que la Fase 2 este lista (datos en servidor), se pueden construir las pantallas de cada modulo:

| Fase | Modulos | Estimacion |
|------|---------|------------|
| Fase 3 | Catalogos completos (Agentes, Clientes, Empresas, Proveedores, Articulos, etc.) | 40-50 hrs |
| Fase 4 | Ordenes de clientes + Compras | 30-40 hrs |
| Fase 5 | Produccion + Recibos | 25-30 hrs |
| Fase 6 | Costos y Costeos | 20-25 hrs |
| Fase 7 | Inventarios + Salidas + Reingresos | 25-30 hrs |
| Fase 8 | Ventas + Generacion de PDF/Excel | 20-25 hrs |
| Fase 9 | Servicios + Solicitudes | 15-20 hrs |
| Fase 10 | Resumenes y Reportes | 15-20 hrs |
| Fase 11 | Firmas digitales + Funcionalidad avanzada | 10-15 hrs |

---

## 7. Inversion Economica

### Resumen de Esfuerzo por Fase

| # | Fase | Descripcion | Horas |
|---|------|-------------|-------|
| 1 | Fase 1 | Login, Usuarios y Roles | 32 |
| 2 | Fase 2 | Migracion de Datos al Servidor | 22 |
| 3 | Fases 3-11 | Pantallas de todos los modulos | 200-255 |
| | | **TOTAL ESTIMADO** | **254-309 hrs** |

### Detalle Fase 1

| # | Entregable | Estado actual | Horas |
|---|-----------|---------------|-------|
| E1 | Configuracion del Proyecto | No existe | 2 |
| E2 | Pantalla de Login | No existe | 3 |
| E3 | Contexto de Autenticacion | No existe | 4 |
| E4 | Pantallas de Estado (Bloqueado/Pendiente) | No existe | 2 |
| E5 | Navegacion con Filtrado por Rol | No existe | 4 |
| E6 | Pantalla de Perfil | No existe | 2 |
| E7 | Gestion de Usuarios | No existe | 6 |
| E8 | Gestion de Roles | No existe | 4 |
| E9 | Pruebas y Ajustes | — | 4 |
| E10 | Documentacion | — | 1 |
| | **TOTAL FASE 1** | | **32 horas** |

### Detalle Fase 2

| # | Entregable | Horas |
|---|-----------|-------|
| E11 | Diseno de Tablas en Supabase | 6 |
| E12 | Creacion de Tablas en Supabase | 4 |
| E13 | Politicas de Seguridad (RLS) | 4 |
| E14 | Capa de Datos en la App | 8 |
| | **TOTAL FASE 2** | **22 horas** |

---

## 8. Supuestos y Consideraciones

### Supuestos

1. Se cuenta con acceso completo al proyecto de Supabase (URL y clave publica ya disponibles en el codigo de referencia).

2. Las tablas existentes en Supabase (perfiles, empresas, Usuarios) se mantendran sin modificaciones en su estructura actual.

3. La autenticacion mediante Supabase Auth ya esta configurada y funcional para registro y login con email/contrasena.

4. Se utilizara el codigo Swift existente unicamente como referencia de diseno y logica de negocio. No se reutilizara codigo directamente.

5. La app se probara en dispositivos fisicos (iPhone/Android) usando Expo Go y escaneando un codigo QR.

### Alcance

1. Los elementos descritos en este documento representan la funcionalidad planificada. Funcionalidades adicionales o desviaciones se estimaran y cotizaran por separado.

2. Los componentes por implementar son los descritos en la seccion "Generalidades de la Solucion".

3. La Fase 1 cubre exclusivamente el sistema de login, autenticacion, gestion de usuarios y roles. Los modulos de negocio (catalogos, ordenes, produccion, ventas, etc.) se desarrollaran en fases posteriores.

4. La Fase 2 es requisito obligatorio para que funcione el modelo de datos compartidos por empresa. Sin esta fase, los datos no podran compartirse entre usuarios.

### Consideraciones Tecnicas

1. **empresa_id es la llave de todo el sistema**. Cada tabla en el servidor debera tener el campo empresa_id para filtrar que empresa ve que informacion.

2. **Las politicas de seguridad (RLS)** en Supabase garantizaran que un usuario de la Empresa A nunca vea datos de la Empresa B.

3. **Hoy los datos viven en cada telefono**. Eso significa que si un usuario crea un cliente, solo el lo ve. Para compartir informacion por empresa, todo debe moverse al servidor (Fase 2).

4. **La base de datos en Supabase necesita ampliarse**. Hoy solo tiene 3 tablas. Se necesitan ~47 tablas mas para los datos de negocio.

---

## 9. Anexos

### 9.1 Tecnologias Propuestas

| Componente | Tecnologia |
|-----------|-----------|
| Framework movil | React Native + Expo |
| Backend | Supabase (ya existente, se amplia) |
| Autenticacion | Supabase Auth (ya configurado) |
| Base de datos | PostgreSQL via Supabase |
| Navegacion | React Navigation (Stack + Tabs) |
| Estado global | React Context API |
| Persistencia local | AsyncStorage (solo sesion) |
| Idioma de la app | Espanol (Mexico) |

### 9.2 Estructura de Carpetas Propuesta

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

### 9.3 Conceptos

| Termino | Descripcion |
|---------|-------------|
| Supabase | Plataforma de backend como servicio que proporciona base de datos PostgreSQL y autenticacion |
| RLS (Row Level Security) | Mecanismo de seguridad a nivel de base de datos que controla que filas puede ver cada usuario |
| empresa_id | Campo identificador que vincula cada registro a una empresa especifica |
| React Native / Expo | Framework para construir aplicaciones moviles multiplataforma (iOS y Android) |
| SwiftData | Sistema de almacenamiento local de Apple utilizado en el codigo de referencia |

### 9.4 Acronimos

| Acronimo | Significado |
|----------|-------------|
| RLS | Row Level Security |
| API | Application Programming Interface |
| UUID | Universally Unique Identifier |
| FK | Foreign Key (llave foranea) |
| Auth | Autenticacion |
| PDF | Portable Document Format |
