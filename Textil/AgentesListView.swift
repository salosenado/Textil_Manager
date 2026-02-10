//
//  AgentesListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  AgentesListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct AgentesListView: View {

    @Query(sort: \Agente.nombre)
    private var agentes: [Agente]

    @State private var mostrarNuevo = false

    var body: some View {
        List {

            // LISTA DE AGENTES
            ForEach(agentes) { agente in
                NavigationLink {
                    AgenteFormView(
                        agente: agente,
                        esNuevo: false
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(agente.nombre) \(agente.apellido)")
                            .font(.body)

                        if !agente.comision.isEmpty {
                            Text("Porcentaje: \(agente.comision)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Agentes")
        .toolbar {

            // BOTÓN +
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarNuevo = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // NUEVO AGENTE
        .sheet(isPresented: $mostrarNuevo) {
            NavigationStack {
                AgenteFormView(
                    agente: Agente(),
                    esNuevo: true
                )
            }
        }
    }
}
