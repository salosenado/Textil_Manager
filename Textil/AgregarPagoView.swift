//
//  AgregarPagoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  AgregarPagoView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct AgregarPagoView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject var authVM: AuthViewModel

    var prestamo: Prestamo

    @State private var montoTexto: String = ""
    @State private var esCapital = false

    // MARK: - Monto numérico real
    private var monto: Double {
        Double(montoTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 24) {

                    // =========================
                    // RESUMEN SUPERIOR
                    // =========================

                    VStack(alignment: .leading, spacing: 14) {

                        Text("Resumen del Préstamo")
                            .font(.headline)

                        fila("Capital Pendiente",
                             formatoMX(prestamo.capitalPendiente),
                             .blue)

                        Divider()

                        if let proximo = prestamo.proximoVencimiento {

                            Text("Próximo Pago (Intereses)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(proximo.formatted(date: .long,
                                                       time: .omitted))
                                Spacer()
                                Text(formatoMX(prestamo.interesParaVencimiento(offset: 0)))
                                    .bold()
                            }

                            Divider()

                            Text("Siguientes Pagos")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            ForEach(1...3, id: \.self) { index in
                                if let siguiente = Calendar.current.date(
                                    byAdding: .month,
                                    value: index,
                                    to: proximo
                                ) {
                                    HStack {
                                        Text(siguiente.formatted(date: .abbreviated,
                                                                 time: .omitted))
                                        Spacer()
                                        Text(formatoMX(prestamo.interesParaVencimiento(offset: index)))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 3)

                    // =========================
                    // REGISTRAR PAGO
                    // =========================

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Registrar Pago")
                            .font(.headline)

                        VStack(alignment: .leading) {

                            Text("Monto")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {

                                Text("MX$")
                                    .font(.title3)
                                    .foregroundColor(.secondary)

                                ZStack(alignment: .leading) {

                                    if montoTexto.isEmpty {
                                        Text("0.00")
                                            .foregroundColor(.gray)
                                            .font(.title3)
                                    }

                                    TextField("", text: $montoTexto)
                                        .keyboardType(.decimalPad)
                                        .font(.title3)
                                        .onChange(of: montoTexto) { _ in
                                            formatearEntrada()
                                        }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(14)
                        }

                        Picker("Tipo de Pago", selection: $esCapital) {
                            Text("Intereses").tag(false)
                            Text("Capital").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(radius: 3)

                    Button {
                        registrarPago()
                    } label: {
                        Text("Guardar Pago")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(monto <= 0 ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .disabled(monto <= 0)
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Nuevo Pago")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - REGISTRO INTELIGENTE

    private func registrarPago() {

        guard monto > 0 else { return }
        guard let usuarioActual = authVM.perfil?.nombre else { return }

        var restante = monto

        let interesVencido = max(
            prestamo.interesEsperadoHastaHoy - prestamo.totalInteresPagado,
            0
        )

        // 1️⃣ Cubrir intereses vencidos primero
        if interesVencido > 0 {

            let pagoInteres = min(restante, interesVencido)

            let nuevoPago = PagoPrestamo(
                monto: pagoInteres,
                esCapital: false,
                usuario: usuarioActual,
                fecha: Date()
            )

            prestamo.pagos.append(nuevoPago)
            context.insert(nuevoPago)

            restante -= pagoInteres
        }

        // 2️⃣ Luego según selección
        if restante > 0 {

            if esCapital {

                let pagoCapital = min(restante, prestamo.capitalPendiente)
                prestamo.capitalPendiente -= pagoCapital

                let nuevoPago = PagoPrestamo(
                    monto: pagoCapital,
                    esCapital: true,
                    usuario: usuarioActual,
                    fecha: Date()
                )

                prestamo.pagos.append(nuevoPago)
                context.insert(nuevoPago)

            } else {

                let nuevoPago = PagoPrestamo(
                    monto: restante,
                    esCapital: false,
                    usuario: usuarioActual,
                    fecha: Date()
                )

                prestamo.pagos.append(nuevoPago)
                context.insert(nuevoPago)
            }
        }

        try? context.save()
        dismiss()
    }

    // MARK: - FORMATO ENTRADA

    private func formatearEntrada() {

        let limpio = montoTexto.replacingOccurrences(of: ",", with: "")
        guard let numero = Double(limpio) else { return }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        if let resultado = formatter.string(from: NSNumber(value: numero)) {
            montoTexto = resultado
        }
    }

    private func formatoMX(_ valor: Double) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "MX$"
        formatter.locale = Locale(identifier: "es_MX")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }

    private func fila(_ titulo: String,
                      _ valor: String,
                      _ color: Color) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .bold()
                .foregroundColor(color)
        }
    }
}
