//
//  TallaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
import SwiftUI
import SwiftData

struct TallaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var talla: Talla
    let esNueva: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Talla") {
                        TextField("Nombre (S, M, L, XL)", text: $talla.nombre)
                            .textInputAutocapitalization(.characters)
                        Divider()
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .navigationTitle(esNueva ? "Nueva talla" : "Editar talla")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {

                        talla.nombre = talla.nombre
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .uppercased()

                        if esNueva {
                            context.insert(talla)
                        }

                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        talla.nombre
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .isEmpty
                    )
                }
            }
        }
    }
}

#Preview {
    TallaFormView(
        talla: Talla(),
        esNueva: true
    )
}
