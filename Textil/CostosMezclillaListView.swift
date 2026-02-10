//
//  CostosMezclillaListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//  CostoMezclillaDetalleView.swift
//  Textil
//
//
//  CostosMezclillaListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CostosMezclillaListView: View {

    @Query(sort: \CostoMezclillaEntity.fecha, order: .reverse)
    private var costos: [CostoMezclillaEntity]

    @State private var mostrarAlta = false

    var body: some View {
        NavigationStack {
            List {

                if costos.isEmpty {
                    ContentUnavailableView(
                        "Sin costos de mezclilla",
                        systemImage: "tray",
                        description: Text("Agrega tu primer costo")
                    )
                    .listRowBackground(Color.clear)
                }

                ForEach(costos) { costo in
                    NavigationLink {
                        CostoMezclillaDetalleView(costo: costo)
                    } label: {
                        CosteoModeloCardView(costo: costo)
                    }
                    .listRowSeparator(.hidden)          // ❌ líneas
                    .listRowBackground(Color.clear)     // ❌ fondo blanco de List
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)        // 👈 CLAVE
            .background(Color(.systemGroupedBackground)) // 🩶 FONDO GRIS
            .navigationTitle("Mezclilla")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarAlta = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarAlta) {
                NavigationStack {
                    AltaCostoMezclillaView()
                }
            }
        }
    }
}
