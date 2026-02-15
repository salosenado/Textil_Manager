//
//  LineasListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  LineasListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct LineasListView: View {

    @Query(sort: \Linea.nombre)
    private var lineas: [Linea]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(lineas) { linea in
                NavigationLink {
                    LineaFormView(
                        linea: linea,
                        esNuevo: false
                    )
                } label: {
                    Text(linea.nombre)
                }
            }
        }
        .navigationTitle("Líneas")
        .toolbar {
            Button {
                mostrarNueva = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNueva) {
            LineaFormView(
                linea: Linea(),
                esNuevo: true
            )
        }
    }
}
