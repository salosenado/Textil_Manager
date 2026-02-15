//
//  DisenoTrazoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

import SwiftUI
import SwiftData

struct DisenoTrazoView: View {

    @Environment(\.modelContext) private var context

    @Query(sort: \OrdenCliente.numeroVenta, order: .reverse)
    private var ordenes: [OrdenCliente]

    @Query
    private var controles: [ControlDisenoTrazo]

    var body: some View {

        ScrollView {
            VStack(spacing: 20) {

                ForEach(ordenes) { orden in

                    VStack(alignment: .leading, spacing: 16) {

                        // HEADER ORDEN
                        VStack(alignment: .leading, spacing: 4) {

                            Text("Venta #\(String(format: "%06d", orden.numeroVenta))")
                                .font(.headline)

                            Text(orden.cliente)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Pedido: \(orden.numeroPedidoCliente)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Entrega: \(orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        // MODELOS
                        ForEach(orden.detalles) { detalle in

                            let control = obtenerControl(for: orden, modelo: detalle.modelo)

                            VStack(alignment: .leading, spacing: 10) {

                                Text("Modelo: \(detalle.modelo)")
                                    .font(.subheadline)
                                    .bold()

                                Text("Color: \(detalle.color)  •  Talla: \(detalle.talla)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Toggle("Liberado de Diseño", isOn: Binding(
                                    get: { control.liberadoDiseno },
                                    set: { nuevoValor in
                                        control.liberadoDiseno = nuevoValor
                                        control.fechaLiberadoDiseno = nuevoValor ? Date() : nil
                                        try? context.save()
                                    }
                                ))

                                if let fecha = control.fechaLiberadoDiseno {
                                    Text("Liberado el \(fecha.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Toggle("Liberado de Trazo", isOn: Binding(
                                    get: { control.liberadoTrazo },
                                    set: { nuevoValor in
                                        control.liberadoTrazo = nuevoValor
                                        control.fechaLiberadoTrazo = nuevoValor ? Date() : nil
                                        try? context.save()
                                    }
                                ))

                                if let fecha = control.fechaLiberadoTrazo {
                                    Text("Liberado el \(fecha.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 5)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Diseño & Trazo")
    }

    private func obtenerControl(for orden: OrdenCliente, modelo: String) -> ControlDisenoTrazo {

        if let existente = controles.first(where: {
            $0.ordenNumero == orden.numeroVenta && $0.modelo == modelo
        }) {
            return existente
        }

        let nuevo = ControlDisenoTrazo(
            ordenNumero: orden.numeroVenta,
            modelo: modelo
        )

        context.insert(nuevo)
        return nuevo
    }
}
