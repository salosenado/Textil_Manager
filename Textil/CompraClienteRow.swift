//
//  CompraClienteRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
//
//  CompraClienteRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
//
//  CompraClienteRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import SwiftUI

struct CompraClienteRow: View {

    let compra: CompraCliente

    // MARK: - Cálculos reales (basados en CompraClienteDetalle)

    private var subtotalCompra: Double {
        var total: Double = 0
        for d in compra.detalles {
            total += d.subtotal
        }
        return total
    }

    private var estado: EstadoCompraCliente {
        subtotalCompra > 0 ? .completa : .pendiente
    }

    // MARK: - Fechas

    private var fechaCreacionTexto: String {
        compra.fechaCreacion.formatted(date: .abbreviated, time: .omitted)
    }

    private var fechaRecepcionTexto: String {
        compra.fechaRecepcion.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - BODY

    var body: some View {
        VStack(spacing: 12) {

            HStack(alignment: .top) {

                // IZQUIERDA
                VStack(alignment: .leading, spacing: 4) {

                    Text("Proveedor: \(compra.proveedorCliente)")
                        .font(.headline)

                    Text("Compra #\(compra.numeroCompra)")
                        .foregroundStyle(.secondary)

                    Text(
                        "Subtotal: \(subtotalCompra.formatted(.currency(code: "MXN")))"
                    )
                    .font(.subheadline)
                }

                Spacer()

                // DERECHA
                VStack(alignment: .trailing, spacing: 6) {

                    estadoBadge

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Creada: \(fechaCreacionTexto)")
                        Text("Recepción: \(fechaRecepcionTexto)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray5))
        )
    }

    // MARK: - Badge

    private var estadoBadge: some View {
        Text(estado.titulo)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(estado.color.opacity(0.15))
            .foregroundStyle(estado.color)
            .clipShape(Capsule())
    }
}

// MARK: - Estado Compra Cliente

enum EstadoCompraCliente {
    case pendiente
    case completa

    var titulo: String {
        switch self {
        case .pendiente: return "PENDIENTE"
        case .completa: return "COMPLETA"
        }
    }

    var color: Color {
        switch self {
        case .pendiente: return .orange
        case .completa: return .green
        }
    }
}
