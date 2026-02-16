# Migraciones de Base de Datos - Textil

## Estructura

Las migraciones están organizadas por módulo y se ejecutan en orden numérico:

| Archivo | Módulo | Tablas |
|---------|--------|--------|
| `001_base_sistema.sql` | Sistema Base | empresas, usuarios, permisos, roles, rol_permisos, usuario_roles |
| `002_catalogos.sql` | Catálogos | agentes, clientes, proveedores, departamentos, lineas, marcas, colores, tallas, unidades, modelos, articulos, tipos_tela, telas, precios_tela, maquileros, servicios |
| `003_ordenes.sql` | Órdenes | ordenes_cliente, orden_cliente_detalles, movimientos_pedido, ordenes_compra, orden_compra_detalles, compras_insumo, compra_insumo_detalles |
| `004_produccion.sql` | Producción | producciones, recibos_produccion, recibo_produccion_detalles, pagos_recibo |
| `005_recibos_compras.sql` | Recibos Compras | recibos_compra, recibo_compra_detalles, recibo_compra_pagos |
| `006_ventas.sql` | Ventas | ventas_cliente, venta_cliente_detalles, venta_cliente_movimientos, cobros_venta |
| `007_salidas_reingresos.sql` | Salidas/Reingresos | salidas_insumo, salida_insumo_detalles, salida_insumo_movimientos, reingresos, reingreso_detalles, reingreso_movimientos |
| `008_costos.sql` | Costos | costos_generales, costo_general_telas, costo_general_insumos, costos_mezclilla |
| `009_financiero.sql` | Financiero | dispersiones, dispersion_salidas, prestamos, pagos_prestamo, prestamos_otorgados, pagos_prestamo_otorgado, pagos_comision, pagos_regalia, movimientos_banco, movimientos_caja, movimientos_financieros_venta, movimientos_factura, pagos_saldo_factura, saldos_factura_adelantada |
| `010_activos_impresion.sql` | Activos/Impresión | activos_empresa, registros_impresion, centro_impresion_registros, control_diseno_trazo |

## Cómo modificar

- Para agregar campos a una tabla existente, crea un archivo nuevo (ej: `011_agregar_campo_x.sql`) con `ALTER TABLE`
- Para agregar tablas nuevas, crea un archivo nuevo con el siguiente número
- Nunca modifiques archivos ya ejecutados en producción

## Total: ~50 tablas
