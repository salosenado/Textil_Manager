-- ============================================================
-- MIGRACIÓN 011: Ajustes a Catálogos
-- Cambios solicitados por el cliente
-- ============================================================

-- TELAS: agregar campo peso
ALTER TABLE telas ADD COLUMN IF NOT EXISTS peso VARCHAR(100);

-- MAQUILEROS: agregar email
ALTER TABLE maquileros ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- SERVICIOS: agregar plazo de pago
ALTER TABLE servicios ADD COLUMN IF NOT EXISTS plazo_pago_dias INT DEFAULT 0;

-- EMPRESAS: asegurar que tenga todos los campos necesarios
-- (nombre, rfc, direccion, telefono, logo_url ya existen en 001)
