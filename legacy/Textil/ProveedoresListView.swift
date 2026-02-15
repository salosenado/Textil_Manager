//
//  ProveedoresListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  ProveedoresListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ProveedoresListView: View {

    @Query(sort: \Proveedor.nombre)
    private var proveedores: [Proveedor]

    @State private var mostrarNuevo = false

    var body: some View {
        List {
            ForEach(proveedores) { proveedor in
                NavigationLink {
                    ProveedorFormView(proveedor: proveedor, esNuevo: false)
                } label: {
                    VStack(alignment: .leading) {
                        Text(proveedor.nombre)
                        if !proveedor.activo {
                            Text("Inactivo")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Proveedores")
        .toolbar {
            Button {
                mostrarNuevo = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNuevo) {
            ProveedorFormView(proveedor: Proveedor(), esNuevo: true)
        }
    }
}
