//
//  AgregarPagoFacturaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//


import SwiftUI
import SwiftData

struct AgregarPagoFacturaView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var factura: SaldoFacturaAdelantada

    @State private var montoTexto: String = ""
    @State private var mostrarError = false

    private let usuarioActual = "Admin"

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                // 🔵 RESUMEN FINANCIERO
                VStack(spacing: 10) {

                    fila("Total Factura",
                         formatoMoneda(factura.total),
                         .primary)

                    fila("Total Pagado",
                         formatoMoneda(factura.totalPagado),
                         .green)

                    Divider()

                    fila("Saldo Pendiente",
                         formatoMoneda(factura.saldoPendiente),
                         .red)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)

                // 🧾 CAPTURA MONTO
                VStack(alignment: .leading, spacing: 12) {

                    Text("Nuevo Abono")
                        .font(.headline)

                    HStack {

                        Text("MX$")
                            .foregroundColor(.secondary)

                        TextField("0", text: $montoTexto)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    if mostrarError {
                        Text("El monto no puede ser mayor al saldo pendiente.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(18)

                Spacer()

            }
            .padding()
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Registrar Pago")
            .toolbar {

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        guardarPago()
                    }
                    .disabled((Double(montoTexto) ?? 0) <= 0)
                }
            }
        }
    }

    // MARK: - GUARDAR

    private func guardarPago() {

        let monto = Double(montoTexto) ?? 0

        guard monto > 0,
              monto <= factura.saldoPendiente else {
            mostrarError = true
            return
        }

        let nuevoPago = PagoSaldoFactura(
            monto: monto,
            usuario: usuarioActual
        )

        factura.pagos.append(nuevoPago)

        let movimiento = MovimientoFactura(
            tipo: "Pago Agregado",
            descripcion: "Se registró un pago",
            usuario: usuarioActual,
            monto: monto
        )

        factura.movimientos.append(movimiento)

        try? context.save()
        dismiss()
    }

    
    // MARK: - FILA RESUMEN

    private func fila(_ titulo: String,
                      _ valor: String,
                      _ color: Color) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }

    // MARK: - FORMATO MONEDA

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
