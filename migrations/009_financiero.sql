-- ============================================================
-- MIGRACIÓN 009: Módulo Financiero
-- Dispersiones, Préstamos, Pagos, Movimientos
-- ============================================================

-- ----------------------------------------------------------
-- DISPERSIONES
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS dispersiones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    wara VARCHAR(255),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    porcentaje_comision DECIMAL(5,2) NOT NULL DEFAULT 0,
    comision DECIMAL(12,2) NOT NULL DEFAULT 0,
    iva DECIMAL(12,2) NOT NULL DEFAULT 0,
    neto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    concepto TEXT,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dispersiones_empresa ON dispersiones(empresa_id);

-- ----------------------------------------------------------
-- SALIDAS DE DISPERSIÓN
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS dispersion_salidas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dispersion_id UUID NOT NULL REFERENCES dispersiones(id) ON DELETE CASCADE,
    concepto VARCHAR(255),
    nombre VARCHAR(255),
    cuenta VARCHAR(255),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_disp_salidas_dispersion ON dispersion_salidas(dispersion_id);

-- ----------------------------------------------------------
-- PRÉSTAMOS (recibidos)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS prestamos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    es_persona_moral BOOLEAN NOT NULL DEFAULT false,
    representante VARCHAR(255),
    telefono VARCHAR(50),
    correo VARCHAR(255),
    notas TEXT,
    monto_prestado DECIMAL(12,2) NOT NULL DEFAULT 0,
    tasa_interes DECIMAL(5,2) NOT NULL DEFAULT 0,
    plazo_meses INT NOT NULL DEFAULT 0,
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prestamos_empresa ON prestamos(empresa_id);

-- ----------------------------------------------------------
-- PAGOS DE PRÉSTAMO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_prestamo (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prestamo_id UUID NOT NULL REFERENCES prestamos(id) ON DELETE CASCADE,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto_capital DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_interes DECIMAL(12,2) NOT NULL DEFAULT 0,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_prestamo_prestamo ON pagos_prestamo(prestamo_id);

-- ----------------------------------------------------------
-- PRÉSTAMOS OTORGADOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS prestamos_otorgados (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    es_persona_moral BOOLEAN NOT NULL DEFAULT false,
    representante VARCHAR(255),
    telefono VARCHAR(50),
    correo VARCHAR(255),
    notas TEXT,
    monto_prestado DECIMAL(12,2) NOT NULL DEFAULT 0,
    tasa_interes DECIMAL(5,2) NOT NULL DEFAULT 0,
    plazo_meses INT NOT NULL DEFAULT 0,
    fecha_inicio TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    activo BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_prestamos_otorgados_empresa ON prestamos_otorgados(empresa_id);

-- ----------------------------------------------------------
-- PAGOS DE PRÉSTAMO OTORGADO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_prestamo_otorgado (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prestamo_id UUID NOT NULL REFERENCES prestamos_otorgados(id) ON DELETE CASCADE,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto_capital DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_interes DECIMAL(12,2) NOT NULL DEFAULT 0,
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_prest_otorg ON pagos_prestamo_otorgado(prestamo_id);

-- ----------------------------------------------------------
-- PAGOS DE COMISIÓN (a agentes)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_comision (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    agente_id UUID REFERENCES agentes(id) ON DELETE SET NULL,
    venta_id UUID REFERENCES ventas_cliente(id) ON DELETE SET NULL,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_comision_empresa ON pagos_comision(empresa_id);

-- ----------------------------------------------------------
-- PAGOS DE REGALÍA (a dueños de marca)
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagos_regalia (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    marca_id UUID REFERENCES marcas(id) ON DELETE SET NULL,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_regalia_empresa ON pagos_regalia(empresa_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE BANCO
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_banco (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    concepto TEXT,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    referencia VARCHAR(255),
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_banco_empresa ON movimientos_banco(empresa_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS DE CAJA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_caja (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    concepto TEXT,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_caja_empresa ON movimientos_caja(empresa_id);

-- ----------------------------------------------------------
-- MOVIMIENTOS FINANCIEROS DE VENTA
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_financieros_venta (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    venta_id UUID REFERENCES ventas_cliente(id) ON DELETE SET NULL,
    tipo VARCHAR(50) NOT NULL,
    concepto TEXT,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_fin_venta_empresa ON movimientos_financieros_venta(empresa_id);

-- ----------------------------------------------------------
-- FACTURAS Y SALDOS
-- ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS movimientos_factura (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    numero_factura VARCHAR(100),
    tipo VARCHAR(50) NOT NULL,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mov_factura_empresa ON movimientos_factura(empresa_id);

CREATE TABLE IF NOT EXISTS pagos_saldo_factura (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    factura_id UUID NOT NULL REFERENCES movimientos_factura(id) ON DELETE CASCADE,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_pago TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    referencia VARCHAR(255),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pagos_saldo_factura ON pagos_saldo_factura(factura_id);

CREATE TABLE IF NOT EXISTS saldos_factura_adelantada (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
    numero_factura VARCHAR(100),
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    observaciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_saldos_fact_adel_empresa ON saldos_factura_adelantada(empresa_id);

-- ----------------------------------------------------------
-- TRIGGERS
-- ----------------------------------------------------------
CREATE TRIGGER trg_dispersiones_updated BEFORE UPDATE ON dispersiones FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_prestamos_updated BEFORE UPDATE ON prestamos FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
CREATE TRIGGER trg_prestamos_otorg_updated BEFORE UPDATE ON prestamos_otorgados FOR EACH ROW EXECUTE FUNCTION actualizar_updated_at();
