//
//  RegistrarRecepcionCompraSheet.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//


import SwiftUI

struct RegistrarRecepcionCompraSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var monto: String = ""
    @State private var observaciones: String = ""

    let onGuardar: (Double, String) -> Void

    var body: some View {
        NavigationStack {
            Form {

                Section("Recepción") {

                    TextField("Cantidad recibida", text: $monto)
                        .keyboardType(.decimalPad)

                    TextField(
                        "Observaciones",
                        text: $observaciones,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Registrar recepción")
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onGuardar(
                            Double(monto) ?? 0,
                            observaciones
                        )
                        dismiss()
                    }
                    .disabled((Double(monto) ?? 0) <= 0)
                }
            }
        }
    }
}
