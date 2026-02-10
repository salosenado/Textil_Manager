//
//  ModelosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ModelosListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ModelosListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Modelo.nombre) private var modelos: [Modelo]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(modelos) { modelo in
                NavigationLink {
                    ModeloFormView(
                        modelo: modelo,
                        esNuevo: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(modelo.nombre)
                            .fontWeight(.medium)
                        if !modelo.codigo.isEmpty {
                            Text(modelo.codigo)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: eliminar)
        }
        .navigationTitle("Modelos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarNuevo = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarNuevo) {
            ModeloFormView(
                modelo: Modelo(),
                esNuevo: true
            )
        }
    }

    private func eliminar(at offsets: IndexSet) {
        for index in offsets {
            context.delete(modelos[index])
        }
    }
}

#Preview {
    NavigationStack {
        ModelosListView()
    }
}
