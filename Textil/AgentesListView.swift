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

            ForEach(agentes) { agente in
                NavigationLink {
                    AgenteFormView(
                        agente: agente,
                        esNuevo: false
                    )
                } label: {

                    VStack(alignment: .leading, spacing: 6) {

                        Text("\(agente.nombre) \(agente.apellido)")
                            .font(.headline)

                        if !agente.comision.isEmpty {
                            Text("Porcentaje: \(agente.comision)%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 3)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .listStyle(.plain)
        .navigationTitle("Agentes")
        .toolbar {

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarNuevo = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
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
