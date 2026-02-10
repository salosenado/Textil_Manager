//
//  UnidadFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  UnidadFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct UnidadFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var unidad: Unidad
    let esNueva: Bool

    @State private var factorTexto: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Unidad") {
                        TextField("Nombre", text: $unidad.nombre)
                        Divider()
                        TextField("Abreviatura", text: $unidad.abreviatura)
                        Divider()

                        HStack {
                            Text("Factor")
                            Spacer()

                            TextField(
                                "Ej. 1, 0.001, 1000",
                                text: $factorTexto
                            )
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 120)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNueva ? "Nueva unidad" : "Editar unidad")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        guardarFactor()
                        if esNueva {
                            context.insert(unidad)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let factor = unidad.factor {
                    factorTexto = String(factor)
                }
            }
        }
    }

    private func guardarFactor() {
        let limpio = factorTexto
            .replacingOccurrences(of: ",", with: "")

        unidad.factor = Double(limpio)
    }
}
