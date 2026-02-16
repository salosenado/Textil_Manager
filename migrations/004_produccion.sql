-- ============================================================
-- MIGRACIÓN 004: Producción y Recibos
-- ============================================================

-- ----------------------------------------------------------
-- PRODUCCIONES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS producciones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    detalle_orden_id UUID REFERENCES orden_cliente_detalles(id) ON DELETE SET NULL,
    maquilero_id UUID REFERENCES maquileros(id) ON DELETE SET NULL,
    maquilero_nombre VARCHAR(255),
    pz_cortadas INT NOT NULL DEFAULT 0,
    costo_maquila DECIMAL(12,2) NOT NULL DEFAULT 0,
    orden_maquila VARCHAR(100),
    fecha_orden_maquila TIMESTAMPTZ,
    cancelada BOOLEAN NOT NULL DEFAULT false,
    fecha_cancelacion TIMESTAMPTZ,
    usuario_cancelacion VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_producciones_empresa ON producciones(empresa_id);
CREATE INDEX idx_producciones_detalle ON producciones(detalle_orden_id);

-- ----------------------------------------------------------
-- RECIBOS DE PRODUCCIÓN
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS recibos_produccion (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    produccion_id UUID NOT NULL REFERENCES producciones(id) ON DELETE CASCADE,
    fecha_recibo TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cantidad INT NOT NULL DEFAULT 0,
    observaciones TEXT,
    firma_entrega BYTEA,
    firma_recepcion BYTEA,
    nombre_entrega VARCHAR(255),
    nombre_recepcion VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recibos_prod_produccion ON recibos_produccion(produccion_id);

-- ----------------------------------------------------------
-- DETALLES DE RECIBO (tallas/colores recibidos)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS recibo_produccion_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID NOT NULL REFERENCES recibos_produccion(id) ON DELETE CASCADE,
    talla VARCHAR(100),
    color VARCHAR(255),
    cantidad INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recibo_prod_det_recibo ON recibo_produccion_detalles(recibo_id);

-- ----------------------------------------------------------
-- PAGOS DE RECIBO (pagos al maquilero)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_recibo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID NOT NULL REFERENCES recibos_produccion(id) ON DELETE CASCADE,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    observaciones TEXT,
    usuario_eliminacion VARCHAR(255),
    fecha_eliminacion TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_recibo_recibo ON pagos_recibo(recibo_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_producciones_updated BEFORE UPDATE ON producciones FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
