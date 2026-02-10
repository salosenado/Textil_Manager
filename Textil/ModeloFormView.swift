//
//  ModeloFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

//
//  ModeloFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ModeloFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var modelo: Modelo
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Modelo") {
                        TextField("Nombre", text: $modelo.nombre)
                        Divider()
                        TextField("Código", text: $modelo.codigo)
                        Divider()
                        TextField("Descripción", text: $modelo.descripcion, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNuevo ? "Nuevo modelo" : "Editar modelo")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(modelo)
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
    ModeloFormView(
        modelo: Modelo(),
        esNuevo: true
    )
}
