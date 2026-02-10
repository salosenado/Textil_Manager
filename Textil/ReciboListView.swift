//
//  ReciboListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//  ReciboListView.swift
//  Textil
import SwiftUI
import SwiftData

struct ReciboListView: View {

    // MARK: - STATE

    @State private var textoBusqueda = ""
    @State private var clienteSeleccionado = "Todos"
    @State private var statusSeleccionado: StatusFiltro = .todos

    enum StatusFiltro: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case produccion = "En producción"
        case parcial = "Parcial"
        case completa = "Completa"

        var id: String { rawValue }
    }

    // MARK: - DATA (PRODUCCIÓN)

    @Query(sort: \OrdenCliente.fechaCreacion, order: .reverse)
    private var ordenes: [OrdenCliente]

    // 🔴 RECEPCIONES REALES
    @Query private var recepciones: [ReciboDetalle]

    // MARK: - BODY

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {

                // 🔍 BUSCADOR
                TextField(
                    "Buscar cliente, modelo, pedido u OM",
                    text: $textoBusqueda
                )
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.top, 8)

                // 🔎 FILTROS
                VStack(spacing: 10) {

                    filtroCard {
                        HStack {
                            Text("Status")
                            Spacer()
                            Picker("", selection: $clienteSeleccionado) {
                                ForEach(clientesDisponibles, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }

                    filtroCard {
                        HStack {
                            Text("Cliente")
                            Spacer()
                            Picker("", selection: $statusSeleccionado) {
                                ForEach(StatusFiltro.allCases) {
                                    Text($0.rawValue).tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // 📦 LISTA PRODUCCIÓN
                listaModelosRecibo(modelosFiltrados)
            }
            .navigationTitle("Recibo")
        }
    }

    // MARK: - LISTA PRODUCCIÓN

    func listaModelosRecibo(_ modelos: [OrdenClienteDetalle]) -> some View {
        List {

            if modelos.isEmpty {
                ContentUnavailableView(
                    "Sin resultados",
                    systemImage: "tray",
                    description: Text("No hay órdenes de producción.")
                )
            }

            ForEach(modelos) { detalle in
                NavigationLink {
                    ReciboDetalleView(detalle: detalle)
                } label: {

                    HStack(alignment: .top, spacing: 16) {

                        // =====================
                        // IZQUIERDA
                        // =====================
                        VStack(alignment: .leading, spacing: 6) {
                            fila("Cliente", detalle.orden?.cliente ?? "—")
                            fila("Pedido", detalle.orden?.numeroPedidoCliente ?? "—")
                            fila("Modelo", detalle.modelo)
                            fila("OM", detalle.produccion?.ordenMaquila ?? "—")
                            fila("Cantidad", "\(detalle.cantidad)")
                            fila("IVA", detalle.orden?.aplicaIVA == true ? "Sí" : "No")
                        }

                        Spacer()

                        // =====================
                        // DERECHA
                        // =====================
                        VStack(alignment: .trailing, spacing: 8) {

                            Text(statusTexto(detalle))
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(statusColor(detalle).opacity(0.15))
                                .foregroundColor(statusColor(detalle))
                                .clipShape(Capsule())

                            Text(formatoMX(totalRecibido(detalle)))
                                .font(.title3.bold())
                                .foregroundStyle(.green)

                            Text("\(porcentajeRecibido(detalle))% recibido")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // 🔥 BARRA DE PROGRESO (FINA)
                            ProgressView(
                                value: Double(pzRecibidas(detalle)),
                                total: Double(detalle.cantidad)
                            )
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            // 🔢 PIEZAS RECIBIDAS
                            Text("\(pzRecibidas(detalle)) / \(detalle.cantidad) PZ Recibidas")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - FILTRADO

    var modelosBase: [OrdenClienteDetalle] {
        ordenes
            .filter { !$0.cancelada }
            .flatMap { $0.detalles }
            .filter {
                guard let p = $0.produccion else { return false }
                return p.pzCortadas > 0 &&
                       p.costoMaquila > 0 &&
                       !p.maquilero.isEmpty
            }
    }

    var modelosFiltrados: [OrdenClienteDetalle] {
        modelosBase.filter { d in

            if clienteSeleccionado != "Todos",
               d.orden?.cliente != clienteSeleccionado {
                return false
            }

            switch statusSeleccionado {
            case .produccion:
                return pzRecibidas(d) == 0
            case .parcial:
                return pzRecibidas(d) > 0 && pzRecibidas(d) < d.cantidad
            case .completa:
                return pzRecibidas(d) >= d.cantidad
            case .todos:
                return true
            }
        }
    }

    var clientesDisponibles: [String] {
        ["Todos"] + Array(
            Set(modelosBase.compactMap { $0.orden?.cliente })
        ).sorted()
    }

    // MARK: - LÓGICA RECEPCIÓN

    func pzRecibidas(_ d: OrdenClienteDetalle) -> Int {
        recepciones
            .filter {
                $0.detalleOrden == d &&
                $0.fechaEliminacion == nil
            }
            .reduce(0) { $0 + $1.pzPrimera + $1.pzSaldo }
    }

    func totalRecibido(_ d: OrdenClienteDetalle) -> Double {
        let pz = Double(pzRecibidas(d))
        let costo = d.produccion?.costoMaquila ?? 0
        let subtotal = pz * costo
        return d.orden?.aplicaIVA == true ? subtotal * 1.16 : subtotal
    }

    func porcentajeRecibido(_ d: OrdenClienteDetalle) -> Int {
        guard d.cantidad > 0 else { return 0 }
        return Int(Double(pzRecibidas(d)) / Double(d.cantidad) * 100)
    }

    func statusTexto(_ d: OrdenClienteDetalle) -> String {
        let r = pzRecibidas(d)
        if r == 0 { return "En producción" }
        if r < d.cantidad { return "Parcial" }
        return "Completa"
    }

    func statusColor(_ d: OrdenClienteDetalle) -> Color {
        let r = pzRecibidas(d)
        if r == 0 { return .red }
        if r < d.cantidad { return .yellow }
        return .green
    }

    // MARK: - UI HELPERS

    func filtroCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    func fila(_ t: String, _ v: String) -> some View {
        HStack(spacing: 4) {
            Text("\(t):")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(v)
                .font(.caption)
        }
    }

    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
