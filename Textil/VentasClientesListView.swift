//
//  VentasClientesListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
import SwiftUI
import SwiftData

struct VentasClientesListView: View {

    @Query(sort: \VentaCliente.fechaEntrega, order: .reverse)
    private var ventas: [VentaCliente]

    @Query private var detalles: [VentaClienteDetalle]

    @State private var refreshID = UUID()
    
    var body: some View {
        List {

            if ventas.isEmpty {
                ContentUnavailableView(
                    "Ventas a clientes",
                    systemImage: "cart",
                    description: Text("Aquí se mostrarán las ventas registradas.")
                )
            }

            ForEach(ventas) { venta in
                NavigationLink {
                    VentaClienteDetalleView(venta: venta)
                } label: {
                    cardVenta(venta)
                }
                .buttonStyle(.plain) // mantiene el look de tarjeta
            }
        }
        .id(refreshID) // 👈 FUERZA RECONSTRUCCIÓN
        .onAppear {
            refreshID = UUID()
        }
        .navigationTitle("Ventas Clientes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    VentaClienteNuevaView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    // MARK: - CARD VENTA

    func cardVenta(_ venta: VentaCliente) -> some View {

        let totalVenta = totalDeVenta(venta)

        return VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(venta.folio)
                    .font(.headline)

                Spacer()

                Text(
                    venta.fechaEntrega.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text("Cliente: \(venta.cliente.nombreComercial)")
                .font(.subheadline)

            if let agente = venta.agente {
                Text("Agente: \(agente.nombre) \(agente.apellido)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.caption)

                Spacer()

                Text(formatoMX(totalVenta))
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - CÁLCULO TOTAL

    func totalDeVenta(_ venta: VentaCliente) -> Double {
        let subtotal = detalles
            .filter { $0.venta == venta && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + (Double($1.cantidad) * $1.costoUnitario) }

        let iva = venta.aplicaIVA ? subtotal * 0.16 : 0
        return subtotal + iva
    }

    // MARK: - HELPER

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }
}

#Preview {
    NavigationStack {
        VentasClientesListView()
    }
}
