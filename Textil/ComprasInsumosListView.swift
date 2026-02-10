//
//  ComprasInsumosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
import SwiftUI
import SwiftData

struct ComprasInsumosListView: View {

    // =====================================
    // MARK: - DATA
    // =====================================

    @Query(
        filter: #Predicate<OrdenCompra> { $0.tipoCompra == "insumo" },
        sort: \.fechaOrden,
        order: .reverse
    )
    private var ordenes: [OrdenCompra]

    // Recepciones reales (para status y %)
    @Query private var recepciones: [ReciboCompraDetalle]

    @State private var mostrarAlta = false

    // =====================================
    // MARK: - BODY
    // =====================================

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(ordenes) { oc in
                    NavigationLink {
                        OrdenCompraInsumosDetalleView(orden: oc)
                    } label: {
                        tarjetaOrden(oc)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Compras Insumos")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    mostrarAlta = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $mostrarAlta) {
            NavigationStack {
                AltaCompraInsumosView()
            }
        }
    }

    // =====================================
    // MARK: - TARJETA
    // =====================================

    func tarjetaOrden(_ oc: OrdenCompra) -> some View {

        let piezasPedidas = oc.detalles.reduce(0) { $0 + $1.cantidad }

        let piezasRecibidas = recepciones
            .filter { $0.ordenCompra == oc && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + Int($1.monto) }

        let porcentaje = piezasPedidas == 0
            ? 0
            : Double(piezasRecibidas) / Double(piezasPedidas)

        let status = statusInfo(oc, piezasPedidas, piezasRecibidas)

        return VStack(spacing: 14) {

            // =========================
            // CONTENIDO PRINCIPAL
            // =========================
            HStack(alignment: .top, spacing: 16) {

                // IZQUIERDA
                VStack(alignment: .leading, spacing: 6) {

                    filaInfo("Proveedor", oc.proveedor)
                    filaInfo("Orden", oc.folio)
                    filaInfo("Insumos", "\(oc.detalles.count)")
                    filaInfo("Fecha orden", formatoFecha(oc.fechaOrden))
                    filaInfo("Fecha entrega", formatoFecha(oc.fechaEntrega))
                    filaInfo("IVA", oc.aplicaIVA ? "Sí" : "No")
                }

                Spacer()

                // DERECHA (STATUS + TOTAL + %)
                VStack(alignment: .trailing, spacing: 8) {

                    // STATUS
                    Text(status.texto)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(status.color)
                        .clipShape(Capsule())

                    // TOTAL ORDEN
                    Text(formatoMX(totalOrden(oc)))
                        .font(.headline)
                        .foregroundStyle(.green)

                    // PORCENTAJE
                    Text("\(Int(porcentaje * 100)) %")
                        .font(.caption.bold())
                        .foregroundStyle(status.color)
                }
            }

            // =========================
            // PROGRESO
            // =========================
            VStack(alignment: .leading, spacing: 6) {

                ProgressView(value: porcentaje)
                    .tint(status.color)

                Text("\(piezasRecibidas) de \(piezasPedidas) PZ recibidas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // =====================================
    // MARK: - STATUS
    // =====================================

    func statusInfo(
        _ oc: OrdenCompra,
        _ pedidas: Int,
        _ recibidas: Int
    ) -> (texto: String, color: Color) {

        if oc.cancelada {
            return ("CANCELADA", .red)
        }

        if pedidas > 0 && recibidas >= pedidas {
            return ("RECIBO COMPLETO", .green)
        }

        if recibidas > 0 {
            return ("RECIBO PARCIAL", .orange)
        }

        return ("ORDEN", .blue)
    }

    // =====================================
    // MARK: - HELPERS
    // =====================================

    func totalOrden(_ oc: OrdenCompra) -> Double {
        let subtotal = oc.detalles.reduce(0) { $0 + $1.subtotal }
        let iva = oc.aplicaIVA ? subtotal * 0.16 : 0
        return subtotal + iva
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }

    func filaInfo(_ titulo: String, _ valor: String) -> some View {
        HStack(spacing: 6) {
            Text("\(titulo):")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(valor)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }

    func formatoFecha(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
