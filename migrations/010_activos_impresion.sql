-- ============================================================
-- MIGRACIÓN 010: Activos, Impresión y Control de Diseño
-- ============================================================

-- ----------------------------------------------------------
-- ACTIVOS DE EMPRESA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS activos_empresa (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    valor DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_adquisicion TIMESTAMPTZ,
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_activos_empresa ON activos_empresa(empresa_id);

-- ----------------------------------------------------------
-- REGISTROS DE IMPRESIÓN
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS registros_impresion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    id_referencia VARCHAR(255) NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    usuario VARCHAR(255),
    tipo VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reg_impresion_empresa ON registros_impresion(empresa_id);

-- ----------------------------------------------------------
-- CENTRO DE IMPRESIÓN (registros con firma)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS centro_impresion_registros (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo VARCHAR(100) NOT NULL,
    folio VARCHAR(100),
    empresa_nombre VARCHAR(255),
    responsable VARCHAR(255),
    proveedor VARCHAR(255),
    firma_responsable BYTEA,
    firma_proveedor BYTEA,
    fecha_impresion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_centro_imp_empresa ON centro_impresion_registros(empresa_id);

-- ----------------------------------------------------------
-- CONTROL DE DISEÑO Y TRAZO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS control_diseno_trazo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    modelo VARCHAR(255),
    descripcion TEXT,
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_control_diseno_empresa ON control_diseno_trazo(empresa_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_activos_updated BEFORE UPDATE ON activos_empresa FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_control_diseno_updated BEFORE UPDATE ON control_diseno_trazo FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
