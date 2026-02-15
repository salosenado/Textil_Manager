//
//  AgregarPagoOtorgadoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//
import SwiftUI
import SwiftData

struct AgregarPagoOtorgadoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var prestamo: PrestamoOtorgado

    @State private var montoTexto = ""
    @State private var esCapital: Bool = true
    @State private var fechaPago = Date()

    private var montoDouble: Double {
        Double(montoTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "$0.00"
    }

    var body: some View {

        NavigationStack {

            Form {

                // 🔹 RESUMEN DEL PRÉSTAMO
                Section("Resumen del Préstamo") {

                    HStack {
                        Text("Receptor")
                        Spacer()
                        Text("\(prestamo.nombre) \(prestamo.apellido)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Monto Original")
                        Spacer()
                        Text(formatoMoneda(prestamo.montoPrestado))
                    }

                    HStack {
                        Text("Capital Pendiente")
                            .bold()
                        Spacer()
                        Text(formatoMoneda(prestamo.capitalPendiente))
                            .bold()
                            .foregroundColor(.red)
                    }
                }

                // 🔹 DATOS DEL PAGO
                Section("Datos del Pago") {

                    HStack {
                        Text("Monto")
                        Spacer()

                        TextField("0.00", text: $montoTexto)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    DatePicker("Fecha de Pago",
                               selection: $fechaPago,
                               displayedComponents: .date)

                    Picker("Tipo de Pago", selection: $esCapital) {
                        Text("Capital").tag(true)
                        Text("Interés").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                // 🔹 PREVISUALIZACIÓN
                Section("Impacto del Pago") {

                    if esCapital {
                        HStack {
                            Text("Nuevo Capital Pendiente")
                            Spacer()
                            Text(formatoMoneda(prestamo.capitalPendiente - montoDouble))
                                .foregroundColor(.blue)
                        }
                    } else {
                        HStack {
                            Text("Este pago no reduce capital")
                            Spacer()
                            Text("Interés")
                                .foregroundColor(.orange)
                        }
                    }
                }

                // 🔹 BOTÓN GUARDAR
                Section {
                    Button {

                        let nuevoPago = PagoPrestamoOtorgado(
                            monto: montoDouble,
                            esCapital: esCapital,
                            usuario: "Admin"
                        )

                        prestamo.pagos.append(nuevoPago)

                        if esCapital {
                            prestamo.capitalPendiente -= montoDouble
                        }

                        do {
                            try context.save()
                            dismiss()
                        } catch {
                            print("Error guardando pago:", error)
                        }

                    } label: {
                        HStack {
                            Spacer()
                            Text("Registrar Pago")
                                .bold()
                            Spacer()
                        }
                    }
                    .disabled(montoDouble <= 0)
                }
            }
            .navigationTitle("Nuevo Pago")
        }
    }
}
