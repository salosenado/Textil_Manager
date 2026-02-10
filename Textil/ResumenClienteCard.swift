//
//  ResumenClienteCard.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//


//
//  ResumenClienteCard.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import SwiftUI

struct ResumenClienteCard: View {

    let resumen: ResumenCliente

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // 👤 Proveedor / Cliente
            Text("Proveedor: \(resumen.proveedor)")
                .font(.headline)

            // 📦 Órdenes
            fila("Órdenes totales", resumen.ordenes)

            Divider()

            // 💰 Montos
            filaMoneda("Monto total", resumen.monto, .green)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 2)
    }

    // MARK: - Helpers

    private func fila(_ titulo: String, _ valor: Int) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text("\(valor)")
                .foregroundStyle(.secondary)
        }
    }

    private func filaMoneda(_ titulo: String, _ valor: Double, _ color: Color) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor, format: .currency(code: "MXN"))
                .foregroundStyle(color)
        }
    }
}
