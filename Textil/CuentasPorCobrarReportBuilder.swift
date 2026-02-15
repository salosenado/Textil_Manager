//
//  CuentasPorCobrarReportBuilder.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//

import Foundation

struct CuentasPorCobrarReportBuilder {

    static func construirReporte(
        ventas: [VentaCliente],
        cobros: [CobroVenta],
        clienteFiltro: String? = nil,
        fechaInicio: Date? = nil,
        fechaFin: Date? = nil
    ) -> CuentasPorCobrarReporte {

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

        for venta in ventas where venta.mercanciaEnviada && !venta.cancelada {

            if let clienteFiltro {
                if venta.cliente.nombreComercial != clienteFiltro {
                    continue
                }
            }

            if let fechaInicio, venta.fechaEntrega < fechaInicio {
                continue
            }

            if let fechaFin, venta.fechaEntrega > fechaFin {
                continue
            }

            let subtotal = venta.detalles.reduce(0) {
                $0 + Double($1.cantidad) * $1.costoUnitario
            }

            let totalVenta = venta.aplicaIVA ? subtotal * 1.16 : subtotal

            let totalCobrado = cobros
                .filter { $0.venta == venta && $0.fechaEliminacion == nil }
                .reduce(0) { $0 + $1.monto }

            let saldo = totalVenta - totalCobrado
            if saldo <= 0 { continue }

            let vencimiento = calendario.date(
                byAdding: .day,
                value: venta.cliente.plazoDias,
                to: venta.fechaEntrega
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

        return CuentasPorCobrarReporte(
            fechaGeneracion: hoy,
            cliente: clienteFiltro,
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
