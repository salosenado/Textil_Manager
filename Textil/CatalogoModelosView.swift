//
//  CatalogoModelosView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//


import SwiftUI
import SwiftData

struct CatalogoModelosView: View {

    @Query(sort: \Modelo.codigo)
    private var modelos: [Modelo]

    let onSelect: (Modelo) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(modelos) { modelo in
                Button {
                    onSelect(modelo)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelo.codigo)
                            .font(.headline)

                        Text(modelo.descripcion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Catálogo de modelos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
