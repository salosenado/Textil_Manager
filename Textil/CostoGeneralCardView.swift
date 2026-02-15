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
            VStack(alignment: .leading, spacing: 8) {

                Text("Modelo: \(costo.modelo)")
                    .font(.title3.bold())

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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal)
        .padding(.vertical, 6)

    }
}
