//
//  TallaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  TallaFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct TallaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var talla: Talla
    let esNueva: Bool

    @State private var ordenTexto: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Talla") {
                        TextField("Nombre (S, M, L, XL)", text: $talla.nombre)
                        Divider()
                        TextField("Orden", text: $ordenTexto)
                            .keyboardType(.numberPad)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNueva ? "Nueva talla" : "Editar talla")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        talla.orden = Int(ordenTexto) ?? 0
                        if esNueva {
                            context.insert(talla)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                ordenTexto = talla.orden == 0 ? "" : "\(talla.orden)"
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
