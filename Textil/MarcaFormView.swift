//
//  MarcaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  MarcaFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct MarcaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var marca: Marca
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARCA
                    FormSection(title: "Marca") {
                        TextField("Nombre", text: $marca.nombre)
                        Divider()
                        TextField("Descripción", text: $marca.descripcion)
                    }

                    // REGALÍAS
                    FormSection(title: "Regalías") {
                        TextField("Dueño", text: $marca.dueno)
                        Divider()
                        HStack {
                            Text("Regalías %")
                                .foregroundColor(.secondary)
                            Spacer()
                            TextField("0", text: $marca.regaliaPorcentaje)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $marca.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNuevo ? "Nueva marca" : "Editar marca")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(marca)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
