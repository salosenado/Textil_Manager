//
//  ComisionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct ComisionDetalleView: View {

    let agente: Agente
    let ventasAgente: [VentaCliente]

    @Query private var pagos: [PagoComision]

    @State private var mostrarNuevoPago = false

    var porcentaje: Double {
        Double(agente.comision) ?? 0
    }

    var factor: Double {
        porcentaje / 100
    }

    // 🔥 NUEVO: Total piezas
    var totalPiezas: Int {
        ventasAgente.reduce(0) { total, venta in
            total + venta.detalles.reduce(0) { $0 + $1.cantidad }
        }
    }

    var pagosAgente: [PagoComision] {
        pagos.filter {
            $0.agente?.persistentModelID == agente.persistentModelID
        }
    }

    var totalPagado: Double {
        pagosAgente.reduce(0) { $0 + $1.monto }
    }

    var totalComisionGenerada: Double {
        ventasAgente.reduce(0) { total, venta in

            let subtotal = venta.detalles.reduce(0) {
                $0 + (Double($1.cantidad) * $1.costoUnitario)
            }

            let totalVenta = venta.aplicaIVA
                ? subtotal * 1.16
                : subtotal

            return total + (totalVenta * factor)
        }
    }

    var saldo: Double {
        totalComisionGenerada - totalPagado
    }

    var body: some View {

        List {

            // 🔥 RESUMEN GENERAL
            Section("Resumen") {

                HStack {
                    Text("Total piezas")
                    Spacer()
                    Text("\(totalPiezas)")
                }

                HStack {
                    Text("Comisión generada")
                    Spacer()
                    Text("MX$ \(totalComisionGenerada.formatoMoneda)")
                }

                HStack {
                    Text("Pagado")
                    Spacer()
                    Text("MX$ \(totalPagado.formatoMoneda)")
                }

                HStack {
                    Text("Saldo")
                    Spacer()
                    Text("MX$ \(saldo.formatoMoneda)")
                        .bold()
                        .foregroundStyle(saldo > 0 ? .red : .green)
                }
            }

            // 🔥 HISTORIAL DE VENTAS
            Section("Historial de ventas") {

                ForEach(ventasAgente) { venta in

                    let piezas = venta.detalles.reduce(0) { $0 + $1.cantidad }

                    let subtotal = venta.detalles.reduce(0) {
                        $0 + (Double($1.cantidad) * $1.costoUnitario)
                    }

                    let totalVenta = venta.aplicaIVA
                        ? subtotal * 1.16
                        : subtotal

                    let comisionVenta = totalVenta * factor

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Folio: \(venta.folio)")
                            .bold()

                        Text("Cliente: \(venta.cliente.nombreComercial)")
                            .font(.caption)

                        Text("Piezas: \(piezas)")
                            .font(.caption)

                        Text("Fecha entrega: \(venta.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)

                        Text("Comisión generada: MX$ \(comisionVenta.formatoMoneda)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }

            // 🔥 PAGOS
            Section("Pagos realizados") {

                ForEach(pagosAgente) { pago in
                    HStack {
                        Text(pago.fecha.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("MX$ \(pago.monto.formatoMoneda)")
                    }
                }
            }
        }
        .navigationTitle("\(agente.nombre) \(agente.apellido)")
        .toolbar {
            Button {
                mostrarNuevoPago = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevoPago) {
            NuevoPagoComisionView(agente: agente)
        }
    }
}
