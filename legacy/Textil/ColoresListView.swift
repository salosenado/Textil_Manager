//
//  ColoresListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  ColoresListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ColoresListView: View {

    @Query(sort: \ColorModelo.nombre)
    private var colores: [ColorModelo]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(colores) { color in
                NavigationLink {
                    ColorFormView(color: color, esNuevo: false)
                } label: {
                    Text(color.nombre)
                }
            }
        }
        .navigationTitle("Colores")
        .toolbar {
            Button {
                mostrarNuevo = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevo) {
            ColorFormView(color: ColorModelo(), esNuevo: true)
        }
    }
}
