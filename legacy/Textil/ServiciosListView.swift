//
//  ServiciosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ServiciosListView.swift
//  ProduccionTextilClean
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ServiciosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

struct ServiciosListView: View {

    // MARK: - DATA
    @Query(sort: \Servicio.nombre)
    private var servicios: [Servicio]

    // MARK: - UI STATE
    @State private var mostrarNuevo = false
    @State private var servicioEditar: Servicio?

    var body: some View {
        NavigationStack {
            List {

                if servicios.isEmpty {
                    ContentUnavailableView(
                        "Sin servicios",
                        systemImage: "wrench.and.screwdriver",
                        description: Text("Agrega tu primer servicio")
                    )
                } else {

                    ForEach(servicios, id: \.self) { servicio in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {

                                // NOMBRE
                                Text(servicio.nombre)
                                    .font(.headline)

                                // PLAZO (SOLO SI > 0)
                                if servicio.plazoPagoDias > 0 {
                                    Text("Plazo de pago: \(servicio.plazoPagoDias) días")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            // ESTADO
                            Circle()
                                .fill(servicio.activo ? .green : .red)
                                .frame(width: 10, height: 10)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            servicioEditar = servicio
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)          // ← ESTA
            .background(Color(.systemBackground))  
            .navigationTitle("Servicios")
            .toolbar {

                // ➕ NUEVO SERVICIO
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarNuevo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // NUEVO
            .sheet(isPresented: $mostrarNuevo) {
                ServicioFormView()
            }

            // EDITAR
            .sheet(item: $servicioEditar) { servicio in
                ServicioFormView(servicio: servicio)
            }
        }
    }
}
