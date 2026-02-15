//
//  CxCDetalleClienteView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  CxCDetalleClienteView.swift
//  Textil
//
//
//  CxCDetalleClienteView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CxCDetalleClienteView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let cliente: String
    let ventasCliente: [VentaCliente]

    @Query private var cobros: [CobroVenta]

    @State private var mostrarCobro = false
    @State private var ventaSeleccionada: VentaCliente?

    // 🔐 Password
    @State private var mostrarPassword = false
    @State private var passwordIngresada = ""
    @State private var mostrarErrorPassword = false

    private let passwordCorrecta = "1234"

    var body: some View {

        ScrollView {
            VStack(spacing: 16) {

                ForEach(ventasCliente, id: \.persistentModelID) { venta in

                    let totalVenta = calcularTotal(venta)

                    let cobrosVenta = cobros.filter {
                        $0.venta == venta && $0.fechaEliminacion == nil
                    }

                    let totalCobrado = cobrosVenta.reduce(0) { $0 + $1.monto }

                    let saldo = totalVenta - totalCobrado
                    let status = statusDeVenta(venta)

                    let vencimiento = Calendar.current.date(
                        byAdding: .day,
                        value: venta.cliente.plazoDias,
                        to: venta.fechaEntrega
                    ) ?? venta.fechaEntrega

                    let ultimoPago = cobrosVenta
                        .max(by: { $0.fechaCobro < $1.fechaCobro })

                    VStack(alignment: .leading, spacing: 10) {

                        // 🔵 HEADER CON FOLIO + FACTURA
                        HStack(alignment: .top) {

                            VStack(alignment: .leading, spacing: 4) {

                                Text("Venta: \(venta.folio)")
                                    .font(.headline)

                                if !venta.numeroFactura.isEmpty {
                                    Text("Factura / Nota: \(venta.numeroFactura)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(status.texto)
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(status.color.opacity(0.15))
                                .foregroundStyle(status.color)
                                .cornerRadius(8)
                        }

                        Divider()

                        // 🔵 FECHAS
                        VStack(alignment: .leading, spacing: 4) {

                            Text("Entrega: \(formatoFecha(venta.fechaEntrega))")
                                .font(.caption)

                            Text("Vence: \(formatoFecha(vencimiento))")
                                .font(.caption)
                                .foregroundStyle(
                                    Date() > vencimiento && saldo > 0
                                    ? .red
                                    : .secondary
                                )

                            if let ultimoPago {
                                Text("Último pago: \(formatoFecha(ultimoPago.fechaCobro))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Divider()

                        // 🔵 TOTALES
                        Text("Total: MX$ \(totalVenta.formatoMoneda)")
                        Text("Cobrado: MX$ \(totalCobrado.formatoMoneda)")
                        Text("Saldo: MX$ \(saldo.formatoMoneda)")
                            .bold()

                        // 🔵 BOTÓN DINÁMICO
                        VStack(spacing: 6) {

                            Button {
                                ventaSeleccionada = venta
                                passwordIngresada = ""
                                mostrarPassword = true
                            } label: {
                                Text(
                                    cobrosVenta.isEmpty
                                    ? "Registrar cobro"
                                    : "Ver / Editar cobros"
                                )
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.15))
                                .foregroundStyle(.green)
                                .cornerRadius(10)
                            }

                            if !cobrosVenta.isEmpty {
                                Text("\(cobrosVenta.count) cobro(s) registrado(s)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(status.color.opacity(0.4), lineWidth: 1)
                    )
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.04), radius: 4)
                }
            }
            .padding()
        }
        .navigationTitle(cliente)

        // 🔐 PASSWORD
        .alert("Autorización requerida", isPresented: $mostrarPassword) {

            SecureField("Contraseña", text: $passwordIngresada)

            Button("Cancelar", role: .cancel) { }

            Button("Aceptar") {
                if passwordIngresada == passwordCorrecta {
                    mostrarCobro = true
                } else {
                    mostrarErrorPassword = true
                }
            }

        } message: {
            Text("Ingrese contraseña para continuar")
        }

        // ❌ ERROR PASSWORD
        .alert("Contraseña incorrecta", isPresented: $mostrarErrorPassword) {
            Button("OK", role: .cancel) { }
        }

        // 🔵 SHEET REGISTRAR / EDITAR
        .sheet(isPresented: $mostrarCobro) {
            if let ventaSeleccionada {
                RegistrarCobroView(venta: ventaSeleccionada)
            }
        }
    }

    // MARK: - STATUS

    func statusDeVenta(_ venta: VentaCliente) -> (texto: String, color: Color) {

        let total = calcularTotal(venta)

        let totalCobrado = cobros
            .filter { $0.venta == venta && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + $1.monto }

        let saldo = total - totalCobrado

        if saldo <= 0 {
            return ("Pagado", .green)
        } else if totalCobrado > 0 {
            return ("Parcial", .yellow)
        } else {
            return ("Pendiente", .red)
        }
    }

    // MARK: - CÁLCULOS

    func calcularTotal(_ venta: VentaCliente) -> Double {
        let subtotal = venta.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
        return venta.aplicaIVA ? subtotal * 1.16 : subtotal
    }

    func formatoFecha(_ fecha: Date) -> String {
        fecha.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
