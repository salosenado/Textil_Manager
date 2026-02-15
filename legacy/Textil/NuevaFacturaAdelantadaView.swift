//
//  NuevaFacturaAdelantadaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//

import SwiftUI
import SwiftData

struct NuevaFacturaAdelantadaView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Empresa> { $0.activo == true })
    private var empresasActivas: [Empresa]

    @State private var numeroFactura = ""
    @State private var empresaSeleccionada: Empresa?
    @State private var empresaAcreedora = ""
    @State private var dueno = ""
    @State private var contacto = ""
    @State private var email = ""
    @State private var telefono = ""
    @State private var subtotal: Double = 0

    var body: some View {

        NavigationStack {

            Form {

                // 🔹 DATOS GENERALES
                Section("Datos Generales") {

                    TextField("Número de Factura", text: $numeroFactura)

                    Picker("Empresa Deudora", selection: $empresaSeleccionada) {
                        ForEach(empresasActivas) { empresa in
                            Text(empresa.nombre).tag(Optional(empresa))
                        }
                    }

                    TextField("Empresa Acreedora", text: $empresaAcreedora)
                }

                // 🔹 CONTACTO
                Section("Información de Contacto") {

                    TextField("Dueño", text: $dueno)
                    TextField("Contacto", text: $contacto)
                    TextField("Email", text: $email)
                    TextField("Teléfono", text: $telefono)
                }

                // 🔹 FINANCIERO
                Section("Información Financiera") {

                    // 🔹 Subtotal con MX$ fijo y 0 en gris
                    HStack {
                        Text("Subtotal")
                        Spacer()

                        HStack(spacing: 4) {

                            Text("MX$")
                                .foregroundColor(.secondary)

                            TextField("0.00", value: $subtotal, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(subtotal == 0 ? .gray.opacity(0.6) : .primary)
                        }
                        .frame(width: 150)
                    }

                    HStack {
                        Text("IVA 16%")
                        Spacer()
                        Text(formatoMoneda(subtotal * 0.16))
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatoMoneda(subtotal * 1.16))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Nueva Factura")
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {

                        guard let empresa = empresaSeleccionada else { return }

                        let nuevaFactura = SaldoFacturaAdelantada(
                            numeroFactura: numeroFactura,
                            empresaNombre: empresa.nombre,
                            empresaAcreedor: empresaAcreedora,
                            dueno: dueno,
                            contacto: contacto,
                            email: email,
                            telefono: telefono,
                            subtotal: subtotal
                        )

                        context.insert(nuevaFactura)
                        try? context.save()
                        dismiss()
                    }
                }
            }
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
