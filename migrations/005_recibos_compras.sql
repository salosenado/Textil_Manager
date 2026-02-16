-- ============================================================
-- MIGRACIÓN 005: Recibos de Compras
-- ============================================================

-- ----------------------------------------------------------
-- RECIBOS DE COMPRA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS recibos_compra (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    orden_compra_id UUID REFERENCES ordenes_compra(id) ON DELETE SET NULL,
    numero_recibo INT NOT NULL,
    fecha_recibo TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recibos_compra_empresa ON recibos_compra(empresa_id);
CREATE INDEX idx_recibos_compra_orden ON recibos_compra(orden_compra_id);

-- ----------------------------------------------------------
-- DETALLES DE RECIBO DE COMPRA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS recibo_compra_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID NOT NULL REFERENCES recibos_compra(id) ON DELETE CASCADE,
    articulo VARCHAR(255),
    modelo VARCHAR(255),
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recibo_compra_det_recibo ON recibo_compra_detalles(recibo_id);

-- ----------------------------------------------------------
-- PAGOS DE RECIBO DE COMPRA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS recibo_compra_pagos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recibo_id UUID NOT NULL REFERENCES recibos_compra(id) ON DELETE CASCADE,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    referencia VARCHAR(255),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_recibo_compra_pagos_recibo ON recibo_compra_pagos(recibo_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_recibos_compra_updated BEFORE UPDATE ON recibos_compra FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
