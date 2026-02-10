//
//  LineaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  LineaFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct LineaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var linea: Linea
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "") {
                        TextField("Nombre de la línea", text: $linea.nombre)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNuevo ? "Nueva línea" : "Editar línea")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(linea)
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
    LineaFormView(
        linea: Linea(),
        esNuevo: true
    )
}
