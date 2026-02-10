//
//  EstadoCompra.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
//
//  EstadoCompra.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import SwiftUI
import SwiftData

// MARK: - ESTADO
enum EstadoCompra: String, CaseIterable, Identifiable {
    case todos = "Todos"
    case activas = "Activas"
    case completas = "Completas"
    var id: String { rawValue }
}

// MARK: - VIEW
struct ResumenComprasClienteView: View {

    // =========================
    // DATA (MISMO ORIGEN QUE COMPRAS CLIENTES)
    // =========================
    @Query(
        filter: #Predicate<OrdenCompra> { $0.tipoCompra == "cliente" },
        sort: \.fechaOrden,
        order: .reverse
    )
    private var ordenes: [OrdenCompra]

    // RECEPCIONES REALES
    @Query private var recepciones: [ReciboCompraDetalle]

    // =========================
    // FILTROS
    // =========================
    @State private var textoBusqueda = ""
    @State private var estadoSeleccionado: EstadoCompra = .todos
    @State private var proveedorSeleccionado = "Todos"
    @State private var mesSeleccionado = "Todos"
    @State private var anioSeleccionado = "Todos"

    @State private var desde: Date = {
        Calendar.current.date(from: DateComponents(
            year: Calendar.current.component(.year, from: Date()),
            month: 1,
            day: 1
        ))!
    }()

    @State private var hasta: Date = Date()

