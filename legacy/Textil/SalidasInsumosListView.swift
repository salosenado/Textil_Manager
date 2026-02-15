//
//  SalidasInsumosListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
import SwiftUI
import SwiftData

struct SalidasInsumosListView: View {

    @Query(sort: \SalidaInsumo.fecha, order: .reverse)
    private var salidas: [SalidaInsumo]

    var body: some View {
        List {

            if salidas.isEmpty {
                ContentUnavailableView(
                    "Salidas de insumos",
                    systemImage: "shippingbox",
                    description: Text(
                        "Aquí se registrarán las salidas internas, mermas y ajustes."
                    )
                )
            }

            ForEach(salidas) { salida in
                NavigationLink {
                    SalidaInsumoDetalleView(salida: salida)
                } label: {

                    VStack(alignment: .leading, spacing: 6) {

                        // FECHA
                        Text(
                            salida.fecha.formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        )
                        .font(.headline)

                        // RESPONSABLE
                        Text(
                            "Responsable: \(salida.responsable.isEmpty ? "—" : salida.responsable)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // RECIBE
                        Text(
                            "Recibe: \(salida.recibeMaterial.isEmpty ? "—" : salida.recibeMaterial)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // ESTADO
                        if salida.cancelada {
                            Text("CANCELADA")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        } else if salida.confirmada {
                            Text("CONFIRMADA")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("Salidas de Insumos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    SalidaInsumoNuevaView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SalidasInsumosListView()
    }
}
