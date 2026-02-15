//
//  ReciboComprasServiciosListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//
//
//  ReciboComprasServiciosListView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//

import SwiftUI
import SwiftData

struct ReciboComprasServiciosListView: View {

    // MARK: - FILTROS

    enum TipoFiltro: String, CaseIterable, Identifiable {
        case todas = "Todas"
        case compras = "Compras"
        case servicios = "Servicios"
        var id: String { rawValue }
    }

    enum StatusFiltro: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case activas = "Activas"
        case canceladas = "Canceladas"
        var id: String { rawValue }
    }

    // MARK: - STATE

    @State private var tipoSeleccionado: TipoFiltro = .todas
    @State private var proveedorSeleccionado: String = "Todos"
    @State private var statusSeleccionado: StatusFiltro = .todos
    @State private var textoBusqueda = ""

    // MARK: - DATA (OBSERVADA)

    @Query(sort: \OrdenCompra.fechaOrden, order: .reverse)
    private var ordenes: [OrdenCompra]

    // 🔥 CLAVE: esto hace que la tarjeta se actualice sola
    @Query private var recepcionesCompra: [ReciboCompraDetalle]

    // MARK: - BODY

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                filtrosFlotantes

                List {

                    if ordenesFiltradas.isEmpty {
                        ContentUnavailableView(
                            "Sin órdenes",
                            systemImage: "tray",
                            description: Text("No hay órdenes para mostrar.")
                        )
                    }

                    ForEach(ordenesFiltradas) { oc in
                        NavigationLink {
                            ReciboCompraDetalleView(orden: oc)
                        } label: {
                            cardOrden(oc)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Recibo Compras y Servicios")
        }
    }

    // MARK: - FILTROS UI

    var filtrosFlotantes: some View {
        VStack(spacing: 12) {

            TextField(
                "Buscar proveedor, folio, modelo o servicio",
                text: $textoBusqueda
            )
            .textFieldStyle(.roundedBorder)
            .tint(.primary)

            filtroLinea(titulo: "Tipo") {
                Picker("", selection: $tipoSeleccionado) {
                    ForEach(TipoFiltro.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }

            filtroLinea(titulo: "Proveedor") {
                Picker("", selection: $proveedorSeleccionado) {
                    ForEach(proveedoresDisponibles, id: \.self) {
                        Text($0).tag($0)
                    }
                }
            }

            filtroLinea(titulo: "Status") {
                Picker("", selection: $statusSeleccionado) {
                    ForEach(StatusFiltro.allCases) {
                        Text($0.rawValue).tag($0)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - CARD ORDEN (✅ DEFINITIVA)

    func cardOrden(_ oc: OrdenCompra) -> some View {

        let piezasPedidas = piezasPedidasOC(oc)
        let piezasRecibidas = piezasRecibidasOC(oc)
        let porcentaje = piezasPedidas > 0
            ? min(Double(piezasRecibidas) / Double(piezasPedidas), 1)
            : 0

        let status = statusOC(oc)
        let totalRecibido = totalRecibidoOC(oc)

        return VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .top, spacing: 12) {

                // IZQUIERDA
                VStack(alignment: .leading, spacing: 6) {

                    filaCard("Proveedor", oc.proveedor)

                    filaCard(
                        oc.tipoCompra == "servicio"
                            ? "Orden de servicio"
                            : "Orden de compra",
                        oc.folio
                    )

                    if let d = oc.detalles.first {
                        filaCard(
                            oc.tipoCompra == "servicio" ? "Servicio" : "Modelo",
                            d.modelo.isEmpty ? d.articulo : d.modelo
                        )
                        filaCard("Cantidad", "\(d.cantidad)")
                    }

                    filaCard("IVA", oc.aplicaIVA ? "Sí" : "No")
                }

                Spacer()

                // DERECHA
                VStack(alignment: .trailing, spacing: 8) {

                    Text(status.texto)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(status.color)
                        .clipShape(Capsule())

                    Text(formatoMX(totalRecibido))
                        .font(.title3.bold())
                        .foregroundStyle(.green)

                    Text("\(Int(porcentaje * 100))% recibido")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 🔥 BARRA DE PROGRESO
            ProgressView(value: porcentaje)
                .tint(status.color)

            Text("\(piezasRecibidasOC(oc)) / \(piezasPedidasOC(oc)) pz recibidas")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - STATUS (🔥 VERDAD ÚNICA)

    func statusOC(_ oc: OrdenCompra) -> (texto: String, color: Color) {

        if oc.cancelada {
            return ("CANCELADA", .red)
        }

        let recibidas = piezasRecibidasOC(oc)
        let pedidas = piezasPedidasOC(oc)

        if recibidas == 0 {
            return ("ORDEN", .blue)
        }

        if recibidas < pedidas {
            return ("RECIBO PARCIAL", .yellow)
        }

        return ("RECIBO COMPLETO", .green)
    }

    // MARK: - FILTRADO

    var ordenesFiltradas: [OrdenCompra] {
        ordenes.filter { oc in

            switch tipoSeleccionado {
            case .compras:
                if oc.tipoCompra == "servicio" { return false }
            case .servicios:
                if oc.tipoCompra != "servicio" { return false }
            case .todas:
                break
            }

            if proveedorSeleccionado != "Todos",
               oc.proveedor != proveedorSeleccionado {
                return false
            }

            switch statusSeleccionado {
            case .activas:
                if oc.cancelada { return false }
            case .canceladas:
                if !oc.cancelada { return false }
            case .todos:
                break
            }

            if textoBusqueda.isEmpty { return true }
            let t = textoBusqueda.lowercased()

            if oc.proveedor.lowercased().contains(t) { return true }
            if oc.folio.lowercased().contains(t) { return true }

            return oc.detalles.contains {
                $0.articulo.lowercased().contains(t) ||
                $0.modelo.lowercased().contains(t)
            }
        }
    }

    var proveedoresDisponibles: [String] {
        ["Todos"] + Array(Set(ordenes.map { $0.proveedor })).sorted()
    }

    // MARK: - HELPERS DATA (🔥 CLAVE)

    func piezasPedidasOC(_ oc: OrdenCompra) -> Int {
        oc.detalles.reduce(0) { $0 + $1.cantidad }
    }

    func piezasRecibidasOC(_ oc: OrdenCompra) -> Int {
        recepcionesCompra
            .filter {
                $0.ordenCompra == oc &&
                $0.fechaEliminacion == nil
            }
            .reduce(0) { $0 + Int($1.monto) }
    }

    func totalOC(_ oc: OrdenCompra) -> Double {
        let subtotal = oc.detalles.reduce(0) { $0 + $1.subtotal }
        let iva = oc.aplicaIVA ? subtotal * 0.16 : 0
        return subtotal + iva
    }

    func totalRecibidoOC(_ oc: OrdenCompra) -> Double {
        let piezas = piezasRecibidasOC(oc)
        let pedidas = piezasPedidasOC(oc)
        let totalPedido = totalOC(oc)

        guard pedidas > 0 else { return 0 }

        let costoPromedio = totalPedido / Double(pedidas)
        return Double(piezas) * costoPromedio
    }

    // MARK: - HELPERS UI

    func filtroLinea<Content: View>(
        titulo: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack {
            Text(titulo)
                .foregroundStyle(.secondary)
            Spacer()
            content()
                .pickerStyle(.menu)
                .tint(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func filaCard(_ t: String, _ v: String) -> some View {
        HStack(spacing: 4) {
            Text("\(t):")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(v)
                .font(.caption)
        }
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }
}
