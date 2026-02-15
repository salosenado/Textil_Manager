//
//  ProduccionRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ProduccionRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

//
//  ProduccionRow.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import SwiftUI

struct ProduccionRow: View {

    let produccion: Produccion

    // MARK: - Cálculos SEPARADOS (ANTI TYPE-CHECK ERROR)

    private var piezasPedidas: Int {
        produccion.pzCortadas
    }

    private var recibosValidos: [ReciboProduccion] {
        produccion.recibos.filter { !$0.cancelado }
    }

    private var detallesValidos: [ReciboDetalle] {
        recibosValidos
            .flatMap { $0.detalles }
            .filter { $0.fechaEliminacion == nil }
    }

    private var piezasRecibidas: Int {
        var total = 0
        for d in detallesValidos {
            total += d.pzPrimera + d.pzSaldo
        }
        return total
    }

    private var porcentajeRecibido: Double {
        guard piezasPedidas > 0 else { return 0 }
        let valor = Double(piezasRecibidas) / Double(piezasPedidas)
        return min(valor, 1.0)
    }

    private var estado: EstadoOrden {
        if produccion.cancelada {
            return .cancelada
        } else if porcentajeRecibido >= 0.95 {
            return .completa
        } else if piezasRecibidas > 0 {
            return .parcial
        } else {
            return .pendiente
        }
    }

    // MARK: - Fechas

    private var fechaCreacion: Date? {
        produccion.fechaOrdenMaquila
    }

    private var fechaRecepcion: Date? {
        let ordenados = recibosValidos.sorted { $0.fechaRecibo > $1.fechaRecibo }
        return ordenados.first?.fechaRecibo
    }

    private var fechaCreacionTexto: String {
        guard let fecha = fechaCreacion else { return "—" }
        return fecha.formatted(date: .abbreviated, time: .omitted)
    }

    private var fechaRecepcionTexto: String {
        guard let fecha = fechaRecepcion else { return "—" }
        return fecha.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Días en producción

    private var diasProduccionTexto: String {
        guard let inicio = fechaCreacion else { return "—" }

        let fin: Date = (estado == .completa && fechaRecepcion != nil)
            ? fechaRecepcion!
            : Date()

        let dias = Calendar.current.dateComponents([.day], from: inicio, to: fin).day ?? 0
        return "\(max(dias, 0)) días"
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 12) {

            HStack(alignment: .top) {

                // IZQUIERDA
                VStack(alignment: .leading, spacing: 4) {

                    Text("Maquilero: \(produccion.maquilero.isEmpty ? "—" : produccion.maquilero)")
                        .font(.headline)

                    Text("Orden: \(produccion.ordenMaquila ?? "—")")
                        .foregroundStyle(.secondary)

                    Text("Pz pedidas: \(piezasPedidas)")
                        .font(.subheadline)

                    Text("Pz recibidas: \(piezasRecibidas)")
                        .font(.subheadline)
                }

                Spacer()

                // DERECHA
                VStack(alignment: .trailing, spacing: 6) {

                    estadoBadge

                    Text("\(Int(porcentajeRecibido * 100))% recibido")
                        .font(.caption)
                        .foregroundStyle(estado.color)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Creada: \(fechaCreacionTexto)")
                        Text("Recibida: \(fechaRecepcionTexto)")
                        Text(diasProduccionTexto)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            // BARRA DE PROGRESO
            ProgressView(value: porcentajeRecibido)
                .progressViewStyle(
                    LinearProgressViewStyle(tint: estado.color)
                )
                .scaleEffect(x: 1, y: 2)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.systemGray5))
        )
    }

    // MARK: - Estado badge

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

// MARK: - Estado Orden

enum EstadoOrden {
    case pendiente
    case parcial
    case completa
    case cancelada

    var titulo: String {
        switch self {
        case .pendiente: return "PENDIENTE"
        case .parcial:   return "PARCIAL"
        case .completa:  return "COMPLETA"
        case .cancelada: return "CANCELADA"
        }
    }

    var color: Color {
        switch self {
        case .pendiente: return .blue
        case .parcial:   return .yellow
        case .completa:  return .green
        case .cancelada: return .red
        }
    }
}
