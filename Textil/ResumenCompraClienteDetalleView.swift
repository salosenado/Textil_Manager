//
//  ResumenCompraClienteDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
//
//  ResumenCompraClienteDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import SwiftUI
import SwiftData

struct ResumenCompraClienteDetalleView: View {

    let compra: CompraCliente
    @Environment(\.dismiss) private var dismiss

    // MARK: - TOTALES REALES

    private var subtotalTotal: Double {
        compra.detalles.reduce(0) { total, d in
            total + d.subtotal
        }
    }

    // MARK: - BODY

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                header

                // =========================
                // DATOS DE LA COMPRA
                // =========================
                sectionTitle("Compra")
                whiteCard {
                    fila("Proveedor", compra.proveedorCliente)
                    fila("Número de compra", "\(compra.numeroCompra)")
                    fila("Fecha creación", formatearFecha(compra.fechaCreacion))
                    fila("Fecha recepción", formatearFecha(compra.fechaRecepcion))
                    fila("IVA", compra.aplicaIVA ? "Aplica" : "No aplica")
                    fila("Observaciones", compra.observaciones.isEmpty ? "—" : compra.observaciones)
                }

                // =========================
                // DETALLES
                // =========================
                sectionTitle("Detalles")
                ForEach(compra.detalles) { d in
                    whiteCard {
                        Text(d.articulo)
                            .font(.headline)

                        Text("Modelo: \(d.modelo)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        fila("Línea", d.linea)
                        fila("Color", d.color)
                        fila("Talla", d.talla)
                        fila("Unidad", d.unidad)
                        fila("Cantidad", "\(d.cantidad)")
                        fila(
                            "Costo unitario",
                            d.costoUnitario.formatted(.currency(code: "MXN"))
                        )
                        fila(
                            "Subtotal",
                            d.subtotal.formatted(.currency(code: "MXN")),
                            color: .green
                        )
                    }
                }

                // =========================
                // TOTAL
                // =========================
                sectionTitle("Total")
                whiteCard {
                    fila(
                        "Subtotal total",
                        subtotalTotal.formatted(.currency(code: "MXN")),
                        color: .green
                    )
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle compra")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - HEADER

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("Detalle compra cliente")
                .font(.headline)
            Spacer()
        }
    }

    // MARK: - HELPERS UI

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func whiteCard<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }

    private func fila(
        _ titulo: String,
        _ valor: String,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(color)
        }
    }

    private func formatearFecha(_ d: Date?) -> String {
        guard let d else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: d)
    }
}
