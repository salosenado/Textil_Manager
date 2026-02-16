-- ============================================================
-- MIGRACIÓN 008: Costos (General + Mezclilla)
-- ============================================================

-- ----------------------------------------------------------
-- COSTOS GENERALES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS costos_generales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    departamento_id UUID REFERENCES departamentos(id) ON DELETE SET NULL,
    linea_id UUID REFERENCES lineas(id) ON DELETE SET NULL,
    modelo VARCHAR(255),
    tallas VARCHAR(255),
    descripcion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_costos_generales_empresa ON costos_generales(empresa_id);

-- ----------------------------------------------------------
-- TELAS DEL COSTO GENERAL
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS costo_general_telas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    costo_general_id UUID NOT NULL REFERENCES costos_generales(id) ON DELETE CASCADE,
    nombre VARCHAR(255),
    consumo DECIMAL(12,4) NOT NULL DEFAULT 0,
    precio_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cg_telas_costo ON costo_general_telas(costo_general_id);

-- ----------------------------------------------------------
-- INSUMOS DEL COSTO GENERAL
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS costo_general_insumos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    costo_general_id UUID NOT NULL REFERENCES costos_generales(id) ON DELETE CASCADE,
    nombre VARCHAR(255),
    cantidad DECIMAL(12,4) NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cg_insumos_costo ON costo_general_insumos(costo_general_id);

-- ----------------------------------------------------------
-- COSTOS DE MEZCLILLA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS costos_mezclilla (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    modelo VARCHAR(255),
    tela VARCHAR(255),
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    costo_tela DECIMAL(12,2) NOT NULL DEFAULT 0,
    consumo_tela DECIMAL(12,4) NOT NULL DEFAULT 0,
    costo_poquetin DECIMAL(12,2) NOT NULL DEFAULT 0,
    consumo_poquetin DECIMAL(12,4) NOT NULL DEFAULT 0,
    maquila DECIMAL(12,2) NOT NULL DEFAULT 0,
    lavanderia DECIMAL(12,2) NOT NULL DEFAULT 0,
    cierre DECIMAL(12,2) NOT NULL DEFAULT 0,
    boton DECIMAL(12,2) NOT NULL DEFAULT 0,
    remaches DECIMAL(12,2) NOT NULL DEFAULT 0,
    etiquetas DECIMAL(12,2) NOT NULL DEFAULT 0,
    flete_y_cajas DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_costos_mezclilla_empresa ON costos_mezclilla(empresa_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_costos_generales_updated BEFORE UPDATE ON costos_generales FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_costos_mezclilla_updated BEFORE UPDATE ON costos_mezclilla FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
