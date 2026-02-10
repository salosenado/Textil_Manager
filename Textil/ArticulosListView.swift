//
//  ArticulosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ArticulosListView.swift
//  Textil
//
import SwiftUI
import SwiftData

struct ArticulosListView: View {

    @Query(sort: \Articulo.nombre)
    private var articulos: [Articulo]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(articulos) { articulo in
                NavigationLink {
                    ArticuloFormView(
                        articulo: articulo,
                        esNuevo: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(articulo.nombre)
                        if !articulo.sku.isEmpty {
                            Text(articulo.sku)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Artículos")
        .toolbar {
            Button {
                mostrarNuevo = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevo) {
            ArticuloFormView(
                articulo: Articulo(),
                esNuevo: true
            )
        }
    }
}