    // =========================
    // BODY
    // =========================
    var body: some View {
        NavigationStack {
            Form {

                // =========================
                // FILTROS
                // =========================
                Section("Filtros") {

                    TextField("Buscar orden o proveedor", text: $textoBusqueda)

                    Picker("Estado", selection: $estadoSeleccionado) {
                        ForEach(EstadoCompra.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }

                    Picker("Proveedor", selection: $proveedorSeleccionado) {
                        ForEach(listaProveedores, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    Picker("Mes", selection: $mesSeleccionado) {
                        Text("Todos").tag("Todos")
                        ForEach(Calendar.current.monthSymbols, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    Picker("Año", selection: $anioSeleccionado) {
                        Text("Todos").tag("Todos")
                        ForEach(listaAnios, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    DatePicker("Desde", selection: $desde, displayedComponents: .date)
                    DatePicker("Hasta", selection: $hasta, displayedComponents: .date)

                    Button(role: .destructive) {
                        limpiarFiltros()
                    } label: {
                        Text("Borrar filtros")
                    }
                }

                // =========================
                // RESUMEN POR PROVEEDOR
                // =========================
                Section("Resumen por proveedor") {
                    ForEach(resumenPorProveedor) { resumen in
                        ResumenClienteCard(resumen: resumen)
                    }
                }

                // =========================
                // ÓRDENES
                // =========================
                Section("Compras clientes") {
                    ForEach(ordenesFiltradas) { orden in
                        NavigationLink {
                            OrdenCompraDetalleView(orden: orden)
                        } label: {
                            tarjetaOrdenCliente(orden)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Resumen Compras Clientes")
        }
    }

    // =========================
    // FILTRO REAL DE ÓRDENES
    // =========================
    private var ordenesFiltradas: [OrdenCompra] {
        ordenes.filter { oc in

            if !textoBusqueda.isEmpty {
                let t = textoBusqueda.lowercased()
                if !oc.proveedor.lowercased().contains(t),
                   !oc.folio.lowercased().contains(t) {
                    return false
                }
            }

            let fecha = oc.fechaOrden
            if fecha < desde || fecha > hasta { return false }

            if mesSeleccionado != "Todos" {
                let mesOrden = Calendar.current.monthSymbols[
                    Calendar.current.component(.month, from: fecha) - 1
                ]
                if mesOrden != mesSeleccionado { return false }
            }

            if anioSeleccionado != "Todos" {
                let anioOrden = String(Calendar.current.component(.year, from: fecha))
                if anioOrden != anioSeleccionado { return false }
            }

            if proveedorSeleccionado != "Todos",
               oc.proveedor != proveedorSeleccionado {
                return false
            }

            // ESTADO (BASADO EN RECEPCIONES REALES)
            let pedidas = oc.detalles.reduce(0) { $0 + $1.cantidad }

            let recibidas = recepciones
                .filter { $0.ordenCompra == oc && $0.fechaEliminacion == nil }
                .reduce(0) { $0 + Int($1.monto) }

            switch estadoSeleccionado {
            case .activas:
                return recibidas < pedidas
            case .completas:
                return pedidas > 0 && recibidas >= pedidas
            case .todos:
                return true
            }
        }
    }

    // =========================
    // RESUMEN POR PROVEEDOR
    // =========================
    private var resumenPorProveedor: [ResumenCliente] {

        let base = proveedorSeleccionado == "Todos"
            ? ordenes
            : ordenes.filter { $0.proveedor == proveedorSeleccionado }

        let agrupadas = Dictionary(grouping: base) { $0.proveedor }
        var resultado: [ResumenCliente] = []

        for (proveedor, items) in agrupadas {

            let totalOrdenes = items.count

            let montoTotal = items.reduce(0.0) { total, oc in
                let subtotal = oc.detalles.reduce(0) { $0 + $1.subtotal }
                let iva = oc.aplicaIVA ? subtotal * 0.16 : 0
                return total + subtotal + iva
            }

            resultado.append(
                ResumenCliente(
                    proveedor: proveedor,
                    ordenes: totalOrdenes,
                    monto: montoTotal
                )
            )
        }

        return resultado
    }

    // =========================
    // TARJETA (MISMA LÓGICA QUE COMPRAS CLIENTES)
    // =========================
    func tarjetaOrdenCliente(_ oc: OrdenCompra) -> some View {

        let pedidas = oc.detalles.reduce(0) { $0 + $1.cantidad }

        let recibidas = recepciones
            .filter { $0.ordenCompra == oc && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + Int($1.monto) }

        let porcentaje = pedidas == 0 ? 0 : Double(recibidas) / Double(pedidas)

        let status: (String, Color) = {
            if oc.cancelada { return ("CANCELADA", .red) }
            if pedidas > 0 && recibidas >= pedidas { return ("ENTREGA COMPLETA", .green) }
            if recibidas > 0 { return ("ENTREGA PARCIAL", .orange) }
            return ("ORDEN", .blue)
        }()

        return VStack(spacing: 12) {

            HStack {

                VStack(alignment: .leading, spacing: 4) {
                    Text("Proveedor: \(oc.proveedor)")
                        .font(.headline)

                    Text("Orden: \(oc.folio)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Artículos: \(oc.detalles.count)")
                        .font(.caption)

                    Text("Fecha: \(oc.fechaOrden.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(status.0)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(status.1)
                        .clipShape(Capsule())

                    Text("MX $ \(totalOrden(oc), specifier: "%.2f")")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text("\(Int(porcentaje * 100)) %")
                        .font(.caption)
                        .foregroundStyle(status.1)
                }
            }

            ProgressView(value: porcentaje)
                .tint(status.1)

            Text("\(recibidas) de \(pedidas) PZ recibidas")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // =========================
    // HELPERS
    // =========================
    private func totalOrden(_ oc: OrdenCompra) -> Double {
        let subtotal = oc.detalles.reduce(0) { $0 + $1.subtotal }
        let iva = oc.aplicaIVA ? subtotal * 0.16 : 0
        return subtotal + iva
    }

    private func limpiarFiltros() {
        textoBusqueda = ""
        estadoSeleccionado = .todos
        proveedorSeleccionado = "Todos"
        mesSeleccionado = "Todos"
        anioSeleccionado = "Todos"

        desde = Calendar.current.date(from: DateComponents(
            year: Calendar.current.component(.year, from: Date()),
            month: 1,
            day: 1
        ))!

        hasta = Date()
    }

    private var listaProveedores: [String] {
        ["Todos"] + Array(Set(ordenes.map { $0.proveedor })).sorted()
    }

    private var listaAnios: [String] {
        ["Todos"] + Array(
            Set(ordenes.map {
                String(Calendar.current.component(.year, from: $0.fechaOrden))
            })
        ).sorted()
    }
}
