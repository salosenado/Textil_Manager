-- ============================================================
-- MIGRACIÓN 013: Agregar descripcion a departamentos
-- ============================================================
ALTER TABLE departamentos ADD COLUMN IF NOT EXISTS descripcion TEXT;
