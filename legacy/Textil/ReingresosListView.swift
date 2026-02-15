//
//  ReingresosListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.

//  ReingresosListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
import SwiftUI
import SwiftData

struct ReingresosListView: View {

    @Query(sort: \Reingreso.fecha, order: .reverse)
    private var reingresos: [Reingreso]

    var body: some View {
        List {

            if reingresos.isEmpty {
                ContentUnavailableView(
                    "Reingresos",
                    systemImage: "tray.and.arrow.down",
                    description: Text(
                        "Aquí se registran reingresos de producto, insumo o servicio."
                    )
                )
            }

            ForEach(reingresos) { reingreso in
                NavigationLink {

                    ReingresoDetalleView(reingreso: reingreso)

                } label: {

                    VStack(alignment: .leading, spacing: 8) {

                        // FECHA + FOLIO
                        HStack {
                            Text(
                                reingreso.fecha.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                            .font(.headline)

                            Spacer()

                            Text(reingreso.folio)
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                        }

                        // RESPONSABLE
                        Text(
                            "Responsable: \(reingreso.responsable.isEmpty ? "—" : reingreso.responsable)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // RECIBE
                        Text(
                            "Recibe: \(reingreso.recibeMaterial.isEmpty ? "—" : reingreso.recibeMaterial)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        // ESTADO
                        if reingreso.cancelado {
                            estado("CANCELADO", .red)
                        } else if reingreso.confirmado {
                            estado("CONFIRMADO", .green)
                        } else {
                            estado("BORRADOR", .orange)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(.systemBackground))  // 🔑 asegura fondo legible
                    .cornerRadius(12)
                }
            }
        }
        .navigationTitle("Reingresos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ReingresoNuevoView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - UI HELPERS
    func estado(_ texto: String, _ color: Color) -> some View {
        Text(texto)
            .font(.caption.bold())
            .foregroundStyle(color)
    }
}
