//
//  ArticuloFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
////
//  ArticuloFormView.swift
//  Textil
//
//
//  ArticuloFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ArticuloFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var articulo: Articulo
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ARTÍCULO
                    FormSection(title: "Artículo") {
                        TextField("Nombre", text: $articulo.nombre)
                        Divider()
                        TextField("SKU", text: $articulo.sku)
                        Divider()
                        TextField("Descripción", text: $articulo.descripcion)
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $articulo.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(esNuevo ? "Nuevo artículo" : "Editar artículo")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(articulo)
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
    ArticuloFormView(
        articulo: Articulo(),
        esNuevo: true
    )
}
