//
//  NuevoActivoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/10/26.
//
//
//  NuevoActivoView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct NuevoActivoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // 🔥 Traemos todas las empresas
    @Query private var empresas: [Empresa]

    // 🔥 Empresa seleccionada
    @State private var empresaSeleccionada: Empresa?

    // =========================
    // 📍 UBICACIÓN
    // =========================
    @State private var ubicacionSeleccionada = "Oficina"
    @State private var ubicacionPersonalizada = ""
    private let ubicaciones = ["Oficina", "Villa Victoria", "Otro"]

    // =========================
    // 📦 DATOS
    // =========================
    @State private var articulo = ""
    @State private var fechaCompra = Date()
    @State private var cantidad = 1
    @State private var costoUnitario = ""

    // =========================
    // 🔢 FORMATEADOR
    // =========================
    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        f.groupingSeparator = ","
        f.decimalSeparator = "."
        return f
    }()

    var costoUnitarioDouble: Double {
        let limpio = costoUnitario.replacingOccurrences(of: ",", with: "")
        return Double(limpio) ?? 0
    }

    var costoTotal: Double {
        Double(cantidad) * costoUnitarioDouble
    }

    var ubicacionFinal: String {
        ubicacionSeleccionada == "Otro"
        ? ubicacionPersonalizada
        : ubicacionSeleccionada
    }

    var puedeGuardar: Bool {
        !articulo.isEmpty &&
        costoUnitarioDouble > 0 &&
        empresaSeleccionada != nil &&
        !(ubicacionSeleccionada == "Otro" && ubicacionPersonalizada.isEmpty)
    }

    var body: some View {

        NavigationStack {
            Form {

                // =========================
                // 🏢 EMPRESA (PICKER)
                // =========================
                Section("Empresa") {
                    Picker("Seleccionar empresa", selection: $empresaSeleccionada) {
                        Text("Seleccionar").tag(Empresa?.none)

                        ForEach(empresas) { empresa in
                            Text(empresa.nombre)
                                .tag(Optional(empresa))
                        }
                    }
                    .pickerStyle(.menu)
                }

                // =========================
                // 📍 UBICACIÓN
                // =========================
                Section("Ubicación") {

                    Picker("Ubicación del Activo", selection: $ubicacionSeleccionada) {
                        ForEach(ubicaciones, id: \.self) { ubicacion in
                            Text(ubicacion)
                        }
                    }
                    .pickerStyle(.segmented)

                    if ubicacionSeleccionada == "Otro" {
                        TextField("Especificar ubicación", text: $ubicacionPersonalizada)
                    }
                }

                // =========================
                // 📦 ARTÍCULO
                // =========================
                Section("Artículo") {
                    TextField("Nombre del artículo", text: $articulo)
                }

                // =========================
                // 💳 COMPRA
                // =========================
                Section("Compra") {

                    DatePicker("Fecha de compra",
                               selection: $fechaCompra,
                               displayedComponents: .date)

                    Stepper("Cantidad: \(cantidad)",
                            value: $cantidad,
                            in: 1...10_000)

                    HStack {
                        Text("MX$")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(height: 40)

                            TextField("0.00", text: $costoUnitario)
                                .keyboardType(.decimalPad)
                                .padding(.horizontal, 10)
                                .onChange(of: costoUnitario) { _, newValue in
                                    formatInput(newValue)
                                }
                        }
                    }
                }

                // =========================
                // 💰 TOTAL
                // =========================
                Section("Total") {
                    HStack {
                        Text("MX$")
                            .foregroundStyle(.secondary)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(
                            formatter.string(from: NSNumber(value: costoTotal)) ?? "0"
                        )
                        .font(.title3)
                        .bold()
                    }
                }
            }
            .navigationTitle("Nuevo Activo")
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

    private func formatInput(_ value: String) {
        let limpio = value
            .replacingOccurrences(of: ",", with: "")
            .filter { "0123456789.".contains($0) }

        if let number = Double(limpio) {
            costoUnitario = formatter.string(from: NSNumber(value: number)) ?? ""
        } else {
            costoUnitario = ""
        }
    }

    private func guardar() {

        guard let empresaSeleccionada else { return }

        let activo = ActivoEmpresa(
            articulo: articulo,
            fechaCompra: fechaCompra,
            cantidad: cantidad,
            costoUnitario: costoUnitarioDouble,
            empresa: empresaSeleccionada,
            ubicacion: ubicacionFinal
        )

        context.insert(activo)
        dismiss()
    }
}
