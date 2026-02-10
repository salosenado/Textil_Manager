//
//  MaquilerosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  MaquilerosListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct MaquilerosListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Maquilero.nombre) private var maquileros: [Maquilero]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(maquileros) { maquilero in
                NavigationLink {
                    MaquileroFormView(
                        maquilero: maquilero,
                        esNuevo: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(maquilero.nombre)
                        if !maquilero.contacto.isEmpty {
                            Text(maquilero.contacto)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: eliminar)
        }
        .navigationTitle("Maquileros")
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
            MaquileroFormView(
                maquilero: Maquilero(),
                esNuevo: true
            )
        }
    }

    private func eliminar(at offsets: IndexSet) {
        for index in offsets {
            context.delete(maquileros[index])
        }
    }
}
