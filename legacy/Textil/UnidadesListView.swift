//
//  UnidadesListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  UnidadesListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct UnidadesListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Unidad.nombre) private var unidades: [Unidad]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(unidades) { unidad in
                NavigationLink {
                    UnidadFormView(
                        unidad: unidad,
                        esNueva: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(unidad.nombre)
                        if let factor = unidad.factor {
                            Text("Factor: \(factor)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: eliminar)
        }
        .navigationTitle("Unidades")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarNueva = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarNueva) {
            UnidadFormView(
                unidad: Unidad(),
                esNueva: true
            )
        }
    }

    private func eliminar(at offsets: IndexSet) {
        for index in offsets {
            context.delete(unidades[index])
        }
    }
}
