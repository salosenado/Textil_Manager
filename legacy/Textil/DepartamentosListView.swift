//
//  DepartamentosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI
import SwiftData

struct DepartamentosListView: View {

    @Query private var departamentos: [Departamento]
    @State private var mostrarAlta = false

    var body: some View {
        List {
            ForEach(departamentos) { dep in
                VStack(alignment: .leading) {
                    Text(dep.nombre)
                    if !dep.activo {
                        Text("Inactivo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Departamentos")
        .toolbar {
            Button {
                mostrarAlta = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $mostrarAlta) {
            NavigationStack {
                AltaDepartamentoView()
            }
        }
    }
}
