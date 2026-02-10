# Textil

## Overview
Textil es una aplicación móvil iOS nativa desarrollada en SwiftUI para la gestión de operaciones de una empresa textil. Se conecta a Supabase como backend (autenticación + base de datos PostgreSQL). El proyecto incluye 176 archivos Swift con ~25,190 líneas de código.

Se está planificando la migración a React Native / Expo para poder ejecutar y probar la app en dispositivos iOS y Android.

## User Preferences
- Idioma de comunicación: Español (México)
- Idioma de la app: Español
- Estilo: Lenguaje simple y cotidiano
- No mencionar plataforma de desarrollo en documentación

## Project Architecture

### App Original (SwiftUI) - `Textil/`
- **UI Framework:** SwiftUI + SwiftData
- **Backend:** Supabase (Auth + PostgreSQL)
- **Archivos Swift:** 176 (64 modelos, 94 vistas, 15 servicios/helpers)
- **Roles:** superadmin, admin, usuario regular
- **Proyecto Xcode:** `Textil.xcodeproj`

### Tablas Supabase
- **perfiles:** id, empresa_id, nombre, email, rol, aprobado, activo, created_at
- **empresas:** id, nombre, aprobado, activo, created_at
- **Usuarios:** id, created_at, email, nombre, rol, empresa, activo

### Módulos del Sistema
1. Catálogos (Agentes, Clientes, Empresas, Proveedores, Artículos, Colores, etc.)
2. Costos (General + Mezclilla + Costeos) - solo admin+
3. Producción + Recibos
4. Órdenes de Clientes + Compras
5. Servicios + Solicitudes - solo admin+
6. Inventarios
7. Ventas + Salidas + Reingresos - solo admin+
8. Gestión de Usuarios - solo superadmin
9. Resúmenes - solo superadmin

### Server Actual
- `server.py` - Servidor web simple que muestra resumen del plan de implementación
- Puerto: 5000

## Key Files
- `PLAN_IMPLEMENTACION.md` - Plan detallado con estimaciones en horas para Fase 1 (32 hrs)
- `Textil/` - Código fuente iOS original (SwiftUI)
- `Textil.xcodeproj/` - Proyecto Xcode
- `server.py` - Servidor web informativo
