-- ============================================================
-- MIGRACIÓN 006: Ventas
-- ============================================================

-- ----------------------------------------------------------
-- VENTAS A CLIENTES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS ventas_cliente (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    folio VARCHAR(100) NOT NULL,
    fecha_venta TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_entrega TIMESTAMPTZ,
    cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
    agente_id UUID REFERENCES agentes(id) ON DELETE SET NULL,
    numero_factura VARCHAR(100),
    aplica_iva BOOLEAN NOT NULL DEFAULT false,
    observaciones TEXT,
    nombre_agente_venta VARCHAR(255),
    nombre_responsable_venta VARCHAR(255),
    firma_agente BYTEA,
    firma_responsable BYTEA,
    documento_emitido BOOLEAN NOT NULL DEFAULT false,
    cancelada BOOLEAN NOT NULL DEFAULT false,
    mercancia_enviada BOOLEAN NOT NULL DEFAULT false,
    fecha_envio TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ventas_cliente_empresa ON ventas_cliente(empresa_id);
CREATE INDEX idx_ventas_cliente_cliente ON ventas_cliente(cliente_id);

-- ----------------------------------------------------------
-- DETALLES DE VENTA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS venta_cliente_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id UUID NOT NULL REFERENCES ventas_cliente(id) ON DELETE CASCADE,
    modelo_nombre VARCHAR(255),
    modelo_id UUID REFERENCES modelos(id) ON DELETE SET NULL,
    marca_id UUID REFERENCES marcas(id) ON DELETE SET NULL,
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    unidad VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_venta_det_venta ON venta_cliente_detalles(venta_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE VENTA (historial)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS venta_cliente_movimientos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id UUID NOT NULL REFERENCES ventas_cliente(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    usuario VARCHAR(255),
    icono VARCHAR(50),
    color VARCHAR(50),
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_venta_mov_venta ON venta_cliente_movimientos(venta_id);

-- ----------------------------------------------------------
-- COBROS DE VENTA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS cobros_venta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id UUID NOT NULL REFERENCES ventas_cliente(id) ON DELETE CASCADE,
    fecha_cobro TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    referencia VARCHAR(255),
    observaciones TEXT,
    fecha_eliminacion TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cobros_venta_venta ON cobros_venta(venta_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_ventas_cliente_updated BEFORE UPDATE ON ventas_cliente FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
