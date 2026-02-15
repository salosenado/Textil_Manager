//
//  NuevoMovimientoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  NuevoMovimientoView.swift
//  Textil
//
//
//  NuevoMovimientoView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct NuevoMovimientoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var clientes: [Cliente]

    @State private var tipo: MovimientoCaja.Tipo = .ingreso
    @State private var fecha = Date()
    @State private var monto = ""
    @State private var clienteSeleccionado: Cliente? = nil
    @State private var razon = ""

    // 🔥 FORMATTER PROFESIONAL
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.groupingSeparator = ","
        f.decimalSeparator = "."
        return f
    }()

    // 🔥 CONVERSIÓN LIMPIA
    var montoDouble: Double {
        let limpio = monto.replacingOccurrences(of: ",", with: "")
        return Double(limpio) ?? 0
    }

    var puedeGuardar: Bool {
        montoDouble > 0 &&
        (tipo == .ingreso ? clienteSeleccionado != nil : !razon.isEmpty)
    }

    var body: some View {

        NavigationStack {
            Form {

                Section("Tipo") {
                    Picker("Tipo", selection: $tipo) {
                        Text("Ingreso").tag(MovimientoCaja.Tipo.ingreso)
                        Text("Egreso").tag(MovimientoCaja.Tipo.egreso)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Información") {

                    DatePicker("Fecha",
                               selection: $fecha,
                               displayedComponents: .date)

                    // 🔥 MONTO CON MX$ Y SEPARADOR
                    HStack {
                        Text("MX$")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)

                        TextField("0.00", text: $monto)
                            .keyboardType(.decimalPad)
                            .onChange(of: monto) { _, newValue in
                                formatInput(newValue)
                            }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    if tipo == .ingreso {

                        Picker("Cliente", selection: $clienteSeleccionado) {

                            Text("Seleccionar")
                                .tag(nil as Cliente?)

                            ForEach(clientes) { cliente in
                                Text(cliente.nombreComercial)
                                    .tag(cliente as Cliente?)
                            }
                        }
                        .pickerStyle(.menu)

                    } else {

                        TextField("Razón", text: $razon)
                    }
                }
            }
            .navigationTitle("Nuevo Movimiento")
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardar()
                    }
                    .disabled(!puedeGuardar)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    // 🔥 FORMATEO EN VIVO
    private func formatInput(_ value: String) {
        let limpio = value
            .replacingOccurrences(of: ",", with: "")
            .filter { "0123456789.".contains($0) }

        if let number = Double(limpio) {
            monto = formatter.string(from: NSNumber(value: number)) ?? ""
        } else {
            monto = ""
        }
    }

    private func guardar() {

        let movimiento = MovimientoCaja(
            tipo: tipo,
            fecha: fecha,
            monto: montoDouble,
            cliente: tipo == .ingreso ? clienteSeleccionado?.nombreComercial : nil,
            razon: tipo == .egreso ? razon : nil
        )

        context.insert(movimiento)
        dismiss()
    }
}
