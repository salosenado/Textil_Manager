//
//  ProduccionCardView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//
//  ProduccionCardView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//

import SwiftUI
import SwiftData

struct ProduccionCardView: View {

    let produccion: Produccion

    // 🔴 RECEPCIONES REALES
    @Query private var recepciones: [ReciboDetalle]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {

            // MARK: - LADO IZQUIERDO
            VStack(alignment: .leading, spacing: 6) {

                filaIzq("Modelo", produccion.detalle?.modelo ?? "")
                filaIzq(
                    "Pz pedidas",
                    "\(produccion.detalle?.cantidad ?? 0)"
                )
                filaIzq(
                    "Pz enviadas",
                    "\(produccion.pzCortadas)"
                )
                filaIzq(
                    "Maquilero",
                    produccion.maquilero.isEmpty ? "Sin asignar" : produccion.maquilero
                )
                filaIzq(
                    "Pedido cliente",
                    produccion.detalle?.orden?.numeroPedidoCliente ?? ""
                )
            }

            Spacer()

            // MARK: - LADO DERECHO
            VStack(alignment: .trailing, spacing: 8) {

                // STATUS CORREGIDO ✅
                Text(statusTexto)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())

                // IVA BADGE
                Text(aplicaIVA ? "Con IVA" : "Sin IVA")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        aplicaIVA
                        ? Color.gray.opacity(0.15)
                        : Color.blue.opacity(0.15)
                    )
                    .foregroundColor(
                        aplicaIVA ? .secondary : .blue
                    )
                    .clipShape(Capsule())

                // TOTAL (NO MOSTRAR SI ESTÁ CANCELADA)
                if produccion.detalle?.orden?.cancelada != true && !produccion.cancelada {
                    Text(formatoMX(total))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 3)
    }

    // MARK: - IVA

    var aplicaIVA: Bool {
        produccion.detalle?.orden?.aplicaIVA ?? false
    }

    // MARK: - RECEPCIONES REALES 🔥

    var piezasRecibidas: Int {
        guard let detalle = produccion.detalle else { return 0 }

        return recepciones
            .filter {
                $0.detalleOrden == detalle &&
                $0.fechaEliminacion == nil
            }
            .reduce(0) { $0 + $1.pzPrimera + $1.pzSaldo }
    }

    // MARK: - STATUS FINAL (CORREGIDO)

    var statusTexto: String {

        // 🔴 CANCELADA
        if produccion.detalle?.orden?.cancelada == true || produccion.cancelada {
            return "CANCELADA"
        }

        let pedidas = produccion.detalle?.cantidad ?? 0
        let recibidas = piezasRecibidas

        // 🔵 EN PRODUCCIÓN (NO HAY RECEPCIÓN)
        if recibidas == 0 {
            return "En producción"
        }

        // 🟡 PARCIAL
        if recibidas < pedidas {
            return "Parcial"
        }

        // 🟢 COMPLETA
        return "Completa"
    }

    var statusColor: Color {

        if produccion.detalle?.orden?.cancelada == true || produccion.cancelada {
            return .red
        }

        let pedidas = produccion.detalle?.cantidad ?? 0
        let recibidas = piezasRecibidas

        if recibidas == 0 {
            return .red
        }

        if recibidas < pedidas {
            return .yellow
        }

        return .green
    }

    // MARK: - TOTALES (SIGUEN IGUAL)

    var subtotal: Double {
        Double(piezasRecibidas) * produccion.costoMaquila
    }

    var iva: Double {
        aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    // MARK: - HELPERS

    func filaIzq(_ titulo: String, _ valor: String) -> some View {
        HStack(spacing: 4) {
            Text("\(titulo):")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(valor)
                .font(.caption)
        }
    }

    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
