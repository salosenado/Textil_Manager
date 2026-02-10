//
//  MarcasListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  MarcasListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct MarcasListView: View {

    @Query(sort: \Marca.nombre)
    private var marcas: [Marca]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(marcas) { marca in
                NavigationLink {
                    MarcaFormView(
                        marca: marca,
                        esNuevo: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(marca.nombre)
                        if !marca.dueno.isEmpty {
                            Text(marca.dueno)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Marcas")
        .toolbar {
            Button {
                mostrarNueva = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNueva) {
            MarcaFormView(
                marca: Marca(),
                esNuevo: true
            )
        }
    }
}
