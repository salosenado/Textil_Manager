//
//  AgenteFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  AgenteFormView.swift
//  Textil
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

                    // AGENTE
                    FormSection(title: "Agente") {
                        TextField("Nombre", text: $agente.nombre)
                        Divider()
                        TextField("Apellido", text: $agente.apellido)
                    }

                    // COMISIÓN
                    FormSection(title: "Comisión") {
                        HStack {
                            Text("Porcentaje %")
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("0", text: $agente.comision)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    // CONTACTO
                    FormSection(title: "Contacto") {
                        TextField("Teléfono", text: $agente.telefono)
                        Divider()
                        TextField("Email", text: $agente.email)
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $agente.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNuevo ? "Nuevo agente" : "Editar agente")
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
