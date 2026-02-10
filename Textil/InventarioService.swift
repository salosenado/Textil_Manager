//
//  InventarioService.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
//
//  InventarioService.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//

import SwiftData
import Foundation

struct InventarioService {

    // =====================================================
    // RESULTADO ESTÁNDAR
    // =====================================================
    struct Resultado {
        let cantidad: Int
        let ultimaFechaRecibo: Date?
        let ultimaFechaVenta: Date?
    }

    // =====================================================
    // CÁLCULO BASE MODELOS (NO TOCAR)
    // =====================================================
    static func calcular(
        modeloNombre: String,
        produccion: [ReciboProduccion],
        compras: [ReciboCompraDetalle],
        ventas: [VentaClienteDetalle],
        salidas: [SalidaInsumoDetalle]
    ) -> Resultado {

        var cantidad = 0
        var ultimaRecibo: Date?
        var ultimaVenta: Date?

        // 🔹 PRODUCCIÓN
        for recibo in produccion {
            for d in recibo.detalles
            where d.fechaEliminacion == nil && d.modelo == modeloNombre {

                let suma = d.pzPrimera + d.pzSaldo
                cantidad += suma
                ultimaRecibo = max(ultimaRecibo ?? recibo.fechaRecibo,
                                   recibo.fechaRecibo)
            }
        }

        // 🔹 COMPRAS
        for r in compras
        where r.fechaEliminacion == nil && r.modelo == modeloNombre {

            cantidad += Int(r.monto)

            if let f = r.recibo?.fechaRecibo {
                ultimaRecibo = max(ultimaRecibo ?? f, f)
            }
        }

        // 🔹 VENTAS (EGRESO)
        for v in ventas
        where v.fechaEliminacion == nil
        && v.modeloNombre == modeloNombre
        && v.venta?.cancelada == false {

            cantidad -= v.cantidad

            if let f = v.venta?.fechaVenta {
                ultimaVenta = max(ultimaVenta ?? f, f)
            }
        }

        // 🔥 SALIDAS DE INSUMOS (EGRESO REAL)
        for s in salidas
        where s.modeloNombre == modeloNombre
        && s.salida?.cancelada == false {

            cantidad -= s.cantidad
        }

        return Resultado(
            cantidad: max(cantidad, 0),
            ultimaFechaRecibo: ultimaRecibo,
            ultimaFechaVenta: ultimaVenta
        )
    }
    // =====================================================
    // EXISTENCIA ACTUAL MODELO (USO UI)
    // =====================================================
    static func existenciaActual(
        modeloNombre: String,
        context: ModelContext
    ) -> Resultado {

        let produccion = (try? context.fetch(
            FetchDescriptor<ReciboProduccion>()
        )) ?? []

        let compras = (try? context.fetch(
            FetchDescriptor<ReciboCompraDetalle>()
        )) ?? []

        let ventas = (try? context.fetch(
            FetchDescriptor<VentaClienteDetalle>()
        )) ?? []

        let salidas = (try? context.fetch(
            FetchDescriptor<SalidaInsumoDetalle>()
        )) ?? []

        return calcular(
            modeloNombre: modeloNombre,
            produccion: produccion,
            compras: compras,
            ventas: ventas,
            salidas: salidas
        )
    }
    // =====================================================
    // 🔥 INVENTARIO USADO EN SERVICIOS
    // (los servicios descuentan inventario del MODELO)
    // =====================================================
    static func calcularServicio(
        modeloNombre: String,
        context: ModelContext
    ) -> Resultado {

        let produccion = (try? context.fetch(
            FetchDescriptor<ReciboProduccion>()
        )) ?? []

        let compras = (try? context.fetch(
            FetchDescriptor<ReciboCompraDetalle>()
        )) ?? []

        let ventas = (try? context.fetch(
            FetchDescriptor<VentaClienteDetalle>()
        )) ?? []

        let salidas = (try? context.fetch(
            FetchDescriptor<SalidaInsumoDetalle>()
        )) ?? []

        // 👉 MISMO cálculo que el modelo
        // 👉 NO duplica lógica
        // 👉 NO rompe ventas
        // 👉 NO descuenta dos veces
        return calcular(
            modeloNombre: modeloNombre,
            produccion: produccion,
            compras: compras,
            ventas: ventas,
            salidas: salidas
        )
    }
}
