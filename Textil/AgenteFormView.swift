//
//  AgenteFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI
import SwiftData

struct AgenteFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var agente: Agente
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Agente") {
                        TextField("Nombre", text: $agente.nombre)
                        Divider()
                        TextField("Apellido", text: $agente.apellido)
                    }

                    FormSection(title: "Comisión") {
                        TextField("Porcentaje %", text: $agente.comision)
                            .keyboardType(.decimalPad)
                    }

                    FormSection(title: "Contacto") {
                        TextField("Teléfono", text: $agente.telefono)
                        Divider()
                        TextField("Email", text: $agente.email)
                            .keyboardType(.emailAddress)
                    }

                    FormSection(title: "") {
                        Toggle("Activo", isOn: $agente.activo)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGray6))
            .navigationTitle(esNuevo ? "Nuevo agente" : "Editar agente")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(agente)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AgenteFormView(
        agente: Agente(),
        esNuevo: true
    )
}
