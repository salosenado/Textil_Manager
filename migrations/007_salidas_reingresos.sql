-- ============================================================
-- MIGRACIÓN 007: Salidas de Insumos y Reingresos
-- ============================================================

-- ----------------------------------------------------------
-- SALIDAS DE INSUMO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS salidas_insumo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    folio VARCHAR(100) NOT NULL,
    fecha_salida TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    destino VARCHAR(255),
    observaciones TEXT,
    cancelada BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salidas_insumo_empresa ON salidas_insumo(empresa_id);

-- ----------------------------------------------------------
-- DETALLES DE SALIDA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS salida_insumo_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salida_id UUID NOT NULL REFERENCES salidas_insumo(id) ON DELETE CASCADE,
    articulo VARCHAR(255),
    modelo VARCHAR(255),
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    unidad VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salida_det_salida ON salida_insumo_detalles(salida_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE SALIDA (historial)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS salida_insumo_movimientos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salida_id UUID NOT NULL REFERENCES salidas_insumo(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    usuario VARCHAR(255),
    icono VARCHAR(50),
    color VARCHAR(50),
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_salida_mov_salida ON salida_insumo_movimientos(salida_id);

-- ----------------------------------------------------------
-- REINGRESOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS reingresos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    folio VARCHAR(100) NOT NULL,
    fecha_reingreso TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    venta_id UUID REFERENCES ventas_cliente(id) ON DELETE SET NULL,
    cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
    motivo TEXT,
    observaciones TEXT,
    cancelado BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reingresos_empresa ON reingresos(empresa_id);

-- ----------------------------------------------------------
-- DETALLES DE REINGRESO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS reingreso_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reingreso_id UUID NOT NULL REFERENCES reingresos(id) ON DELETE CASCADE,
    es_servicio BOOLEAN NOT NULL DEFAULT false,
    nombre VARCHAR(255),
    talla VARCHAR(100),
    unidad VARCHAR(100),
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reingreso_det_reingreso ON reingreso_detalles(reingreso_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE REINGRESO (historial)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS reingreso_movimientos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reingreso_id UUID NOT NULL REFERENCES reingresos(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    usuario VARCHAR(255),
    icono VARCHAR(50),
    color VARCHAR(50),
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reingreso_mov_reingreso ON reingreso_movimientos(reingreso_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_salidas_insumo_updated BEFORE UPDATE ON salidas_insumo FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_reingresos_updated BEFORE UPDATE ON reingresos FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
