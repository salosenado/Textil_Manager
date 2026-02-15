//
//  RegaliaDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  RegaliaDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct RegaliaDetalleView: View {

    let marca: Marca
    let ventasMarca: [VentaCliente]

    @Query private var pagos: [PagoRegalia]

    @State private var mostrarNuevoPago = false

    var porcentaje: Double {
        Double(marca.regaliaPorcentaje) ?? 0
    }

    var factor: Double {
        porcentaje / 100
    }

    var pagosMarca: [PagoRegalia] {
        pagos.filter {
            $0.marca?.persistentModelID == marca.persistentModelID
        }
    }

    var totalPagado: Double {
        pagosMarca.reduce(0) { $0 + $1.monto }
    }

    var totalRegaliaGenerada: Double {
        ventasMarca.reduce(0) { total, venta in

            let detallesMarca = venta.detalles.filter {
                $0.marca?.persistentModelID == marca.persistentModelID
            }

            let subtotal = detallesMarca.reduce(0) {
                $0 + (Double($1.cantidad) * $1.costoUnitario)
            }

            let totalVenta = venta.aplicaIVA
                ? subtotal * 1.16
                : subtotal

            return total + (totalVenta * factor)
        }
    }

    var saldo: Double {
        totalRegaliaGenerada - totalPagado
    }

    var body: some View {

        List {

            // 🔥 RESUMEN GENERAL
            Section("Resumen") {

                HStack {
                    Text("Regalía generada")
                    Spacer()
                    Text("MX$ \(totalRegaliaGenerada.formatoMoneda)")
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

                ForEach(ventasMarca) { venta in

                    let detallesMarca = venta.detalles.filter {
                        $0.marca?.persistentModelID == marca.persistentModelID
                    }

                    let piezas = detallesMarca.reduce(0) { $0 + $1.cantidad }

                    let subtotal = detallesMarca.reduce(0) {
                        $0 + (Double($1.cantidad) * $1.costoUnitario)
                    }

                    let totalVenta = venta.aplicaIVA
                        ? subtotal * 1.16
                        : subtotal

                    let regaliaVenta = totalVenta * factor

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Folio: \(venta.folio)")
                            .bold()

                        Text("Cliente: \(venta.cliente.nombreComercial)")
                            .font(.caption)

                        Text("Piezas: \(piezas)")
                            .font(.caption)

                        Text("Fecha entrega: \(venta.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)

                        Text("Regalía generada: MX$ \(regaliaVenta.formatoMoneda)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }

            // 🔥 PAGOS
            Section("Pagos realizados") {

                ForEach(pagosMarca) { pago in
                    HStack {
                        Text(pago.fecha.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("MX$ \(pago.monto.formatoMoneda)")
                    }
                }
            }
        }
        .navigationTitle(marca.nombre)
        .toolbar {
            Button {
                mostrarNuevoPago = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevoPago) {
            NuevoPagoRegaliaView(marca: marca)
        }
    }
}
