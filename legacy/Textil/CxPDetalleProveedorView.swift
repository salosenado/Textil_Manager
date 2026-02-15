//
//  CxPDetalleProveedorView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  CxPDetalleProveedorView.swift
//  Textil
//
import SwiftUI
import SwiftData

struct CxPDetalleProveedorView: View {

    let proveedor: String
    let recibosProveedor: [OrdenCompra]

    @Query private var recepciones: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]

    var body: some View {

        List {

            ForEach(recibosProveedor) { orden in

                let subtotal = orden.detalles.reduce(0) { $0 + $1.subtotal }
                let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal

                let piezasPedidas = orden.detalles.reduce(0) { $0 + $1.cantidad }

                let recepcionesOrden = recepciones.filter {
                    $0.ordenCompra == orden &&
                    $0.fechaEliminacion == nil
                }

                let piezasRecibidas = recepcionesOrden.reduce(0) {
                    $0 + Int($1.monto)
                }

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

                let vencimiento = Calendar.current.date(
                    byAdding: .day,
                    value: orden.plazoDias ?? 0,
                    to: orden.fechaOrden
                ) ?? Date()

                let estadoColor: Color =
                    saldo <= 0 ? .green :
                    Date() > vencimiento ? .red : .orange

                VStack(alignment: .leading, spacing: 6) {

                    Text("OC: \(orden.folio)")
                        .bold()

                    Text("Fecha orden: \(orden.fechaOrden.formatted(date: .abbreviated, time: .omitted))")

                    Text("Vence: \(vencimiento.formatted(date: .abbreviated, time: .omitted))")

                    Divider()

                    Text("Total pedido: MX$ \(totalPedido.formatoMoneda)")
                    Text("Total recibido: MX$ \(totalRecibido.formatoMoneda)")
                    Text("Pagado: MX$ \(totalPagado.formatoMoneda)")
                    Text("Saldo: MX$ \(saldo.formatoMoneda)")
                        .foregroundStyle(estadoColor)
                        .bold()
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle(proveedor)
    }
    // MARK: - HISTÓRICO POR AÑO Y MES

    func historicoPorAñoYMes() -> [Int: [Int: (comprado: Double, pagado: Double)]] {
        
        var resultado: [Int: [Int: (Double, Double)]] = [:]
        let calendar = Calendar.current
        
        // 🔵 COMPRADO (por fechaOrden)
        for orden in recibosProveedor {
            
            let year = calendar.component(.year, from: orden.fechaOrden)
            let month = calendar.component(.month, from: orden.fechaOrden)
            
            let subtotal = orden.detalles.reduce(0) { $0 + $1.subtotal }
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            
            resultado[year, default: [:]][month, default: (0,0)].0 += totalPedido
        }
        
        // 🔵 PAGADO (por fechaPago)
        let pagosProveedor = pagos.filter {
            $0.recibo?.ordenCompra?.proveedor == proveedor &&
            $0.fechaEliminacion == nil
        }
        
        for pago in pagosProveedor {
            
            let year = calendar.component(.year, from: pago.fechaPago)
            let month = calendar.component(.month, from: pago.fechaPago)
            
            resultado[year, default: [:]][month, default: (0,0)].1 += pago.monto
        }
        
        return resultado
    }
}
