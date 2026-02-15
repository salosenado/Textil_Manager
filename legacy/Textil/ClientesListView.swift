//
//  ClientesListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  ClientesListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ClientesListView: View {

    @Query(sort: \Cliente.nombreComercial)
    private var clientes: [Cliente]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(clientes) { cliente in
                NavigationLink {
                    ClienteFormView(cliente: cliente, esNuevo: false)
                } label: {
                    VStack(alignment: .leading) {
                        Text(cliente.nombreComercial)
                        if !cliente.activo {
                            Text("Inactivo")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Clientes")
        .toolbar {
            Button {
                mostrarNuevo = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevo) {
            ClienteFormView(cliente: Cliente(), esNuevo: true)
        }
    }
}
