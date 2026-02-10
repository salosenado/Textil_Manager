//
//  ResumenMaquileroCard.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ResumenMaquileroCard.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import SwiftUI

struct ResumenMaquileroCard: View {

    let resumen: ResumenMaquilero

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // 👤 Maquilero
            Text("Maquilero: \(resumen.maquilero)")
                .font(.headline)

            // 📦 Órdenes
            fila("Órdenes totales", resumen.ordenesPedidas)

            fila(
                "Órdenes activas",
                resumen.ordenesPedidas - resumen.ordenesEntregadas
            )

            fila(
                "Órdenes cerradas",
                resumen.ordenesEntregadas
            )

            // 🔢 Piezas
            fila("Pzas pedidas", resumen.pzPedidas)
            fila("Pzas recibidas", resumen.pzRecibidas)

            Divider()

            // 💰 Pagos
            filaMoneda("Pagado", resumen.pagado, .green)
            filaMoneda("Pendiente", resumen.pendiente, .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 2)
    }

    // MARK: - Helpers
    func fila(_ titulo: String, _ valor: Int) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text("\(valor)")
                .foregroundStyle(.secondary)
        }
    }

    func filaMoneda(_ titulo: String, _ valor: Double, _ color: Color) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor, format: .currency(code: "MXN"))
                .foregroundStyle(color)
        }
    }
}
