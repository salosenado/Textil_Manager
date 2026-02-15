//
//  RegistrarMovimientoVentaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//

import SwiftUI
import SwiftData

struct RegistrarMovimientoVentaView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let venta: VentaCliente

    @Query private var movimientos: [MovimientoFinancieroVenta]

    @State private var tipoSeleccionado: TipoMovimientoVenta = .pago
    @State private var monto = ""
    @State private var fecha = Date()
    @State private var observaciones = ""

    var movimientosVenta: [MovimientoFinancieroVenta] {
        movimientos.filter {
            $0.venta == venta && $0.fechaEliminacion == nil
        }
    }

    var subtotal: Double {
        venta.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
    }

    var iva: Double {
        venta.aplicaIVA ? subtotal * 0.16 : 0
    }

    var totalVenta: Double {
        subtotal + iva
    }

    var totalPagos: Double {
        movimientosVenta
            .filter { $0.tipo == .pago }
            .reduce(0) { $0 + $1.monto }
    }

    var totalFactoraje: Double {
        movimientosVenta
            .filter { $0.tipo == .factoraje }
            .reduce(0) { $0 + $1.monto }
    }

    var totalFillRate: Double {
        movimientosVenta
            .filter { $0.tipo == .fillRate }
            .reduce(0) { $0 + $1.monto }
    }

    var totalDescuentos: Double {
        movimientosVenta
            .filter { $0.tipo == .descuento }
            .reduce(0) { $0 + $1.monto }
    }

    var saldoFinal: Double {
        totalVenta
        - totalPagos
        - totalFactoraje
        - totalFillRate
        - totalDescuentos
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                // 🔝 RESUMEN
                VStack(alignment: .leading, spacing: 6) {

                    Text("Resumen de la Venta")
                        .font(.headline)

                    Divider()

                    Text("Subtotal: MX$ \(subtotal.formatoMoneda)")
                    Text("IVA: MX$ \(iva.formatoMoneda)")
                    Text("Total: MX$ \(totalVenta.formatoMoneda)")
                        .bold()

                    Divider()

                    Text("Pagos: MX$ \(totalPagos.formatoMoneda)")
                    Text("Factoraje: MX$ \(totalFactoraje.formatoMoneda)")
                    Text("Fill Rate: MX$ \(totalFillRate.formatoMoneda)")
                    Text("Descuentos: MX$ \(totalDescuentos.formatoMoneda)")

                    Divider()

                    Text("Saldo Final: MX$ \(saldoFinal.formatoMoneda)")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(saldoFinal <= 0 ? .green : .red)

                }
                .padding()
                .background(Color.gray.opacity(0.06))
                .cornerRadius(14)

                // 📝 FORMULARIO

                VStack(spacing: 12) {

                    Picker("Tipo", selection: $tipoSeleccionado) {
                        Text("Pago").tag(TipoMovimientoVenta.pago)
                        Text("Factoraje").tag(TipoMovimientoVenta.factoraje)
                        Text("Fill Rate").tag(TipoMovimientoVenta.fillRate)
                        Text("Descuento").tag(TipoMovimientoVenta.descuento)
                    }
                    .pickerStyle(.segmented)

                    TextField("Monto", text: $monto)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Fecha", selection: $fecha, displayedComponents: .date)

                    TextField("Observaciones", text: $observaciones)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        guardarMovimiento()
                    } label: {
                        Text("Guardar movimiento")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
            }
            .padding()
        }
        .navigationTitle("Movimientos")
    }

    func guardarMovimiento() {

        guard let montoDouble = Double(monto), montoDouble > 0 else { return }

        let nuevo = MovimientoFinancieroVenta(
            fecha: fecha,
            monto: montoDouble,
            tipo: tipoSeleccionado,
            observaciones: observaciones,
            venta: venta
        )

        context.insert(nuevo)

        monto = ""
        observaciones = ""
    }
}
