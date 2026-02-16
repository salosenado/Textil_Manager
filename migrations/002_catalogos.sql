-- ============================================================
-- MIGRACIÓN 002: Catálogos
-- Todos los catálogos base del sistema
-- ============================================================

-- ----------------------------------------------------------
-- AGENTES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS agentes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255),
    comision DECIMAL(5,2) DEFAULT 0,
    telefono VARCHAR(50),
    email VARCHAR(255),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_agentes_empresa ON agentes(empresa_id);

-- ----------------------------------------------------------
-- CLIENTES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS clientes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre_comercial VARCHAR(255) NOT NULL,
    razon_social VARCHAR(255),
    rfc VARCHAR(20),
    plazo_dias INT DEFAULT 0,
    limite_credito DECIMAL(12,2) DEFAULT 0,
    contacto VARCHAR(255),
    telefono VARCHAR(50),
    email VARCHAR(255),
    calle VARCHAR(255),
    numero VARCHAR(50),
    colonia VARCHAR(255),
    ciudad VARCHAR(255),
    estado VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'México',
    codigo_postal VARCHAR(10),
    observaciones TEXT,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clientes_empresa ON clientes(empresa_id);

-- ----------------------------------------------------------
-- PROVEEDORES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS proveedores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    contacto VARCHAR(255),
    rfc VARCHAR(20),
    plazo_pago_dias INT DEFAULT 0,
    calle VARCHAR(255),
    numero_exterior VARCHAR(50),
    numero_interior VARCHAR(50),
    colonia VARCHAR(255),
    ciudad VARCHAR(255),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    telefono_principal VARCHAR(50),
    telefono_secundario VARCHAR(50),
    email VARCHAR(255),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_proveedores_empresa ON proveedores(empresa_id);

-- ----------------------------------------------------------
-- DEPARTAMENTOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS departamentos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_departamentos_empresa ON departamentos(empresa_id);

-- ----------------------------------------------------------
-- LÍNEAS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS lineas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lineas_empresa ON lineas(empresa_id);

-- ----------------------------------------------------------
-- MARCAS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS marcas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    dueno VARCHAR(255),
    regalia_porcentaje DECIMAL(5,2) DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_marcas_empresa ON marcas(empresa_id);

-- ----------------------------------------------------------
-- COLORES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS colores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_colores_empresa ON colores(empresa_id);

-- ----------------------------------------------------------
-- TALLAS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tallas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(50) NOT NULL,
    orden INT DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tallas_empresa ON tallas(empresa_id);

-- ----------------------------------------------------------
-- UNIDADES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS unidades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    abreviatura VARCHAR(20),
    factor DECIMAL(10,4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_unidades_empresa ON unidades(empresa_id);

-- ----------------------------------------------------------
-- MODELOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS modelos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    codigo VARCHAR(100),
    descripcion TEXT,
    existencia INT DEFAULT 0,
    marca_id UUID REFERENCES marcas(id) ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_modelos_empresa ON modelos(empresa_id);
CREATE INDEX idx_modelos_marca ON modelos(marca_id);

-- ----------------------------------------------------------
-- ARTÍCULOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS articulos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    sku VARCHAR(100),
    descripcion TEXT,
    precio_venta DECIMAL(12,2) DEFAULT 0,
    costo DECIMAL(12,2) DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_articulos_empresa ON articulos(empresa_id);

-- ----------------------------------------------------------
-- TIPOS DE TELA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS tipos_tela (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tipos_tela_empresa ON tipos_tela(empresa_id);

-- ----------------------------------------------------------
-- TELAS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS telas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    composicion TEXT,
    proveedor_id UUID REFERENCES proveedores(id) ON DELETE SET NULL,
    descripcion TEXT,
    activa BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_telas_empresa ON telas(empresa_id);

-- ----------------------------------------------------------
-- PRECIOS DE TELA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS precios_tela (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tela_id UUID NOT NULL REFERENCES telas(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL,
    precio DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_precios_tela_tela ON precios_tela(tela_id);

-- ----------------------------------------------------------
-- MAQUILEROS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS maquileros (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    contacto VARCHAR(255),
    calle VARCHAR(255),
    numero_exterior VARCHAR(50),
    numero_interior VARCHAR(50),
    colonia VARCHAR(255),
    ciudad VARCHAR(255),
    estado VARCHAR(100),
    codigo_postal VARCHAR(10),
    telefono_principal VARCHAR(50),
    telefono_secundario VARCHAR(50),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_maquileros_empresa ON maquileros(empresa_id);

-- ----------------------------------------------------------
-- SERVICIOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS servicios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    costo DECIMAL(12,2) DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_servicios_empresa ON servicios(empresa_id);

-- ----------------------------------------------------------
-- TRIGGERS updated_at
-- ----------------------------------------------------------
CREATE TRIGGER trg_agentes_updated BEFORE UPDATE ON agentes FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_clientes_updated BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_proveedores_updated BEFORE UPDATE ON proveedores FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_departamentos_updated BEFORE UPDATE ON departamentos FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_lineas_updated BEFORE UPDATE ON lineas FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_marcas_updated BEFORE UPDATE ON marcas FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_colores_updated BEFORE UPDATE ON colores FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_tallas_updated BEFORE UPDATE ON tallas FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_unidades_updated BEFORE UPDATE ON unidades FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_modelos_updated BEFORE UPDATE ON modelos FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_articulos_updated BEFORE UPDATE ON articulos FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_tipos_tela_updated BEFORE UPDATE ON tipos_tela FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_telas_updated BEFORE UPDATE ON telas FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_maquileros_updated BEFORE UPDATE ON maquileros FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_servicios_updated BEFORE UPDATE ON servicios FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
