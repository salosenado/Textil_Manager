//
//  OrdenRowView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//

//
//  OrdenRowView.swift
//  Textil
//

import SwiftUI

struct OrdenRowView: View {

    let orden: OrdenCliente

    // 👉 ARRAY YA RESUELTO (NO LÓGICA EN EL VIEW)
    private var detalles: [OrdenClienteDetalle] {
        orden.detalles
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // CLIENTE
            Text(orden.cliente)
                .font(.headline)

            // PEDIDO
            Text("Pedido: \(orden.numeroPedidoCliente)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // MODELOS
            ForEach(detalles) { detalle in
                VStack(alignment: .leading, spacing: 2) {
                    Text(detalle.modelo)
                        .font(.subheadline)

                    Text(detalle.articulo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // TOTAL
            HStack {
                Spacer()
                Text(formatoMX(orden.total))
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - HELPERS
    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
