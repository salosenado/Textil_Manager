//
//  CuentasPorPagarReporte.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


//
//  CuentasPorPagarReportBuilder.swift
//  Textil
//

import Foundation

struct CuentasPorPagarReporte {

    var fechaGeneracion: Date
    var proveedor: String?
    var fechaInicio: Date?
    var fechaFin: Date?

    var vigente: Double
    var semanaActual: Double
    var semanaSiguiente: Double
    var dias30: Double
    var dias60: Double
    var dias90: Double
    var mas90: Double

    var totalGeneral: Double
}

struct CuentasPorPagarReportBuilder {

    static func construirReporte(
        ordenes: [OrdenCompra],
        recepciones: [ReciboCompraDetalle],
        pagos: [PagoRecibo],
        proveedorFiltro: String? = nil,
        fechaInicio: Date? = nil,
        fechaFin: Date? = nil
    ) -> CuentasPorPagarReporte {

        let calendario = Calendar.current
        let hoy = Date()

        var vigente: Double = 0
        var semanaActual: Double = 0
        var semanaSiguiente: Double = 0
        var dias30: Double = 0
        var dias60: Double = 0
        var dias90: Double = 0
        var mas90: Double = 0

        let inicioSemana = calendario.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        let finSemanaLaboral = calendario.date(byAdding: .day, value: 4, to: inicioSemana)!

        let inicioSemanaSiguiente = calendario.date(byAdding: .day, value: 7, to: inicioSemana)!
        let finSemanaLaboralSiguiente = calendario.date(byAdding: .day, value: 4, to: inicioSemanaSiguiente)!

        for orden in ordenes where !orden.cancelada {

            if let proveedorFiltro {
                if orden.proveedor.trimmingCharacters(in: .whitespaces) != proveedorFiltro {
                    continue
                }
            }

            if let fechaInicio, orden.fechaOrden < fechaInicio {
                continue
            }

            if let fechaFin, orden.fechaOrden > fechaFin {
                continue
            }

            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden && $0.fechaEliminacion == nil
            }

            let piezasRecibidas = recepcionesOrden.reduce(0) {
                $0 + Int($1.monto)
            }

            let piezasPedidas = orden.detalles.reduce(0) {
                $0 + $1.cantidad
            }

            let subtotal = orden.detalles.reduce(0) {
                $0 + $1.subtotal
            }

            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let costoPromedio = piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
            let totalRecibido = Double(piezasRecibidas) * costoPromedio

            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden && $0.fechaEliminacion == nil
            }

            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }
            let saldo = totalRecibido - totalPagado

            if saldo <= 0 { continue }

            let vencimiento = calendario.date(
                byAdding: .day,
                value: orden.plazoDias ?? 0,
                to: orden.fechaOrden
            )!

            let dias = calendario.dateComponents([.day], from: vencimiento, to: hoy).day ?? 0

            if dias <= 0 {
                vigente += saldo
            }
            else if vencimiento >= inicioSemana && vencimiento <= finSemanaLaboral {
                semanaActual += saldo
            }
            else if vencimiento >= inicioSemanaSiguiente && vencimiento <= finSemanaLaboralSiguiente {
                semanaSiguiente += saldo
            }
            else if dias <= 30 {
                dias30 += saldo
            }
            else if dias <= 60 {
                dias60 += saldo
            }
            else if dias <= 90 {
                dias90 += saldo
            }
            else {
                mas90 += saldo
            }
        }

        let total = vigente + semanaActual + semanaSiguiente + dias30 + dias60 + dias90 + mas90

        return CuentasPorPagarReporte(
            fechaGeneracion: hoy,
            proveedor: proveedorFiltro,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            vigente: vigente,
            semanaActual: semanaActual,
            semanaSiguiente: semanaSiguiente,
            dias30: dias30,
            dias60: dias60,
            dias90: dias90,
            mas90: mas90,
            totalGeneral: total
        )
    }
}
