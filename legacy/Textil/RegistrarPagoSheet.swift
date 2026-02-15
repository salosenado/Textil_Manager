//
//  RegistrarPagoSheet.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
import SwiftUI

struct RegistrarPagoSheet: View {

    @State private var montoTexto = ""
    @State private var observaciones = ""

    let onGuardar: (Double, String) -> Void

    var montoDouble: Double {
        let limpio = montoTexto
            .replacingOccurrences(of: ",", with: ".")
        return Double(limpio) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Pago") {

                    TextField("Monto", text: $montoTexto)
                        .keyboardType(.decimalPad)

                    TextField("Observaciones", text: $observaciones)
                }
            }
            .navigationTitle("Registrar pago")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        // el padre cierra
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        onGuardar(montoDouble, observaciones)
                    }
                    .disabled(montoDouble <= 0) // 🔐 CLAVE
                }
            }
        }
    }
}
