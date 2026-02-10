//
//  CostoGeneralCardView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI

struct CosteoGeneralCardView: View {

    let costo: CostoGeneralEntity

    var body: some View {
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}
