//
//  OrdenClienteDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI

struct OrdenClienteDetalleView: View {

    // 🔑 AHORA RECIBE EL DETALLE REAL
    let detalle: OrdenClienteDetalle

    // MARK: - DATOS DERIVADOS

    var clienteNombre: String {
        detalle.orden?.cliente ?? ""
    }

    var pedido: String {
        detalle.orden?.numeroPedidoCliente ?? ""
    }

    var fechaCreacion: Date {
        detalle.orden?.fechaCreacion ?? Date()
    }

    var sinIVA: Bool {
        !(detalle.orden?.aplicaIVA ?? false)
    }

    var plazoCliente: Int? {
        // 🔒 AÚN NO EXISTE clienteCatalogo EN EL MODELO
        nil
    }

    var descripcionModelo: String? {
        detalle.modeloCatalogo?.descripcion
    }

    var subtotal: Double {
        detalle.subtotal
    }

    var iva: Double {
        sinIVA ? 0 : subtotal * 0.16
    }

    var total: Double {
        sinIVA ? subtotal : subtotal + iva
    }

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - RESUMEN ORDEN
                VStack(spacing: 12) {

                    HStack {
                        Text(clienteNombre)
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Text(formatoMX(total))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }

                    HStack {
                        Text("Pedido: \(pedido)")
                        Spacer()
                        if sinIVA {
                            Text("SIN IVA")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(
                        "Creado: \(fechaCreacion.formatted(.dateTime.day().month(.abbreviated).year()))"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // MARK: - PLAZO CLIENTE
                if let plazo = plazoCliente {
                    Text("Plazo del cliente: \(plazo) días")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // MARK: - PRODUCTO
                VStack(spacing: 12) {

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Modelo \(detalle.modelo)")
                                .font(.subheadline)

                            Text("Cantidad: \(detalle.cantidad) \(detalle.unidad)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatoMX(subtotal))
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // MARK: - DESCRIPCIÓN MODELO
                if let descripcion = descripcionModelo, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // MARK: - TOTALES
                VStack(spacing: 12) {

                    fila("Subtotal", subtotal)
                    fila("IVA (16%)", iva)

                    Divider()

                    fila("Total", total, destacado: true)
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle orden")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - HELPERS

    func fila(
        _ titulo: String,
        _ valor: Double,
        destacado: Bool = false
    ) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(formatoMX(valor))
                .fontWeight(destacado ? .bold : .regular)
                .foregroundStyle(destacado ? .green : .primary)
        }
    }

    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
