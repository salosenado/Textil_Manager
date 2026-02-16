-- ============================================================
-- MIGRACIÓN 001: Sistema Base
-- Empresas, Usuarios, Roles y Permisos
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ----------------------------------------------------------
-- EMPRESAS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS empresas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre VARCHAR(255) NOT NULL,
    rfc VARCHAR(20),
    direccion TEXT,
    telefono VARCHAR(50),
    logo_url TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    aprobado BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------
-- USUARIOS (autenticación 100% propia, sin proveedores externos)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID REFERENCES empresas(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255),
    telefono VARCHAR(50),
    es_root BOOLEAN NOT NULL DEFAULT false,
    activo BOOLEAN NOT NULL DEFAULT true,
    aprobado BOOLEAN NOT NULL DEFAULT false,
    ultimo_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_usuarios_empresa ON usuarios(empresa_id);
CREATE INDEX idx_usuarios_email ON usuarios(email);

-- ----------------------------------------------------------
-- PERMISOS MAESTROS (catálogo fijo de permisos del sistema)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS permisos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clave VARCHAR(100) NOT NULL UNIQUE,
    nombre VARCHAR(255) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    descripcion TEXT
);

INSERT INTO permisos (clave, nombre, categoria, descripcion) VALUES
    ('catalogos.ver', 'Ver catálogos', 'Catálogos', 'Permite ver los catálogos del sistema'),
    ('catalogos.editar', 'Editar catálogos', 'Catálogos', 'Permite crear y editar catálogos'),
    ('costos.ver', 'Ver costos', 'Costos', 'Permite ver costos generales y de mezclilla'),
    ('costos.editar', 'Editar costos', 'Costos', 'Permite crear y editar costos'),
    ('produccion.ver', 'Ver producción', 'Producción', 'Permite ver producciones y recibos'),
    ('produccion.editar', 'Editar producción', 'Producción', 'Permite crear y editar producciones'),
    ('ordenes.ver', 'Ver órdenes', 'Órdenes', 'Permite ver órdenes de clientes y compras'),
    ('ordenes.editar', 'Editar órdenes', 'Órdenes', 'Permite crear y editar órdenes'),
    ('ventas.ver', 'Ver ventas', 'Ventas', 'Permite ver ventas y salidas'),
    ('ventas.editar', 'Editar ventas', 'Ventas', 'Permite crear y editar ventas'),
    ('inventarios.ver', 'Ver inventarios', 'Inventarios', 'Permite ver inventarios'),
    ('inventarios.editar', 'Editar inventarios', 'Inventarios', 'Permite mover y ajustar inventarios'),
    ('servicios.ver', 'Ver servicios', 'Servicios', 'Permite ver servicios y solicitudes'),
    ('servicios.editar', 'Editar servicios', 'Servicios', 'Permite crear y editar servicios'),
    ('reportes.ver', 'Ver reportes', 'Reportes', 'Permite ver reportes y resúmenes'),
    ('financiero.ver', 'Ver financiero', 'Financiero', 'Permite ver dispersiones, préstamos, etc.'),
    ('financiero.editar', 'Editar financiero', 'Financiero', 'Permite crear y editar movimientos financieros'),
    ('usuarios.ver', 'Ver usuarios', 'Usuarios', 'Permite ver la lista de usuarios'),
    ('usuarios.editar', 'Editar usuarios', 'Usuarios', 'Permite crear y editar usuarios'),
    ('roles.ver', 'Ver roles', 'Roles', 'Permite ver roles de la empresa'),
    ('roles.editar', 'Editar roles', 'Roles', 'Permite crear y editar roles'),
    ('compras.ver', 'Ver compras', 'Compras', 'Permite ver compras de insumos y materiales'),
    ('compras.editar', 'Editar compras', 'Compras', 'Permite crear y editar compras'),
    ('reingresos.ver', 'Ver reingresos', 'Reingresos', 'Permite ver reingresos de mercancía'),
    ('reingresos.editar', 'Editar reingresos', 'Reingresos', 'Permite crear y editar reingresos');

-- ----------------------------------------------------------
-- ROLES (cada empresa crea los suyos)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(empresa_id, nombre)
);

CREATE INDEX idx_roles_empresa ON roles(empresa_id);

-- ----------------------------------------------------------
-- ROL ↔ PERMISOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS rol_permisos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rol_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permiso_id UUID NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    UNIQUE(rol_id, permiso_id)
);

-- ----------------------------------------------------------
-- USUARIO ↔ ROL
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS usuario_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    UNIQUE(usuario_id, rol_id)
);

-- ----------------------------------------------------------
-- FUNCIÓN PARA ACTUALIZAR updated_at AUTOMÁTICAMENTE
-- ----------------------------------------------------------
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_empresas_updated BEFORE UPDATE ON empresas
    FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trg_usuarios_updated BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trg_roles_updated BEFORE UPDATE ON roles
    FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
