//
//  CosteoModeloCardView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CosteoModeloCardView.swift
//  Textil
//  USADO EN COSTOS MEZCLILLA
//

import SwiftUI

struct CosteoModeloCardView: View {

    let costo: CostoMezclillaEntity

    var body: some View {
        HStack(alignment: .top) {

            // MARK: - LADO IZQUIERDO
            VStack(alignment: .leading, spacing: 6) {

                Text("Modelo: \(costo.modelo)")
                    .font(.headline)

                // 👇 DESCRIPCIÓN (DEL MODELO)
                Text("Descripción: \(descripcionModelo)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(
                    "Fecha captura: \(costo.fecha.formatted(.dateTime.day().month(.abbreviated).year()))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // MARK: - LADO DERECHO (COSTO CHICO ARRIBA)
            VStack(alignment: .trailing) {
                Text(
                    costo.total,
                    format: .currency(code: "MXN")
                )
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground)) // tarjeta blanca
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    /// 🔹 Mientras Mezclilla no tenga relación al catálogo Modelo,
    /// la descripción visible ES el nombre del modelo
    private var descripcionModelo: String {
        costo.modelo
    }
}
