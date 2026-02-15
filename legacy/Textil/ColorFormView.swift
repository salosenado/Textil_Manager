//
//  ColorFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  ColorFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ColorFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var color: ColorModelo
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // COLOR
                    FormSection(title: "Color") {
                        TextField("Nombre del color", text: $color.nombre)
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $color.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(esNuevo ? "Nuevo color" : "Editar color")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(color)
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
    ColorFormView(color: ColorModelo(), esNuevo: true)
}
