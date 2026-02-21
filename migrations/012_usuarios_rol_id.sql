-- ============================================================
-- MIGRACIÓN 012: Agregar rol_id a usuarios
-- ============================================================

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS rol_id UUID REFERENCES roles(id);
