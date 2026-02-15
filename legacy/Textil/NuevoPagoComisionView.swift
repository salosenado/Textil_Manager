//
//  NuevoPagoComisionView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftUI
import SwiftData

struct NuevoPagoComisionView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let agente: Agente

    @State private var monto = ""
    @State private var password = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Monto") {
                    HStack {
                        Text("MX$")
                        TextField("0.00", text: $monto)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Contraseña") {
                    SecureField("Contraseña", text: $password)
                }
            }
            .navigationTitle("Nuevo Pago")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardar()
                    }
                }
            }
        }
    }

    func guardar() {

        guard password == "1234",
              let montoDouble = Double(monto),
              montoDouble > 0 else { return }

        let pago = PagoComision(
            monto: montoDouble,
            agente: agente
        )

        context.insert(pago)
        try? context.save()

        dismiss()
    }
}
