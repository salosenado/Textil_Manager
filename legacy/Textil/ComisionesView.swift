//
//  ComisionesView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftUI
import SwiftData

struct ComisionesView: View {

    @Query private var ventas: [VentaCliente]
    @Query private var agentes: [Agente]
    @Query private var pagos: [PagoComision]

    var body: some View {

        NavigationStack {

            List {

                ForEach(agentes.filter { $0.activo }) { agente in

                    let resumen = calcularResumen(agente: agente)

                    NavigationLink {
                        ComisionDetalleView(
                            agente: agente,
                            ventasAgente: resumen.ventas
                        )
                    } label: {

                        VStack(alignment: .leading, spacing: 6) {

                            Text("\(agente.nombre) \(agente.apellido)")
                                .font(.headline)

                            Divider()

                            Text("Ventas enviadas: \(resumen.ventas.count)")
                                .font(.caption)

                            Text("Comisión generada: MX$ \(resumen.totalComision.formatoMoneda)")
                                .font(.caption)

                            Text("Pagado: MX$ \(resumen.totalPagado.formatoMoneda)")
                                .font(.caption)

                            Divider()

                            Text("Saldo: MX$ \(resumen.saldo.formatoMoneda)")
                                .font(.headline)
                                .foregroundStyle(
                                    resumen.saldo > 0 ? .red : .green
                                )
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Comisiones")
        }
    }

    func calcularResumen(agente: Agente) -> (
        totalComision: Double,
        totalPagado: Double,
        saldo: Double,
        ventas: [VentaCliente]
    ) {

        let ventasEnviadas = ventas.filter {
            $0.mercanciaEnviada &&
            !$0.cancelada &&
            $0.agente?.persistentModelID == agente.persistentModelID
        }

        let porcentaje = Double(agente.comision) ?? 0
        let factor = porcentaje / 100

        var totalComision: Double = 0

        for venta in ventasEnviadas {

            let subtotal = venta.detalles.reduce(0) {
                $0 + (Double($1.cantidad) * $1.costoUnitario)
            }

            let totalVenta = venta.aplicaIVA
                ? subtotal * 1.16
                : subtotal

            totalComision += totalVenta * factor
        }

        let pagosAgente = pagos.filter {
            $0.agente?.persistentModelID == agente.persistentModelID
        }

        let totalPagado = pagosAgente.reduce(0) { $0 + $1.monto }

        let saldo = totalComision - totalPagado

        return (
            totalComision,
            totalPagado,
            saldo,
            ventasEnviadas
        )
    }
}
