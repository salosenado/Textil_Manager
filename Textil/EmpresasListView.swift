//
//  EmpresasListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  EmpresasListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct EmpresasListView: View {

    @Query(sort: \Empresa.nombre)
    private var empresas: [Empresa]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(empresas) { empresa in
                NavigationLink {
                    EmpresaFormView(empresa: empresa, esNueva: false)
                } label: {
                    VStack(alignment: .leading) {
                        Text(empresa.nombre)
                        if !empresa.activo {
                            Text("Inactiva")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .navigationTitle("Empresas")
        .toolbar {
            Button {
                mostrarNueva = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarNueva) {
            EmpresaFormView(empresa: Empresa(), esNueva: true)
        }
    }
}
