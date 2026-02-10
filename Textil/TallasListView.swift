//
//  TallasListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  TallasListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct TallasListView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Talla.orden) private var tallas: [Talla]

    @State private var mostrarNueva = false

    var body: some View {
        List {
            ForEach(tallas) { talla in
                NavigationLink {
                    TallaFormView(
                        talla: talla,
                        esNueva: false
                    )
                } label: {
                    HStack {
                        Text(talla.nombre)
                        Spacer()
                        Text("\(talla.orden)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: eliminar)
        }
        .navigationTitle("Tallas")
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
            TallaFormView(
                talla: Talla(),
                esNueva: true
            )
        }
    }

    private func eliminar(at offsets: IndexSet) {
        for index in offsets {
            context.delete(tallas[index])
        }
    }
}

#Preview {
    NavigationStack {
        TallasListView()
    }
}
