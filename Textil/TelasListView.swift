//
//  TelasListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  TelasListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct TelasListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Tela.nombre) private var telas: [Tela]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(telas) { tela in
                NavigationLink {
                    TelaFormView(
                        tela: tela,
                        esNueva: false
                    )
                } label: {
                    VStack(alignment: .leading) {
                        Text(tela.nombre)
                        if let ultimo = tela.precios.sorted(by: { $0.fecha > $1.fecha }).first {
                            Text("Último precio: MX $\(ultimo.precio, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: eliminar)
        }
        .navigationTitle("Telas")
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
            TelaFormView(
                tela: Tela(),
                esNueva: true
            )
        }
    }

    private func eliminar(at offsets: IndexSet) {
        for index in offsets {
            context.delete(telas[index])
        }
    }
}
