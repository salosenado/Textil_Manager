# Textil

## Overview
Sistema multi-tenant para gestión de operaciones de empresas textiles. Se está reconstruyendo en React Native (iOS + Android) con backend Node.js + Express y PostgreSQL. Cada empresa tiene sus datos completamente aislados mediante empresa_id en todas las tablas.

## User Preferences
- Idioma de comunicación: Español (México)
- Idioma de la app: Español
- Estilo: Lenguaje simple y cotidiano
- No mencionar plataforma de desarrollo en documentación
- Autenticación 100% propia (sin proveedores externos como Supabase Auth)

## Project Architecture

### Multi-tenant
- Todas las tablas tienen `empresa_id` para aislamiento de datos
- Usuario root tiene acceso a todo el sistema
- Cada empresa crea sus propios roles con permisos personalizados
- 13 categorías de permisos maestros (25 permisos totales)

### Base de Datos (PostgreSQL)
- ~50 tablas organizadas en 10 archivos de migración
- Migraciones en `migrations/` ordenadas numéricamente
- Función `actualizar_updated_at()` con triggers automáticos
- UUID como primary keys en todas las tablas

### Módulos del Sistema
1. **Base:** empresas, usuarios, roles, permisos
2. **Catálogos:** agentes, clientes, proveedores, departamentos, líneas, marcas, colores, tallas, unidades, modelos, artículos, tipos_tela, telas, precios_tela, maquileros, servicios
3. **Órdenes:** ordenes_cliente, ordenes_compra, compras_insumo (con detalles y movimientos)
4. **Producción:** producciones, recibos_produccion, pagos_recibo
5. **Recibos de Compras:** recibos_compra (con detalles y pagos)
6. **Ventas:** ventas_cliente (con detalles, movimientos, cobros)
7. **Salidas/Reingresos:** salidas_insumo, reingresos (con detalles y movimientos)
8. **Costos:** costos_generales, costos_mezclilla (con telas e insumos)
9. **Financiero:** dispersiones, préstamos, pagos_comision, pagos_regalia, movimientos_banco/caja, facturas
10. **Activos/Impresión:** activos_empresa, registros_impresion, control_diseno_trazo

### Interfaz Web de Carga
- `server.js` - Express server en puerto 5000
- `public/` - Interfaz HTML/CSS/JS para subir catálogos desde CSV/Excel
- Soporta 14 catálogos diferentes
- Incluye vista previa de datos y estadísticas

### Código Legacy (referencia)
- `legacy/` - Código original SwiftUI (176 archivos Swift)
- Se usa como referencia para campos y relaciones

## Key Files
- `PLAN_IMPLEMENTACION.md` - Plan con 11 fases, 124 horas totales
- `migrations/` - 10 archivos SQL con todas las tablas
- `migrations/README.md` - Guía de cómo agregar/modificar migraciones
- `server.js` - Servidor web para carga de catálogos
- `public/` - Frontend de la interfaz de carga
- `legacy/` - Código SwiftUI original (referencia)

## Recent Changes
- 2026-02-16: Creadas 10 migraciones SQL con ~50 tablas
- 2026-02-16: Ejecutadas todas las migraciones en PostgreSQL
- 2026-02-16: Creada interfaz web para carga de catálogos (CSV/Excel)
- 2026-02-16: Fase 11 actualizada con publicación en tiendas
