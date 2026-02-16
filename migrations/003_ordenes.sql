-- ============================================================
-- MIGRACIÓN 003: Órdenes de Clientes y Compras
-- ============================================================

-- ----------------------------------------------------------
-- ÓRDENES DE CLIENTE
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS ordenes_cliente (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    numero_venta INT NOT NULL,
    cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
    cliente_nombre VARCHAR(255),
    agente_id UUID REFERENCES agentes(id) ON DELETE SET NULL,
    numero_pedido_cliente VARCHAR(100),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_entrega TIMESTAMPTZ,
    aplica_iva BOOLEAN NOT NULL DEFAULT false,
    cancelada BOOLEAN NOT NULL DEFAULT false,
    usuario_cancelacion VARCHAR(255),
    fecha_cancelacion TIMESTAMPTZ,
    ultimo_usuario_edicion VARCHAR(255),
    fecha_ultima_edicion TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ordenes_cliente_empresa ON ordenes_cliente(empresa_id);
CREATE INDEX idx_ordenes_cliente_cliente ON ordenes_cliente(cliente_id);

-- ----------------------------------------------------------
-- DETALLES DE ORDEN DE CLIENTE
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS orden_cliente_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES ordenes_cliente(id) ON DELETE CASCADE,
    articulo VARCHAR(255),
    linea VARCHAR(255),
    modelo VARCHAR(255),
    modelo_id UUID REFERENCES modelos(id) ON DELETE SET NULL,
    color VARCHAR(255),
    talla VARCHAR(100),
    unidad VARCHAR(100),
    cantidad INT NOT NULL DEFAULT 0,
    precio_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orden_cliente_det_orden ON orden_cliente_detalles(orden_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE PEDIDO (historial de cambios en la orden)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_pedido (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES ordenes_cliente(id) ON DELETE CASCADE,
    movimiento TEXT NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_pedido_orden ON movimientos_pedido(orden_id);

-- ----------------------------------------------------------
-- ÓRDENES DE COMPRA (a proveedores)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS ordenes_compra (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    numero_compra INT NOT NULL,
    proveedor_id UUID REFERENCES proveedores(id) ON DELETE SET NULL,
    proveedor_nombre VARCHAR(255),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_recepcion TIMESTAMPTZ,
    aplica_iva BOOLEAN NOT NULL DEFAULT false,
    observaciones TEXT,
    cancelada BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ordenes_compra_empresa ON ordenes_compra(empresa_id);

-- ----------------------------------------------------------
-- DETALLES DE ORDEN DE COMPRA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS orden_compra_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES ordenes_compra(id) ON DELETE CASCADE,
    articulo VARCHAR(255),
    modelo VARCHAR(255),
    modelo_id UUID REFERENCES modelos(id) ON DELETE SET NULL,
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orden_compra_det_orden ON orden_compra_detalles(orden_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE ORDEN DE COMPRA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS orden_compra_movimientos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES ordenes_compra(id) ON DELETE CASCADE,
    movimiento TEXT NOT NULL,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_compra_orden ON orden_compra_movimientos(orden_id);

-- ----------------------------------------------------------
-- COMPRAS DE INSUMOS (a clientes-proveedores)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS compras_insumo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    numero_compra INT NOT NULL,
    proveedor_cliente VARCHAR(255),
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_recepcion TIMESTAMPTZ,
    aplica_iva BOOLEAN NOT NULL DEFAULT false,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compras_insumo_empresa ON compras_insumo(empresa_id);

-- ----------------------------------------------------------
-- DETALLES DE COMPRA DE INSUMOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS compra_insumo_detalles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compra_id UUID NOT NULL REFERENCES compras_insumo(id) ON DELETE CASCADE,
    articulo VARCHAR(255),
    linea VARCHAR(255),
    modelo VARCHAR(255),
    color VARCHAR(255),
    talla VARCHAR(100),
    unidad VARCHAR(100),
    cantidad INT NOT NULL DEFAULT 0,
    costo_unitario DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_compra_insumo_det_compra ON compra_insumo_detalles(compra_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_ordenes_cliente_updated BEFORE UPDATE ON ordenes_cliente FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_ordenes_compra_updated BEFORE UPDATE ON ordenes_compra FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_compras_insumo_updated BEFORE UPDATE ON compras_insumo FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
