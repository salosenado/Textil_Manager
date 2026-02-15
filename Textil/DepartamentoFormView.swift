//
//  DepartamentoFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  DepartamentoFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct DepartamentoFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var departamento: Departamento
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // DEPARTAMENTO
                    FormSection(title: "Departamento") {
                        TextField(
                            "Nombre (Dama, Caballero...)",
                            text: $departamento.nombre
                        )
                        Divider()
                        TextField("Descripción", text: $departamento.descripcion)
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $departamento.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(
                esNuevo ? "Nuevo departamento" : "Editar departamento"
            )
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(departamento)
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
    DepartamentoFormView(
        departamento: Departamento(),
        esNuevo: true
    )
}
