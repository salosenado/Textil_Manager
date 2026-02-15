//
//  CostosGeneralListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CostosGeneralListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CostosGeneralListView: View {

    // MARK: - Datos
    @Query(sort: \CostoGeneralEntity.fecha, order: .reverse)
    private var costos: [CostoGeneralEntity]

    // MARK: - UI State
    @State private var mostrarAlta = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {

                    if costos.isEmpty {
                        ContentUnavailableView(
                            "Sin costos generales",
                            systemImage: "tray",
                            description: Text("Agrega tu primer costo")
                        )
                        .padding(.top, 60)
                    }

                    ForEach(costos) { costo in
                        NavigationLink {
                            CostoGeneralDetalleView(costo: costo)
                        } label: {

                            // MARK: - TARJETA (IGUAL A MEZCLILLA)
                            HStack(alignment: .top) {

                                // IZQUIERDA
                                VStack(alignment: .leading, spacing: 6) {

                                    Text("Modelo: \(costo.modelo)")
                                        .font(.headline)

                                    if !costo.descripcion.isEmpty {
                                        Text("Descripción: \(costo.descripcion)")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }

                                    Text(
                                        "Fecha captura: \(costo.fecha.formatted(.dateTime.day().month(.abbreviated).year()))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // DERECHA — COSTO CHICO ARRIBA
                                VStack(alignment: .trailing) {
                                    Text(
                                        costo.totalConGastos,
                                        format: .currency(code: "MXN")
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground)) // fondo gris
            }
            .navigationTitle("Costos Generales")

            // MARK: - BOTÓN ➕
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarAlta = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }

            // MARK: - ALTA
            .sheet(isPresented: $mostrarAlta) {
                NavigationStack {
                    AltaCostoGeneralView()
                }
            }
        }
    }
}
