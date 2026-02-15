//
//  CxPTabBadgeView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  CxPTabBadgeView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CxPTabBadgeView: View {

    @Query private var ordenes: [OrdenCompra]
    @Query private var recepciones: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]

    // MARK: - TOTAL PENDIENTE (BADGE)

    var totalPendiente: Double {

        var total: Double = 0

        for orden in ordenes where !orden.cancelada {

            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
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

            let totalPedido = orden.aplicaIVA
                ? subtotal * 1.16
                : subtotal

            let costoPromedio = piezasPedidas == 0
                ? 0
                : totalPedido / Double(piezasPedidas)

            let totalRecibido = Double(piezasRecibidas) * costoPromedio

            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }

            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }

            let saldo = totalRecibido - totalPagado

            if saldo > 0 {
                total += saldo
            }
        }

        return total
    }

    // MARK: - DETECTAR DEUDA VENCIDA

    var hayDeudaVencida: Bool {

        for orden in ordenes where !orden.cancelada {

            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
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

            let totalPedido = orden.aplicaIVA
                ? subtotal * 1.16
                : subtotal

            let costoPromedio = piezasPedidas == 0
                ? 0
                : totalPedido / Double(piezasPedidas)

            let totalRecibido = Double(piezasRecibidas) * costoPromedio

            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }

            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }

            let saldo = totalRecibido - totalPagado

            if saldo > 0 {

                let vencimiento = Calendar.current.date(
                    byAdding: .day,
                    value: orden.plazoDias ?? 0,
                    to: orden.fechaOrden
                ) ?? Date()

                if Date() > vencimiento {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - BODY

    var body: some View {

        Group {
            if totalPendiente > 0 {
                Color.clear
                    .badge(Int(totalPendiente))
            } else {
                Color.clear
            }
        }
        .onChange(of: hayDeudaVencida) { nuevoValor in
            NotificationCenter.default.post(
                name: Notification.Name("DeudaVencidaCXP"),
                object: nuevoValor
            )
        }
    }
}
