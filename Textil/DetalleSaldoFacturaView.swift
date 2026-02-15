//
//  DetalleSaldoFacturaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//
//
//  DetalleSaldoFacturaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//

import SwiftUI
import SwiftData
import UIKit

struct DetalleSaldoFacturaView: View {

    @Environment(\.modelContext) private var context

    @State private var mostrarPago = false
    @State private var pagoEliminar: PagoSaldoFactura?
    @State private var password = ""
    @State private var mostrarPassword = false

    private let adminPassword = "1234"

    @Bindable var factura: SaldoFacturaAdelantada

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                resumenGeneral
                moduloPagos
                cardPagosRegistrados
                botonImprimir
                historialMovimientos
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(factura.empresaNombre)
        .sheet(isPresented: $mostrarPago) {
            AgregarPagoFacturaView(factura: factura)
        }
        .alert("Contraseña requerida", isPresented: $mostrarPassword) {

            SecureField("Contraseña", text: $password)

            Button("Eliminar", role: .destructive) {

                if password == adminPassword,
                   let pago = pagoEliminar {

                    pago.eliminado = true

                    let movimiento = MovimientoFactura(
                        tipo: "Pago Eliminado",
                        descripcion: "Se eliminó un pago",
                        usuario: pago.usuario,
                        monto: pago.monto
                    )

                    factura.movimientos.append(movimiento)

                    try? context.save()
                }

                password = ""
            }

            Button("Cancelar", role: .cancel) {
                password = ""
            }
        }
    }

    // MARK: - RESUMEN GENERAL

    private var resumenGeneral: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Información General")
                .font(.headline)

            Divider()

            fila("Dueño", factura.dueno)
            fila("Contacto", factura.contacto ?? "-")
            fila("Email", factura.email ?? "-")
            fila("Teléfono", factura.telefono ?? "-")

            Divider()

            fila("Subtotal", formatoMoneda(factura.subtotal))
            fila("IVA 16%", formatoMoneda(factura.iva))
            fila("Total", formatoMoneda(factura.total))

            Divider()

            fila("Total Pagado",
                 formatoMoneda(factura.totalPagado),
                 .green)

            fila("Saldo Pendiente",
                 formatoMoneda(factura.saldoPendiente),
                 factura.saldoPendiente > 0 ? .red : .blue)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(radius: 3)
    }

    // MARK: - MODULO PAGOS

    private var moduloPagos: some View {

        VStack(spacing: 15) {

            Text("Pagos")
                .font(.headline)

            Button {
                mostrarPago = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Registrar Pago")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(radius: 3)
    }

    // MARK: - PAGOS REGISTRADOS

    private var cardPagosRegistrados: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Pagos Registrados")
                .font(.headline)

            Divider()

            let pagosActivos = factura.pagos
                .filter { !$0.eliminado }
                .sorted(by: { $0.fecha > $1.fecha })

            if pagosActivos.isEmpty {

                Text("No hay pagos registrados")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)

            } else {

                ForEach(pagosActivos) { pago in

                    HStack {

                        VStack(alignment: .leading, spacing: 4) {

                            Text(pago.fecha.formatted(
                                .dateTime.day().month().year()
                            ))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                            Text(pago.fecha.formatted(
                                .dateTime.hour().minute()
                            ))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }

                        Spacer()

                        Text(formatoMoneda(pago.monto))
                            .fontWeight(.bold)
                            .foregroundColor(.green)

                        Button {
                            pagoEliminar = pago
                            mostrarPassword = true
                        } label: {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }

                    Divider()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(radius: 3)
    }

    // MARK: - MOVIMIENTOS

    // MARK: - MOVIMIENTOS

    private var historialMovimientos: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Movimientos")
                .font(.headline)

            Divider()

            let movimientosOrdenados = factura.movimientos
                .sorted(by: { $0.fecha > $1.fecha })

            if movimientosOrdenados.isEmpty {

                Text("Sin movimientos registrados")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)

            } else {

                ForEach(movimientosOrdenados) { mov in

                    HStack(spacing: 12) {

                        ZStack {
                            Circle()
                                .fill(colorMovimiento(mov).opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: iconoMovimiento(mov))
                                .foregroundColor(colorMovimiento(mov))
                        }

                        VStack(alignment: .leading, spacing: 4) {

                            Text(mov.tipo)
                                .font(.subheadline)
                                .bold()

                            Text(mov.descripcion)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(
                                mov.fecha.formatted(
                                    .dateTime.day().month().year().hour().minute()
                                )
                            )
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }

                        Spacer()

                        if let monto = mov.monto {

                            Text(formatoMoneda(monto))
                                .fontWeight(.bold)
                                .foregroundColor(colorMovimiento(mov))
                        }
                    }

                    Divider()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(radius: 3)
    }


    // MARK: - BOTÓN IMPRIMIR

    private var botonImprimir: some View {

        Button {
            imprimirDetalle()
        } label: {
            HStack {
                Image(systemName: "printer.fill")
                Text("Imprimir Detalle")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
    }

    // MARK: - IMPRESIÓN

    private func imprimirDetalle() {

        let pagosHTML = factura.pagos
            .filter { !$0.eliminado }
            .map {
                """
                <tr>
                    <td>\($0.fecha.formatted(date: .abbreviated, time: .shortened))</td>
                    <td>\($0.usuario)</td>
                    <td style="text-align:right;">\(formatoMoneda($0.monto))</td>
                </tr>
                """
            }.joined()

        let html = """
        <html>
        <body style="font-family:-apple-system; padding:30px;">

        <h2>Detalle Factura Adelantada</h2>

        <p><strong>Empresa:</strong> \(factura.empresaNombre)</p>
        <p><strong>Dueño:</strong> \(factura.dueno)</p>
        <p><strong>Contacto:</strong> \(factura.contacto ?? "-")</p>
        <p><strong>Email:</strong> \(factura.email ?? "-")</p>
        <p><strong>Teléfono:</strong> \(factura.telefono ?? "-")</p>

        <br>

        <p><strong>Subtotal:</strong> \(formatoMoneda(factura.subtotal))</p>
        <p><strong>IVA 16%:</strong> \(formatoMoneda(factura.iva))</p>
        <p><strong>Total:</strong> \(formatoMoneda(factura.total))</p>
        <p><strong>Total Pagado:</strong> \(formatoMoneda(factura.totalPagado))</p>
        <p><strong>Saldo Pendiente:</strong> \(formatoMoneda(factura.saldoPendiente))</p>

        <h3>Historial de Pagos</h3>

        <table width="100%" border="0" cellspacing="0" cellpadding="8">
        <tr>
            <th align="left">Fecha</th>
            <th align="left">Usuario</th>
            <th align="right">Monto</th>
        </tr>
        \(pagosHTML)
        </table>

        <br>
        Documento generado el \(Date().formatted(date: .long, time: .shortened))

        </body>
        </html>
        """

        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let controller = UIPrintInteractionController.shared
        controller.printFormatter = formatter

        let movimiento = MovimientoFactura(
            tipo: "Documento Impreso",
            descripcion: "Se imprimió el detalle de la factura",
            usuario: "Sistema"
        )

        factura.movimientos.append(movimiento)
        try? context.save()

        controller.present(animated: true)
    }


    // MARK: - UTILIDADES

    private func fila(_ titulo: String,
                      _ valor: String,
                      _ color: Color = .primary) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .bold()
                .foregroundColor(color)
        }
    }

    private func iconoMovimiento(_ mov: MovimientoFactura) -> String {

        switch mov.tipo {
        case "Pago Agregado":
            return "arrow.down.circle.fill"
        case "Pago Eliminado":
            return "trash.circle.fill"
        case "Documento Impreso":
            return "printer.fill"
        default:
            return "doc.text.fill"
        }
    }

    private func colorMovimiento(_ mov: MovimientoFactura) -> Color {

        switch mov.tipo {
        case "Pago Agregado":
            return .green
        case "Pago Eliminado":
            return .red
        case "Documento Impreso":
            return .blue
        default:
            return .gray
        }
    }

    
    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
