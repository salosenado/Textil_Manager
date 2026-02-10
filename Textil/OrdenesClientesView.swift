//
//  OrdenesClientesView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//  OrdenesClientesView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

struct OrdenesClientesView: View {

    @Query(sort: \OrdenCliente.fechaCreacion, order: .reverse)
    private var ordenes: [OrdenCliente]

    // MARK: - UI STATE
    @State private var searchText = ""
    @State private var mostrarNuevaOrden = false
    @State private var ordenSeleccionada: OrdenCliente?

    enum Periodo: String, CaseIterable {
        case semana = "Semana"
        case mes = "Mes"
        case anio = "Año"
    }

    enum Status: String, CaseIterable {
        case todos = "Todos"
        case activas = "Activas"
        case bloqueadas = "Bloqueadas"
    }

    @State private var periodo: Periodo = .mes
    @State private var status: Status = .todos
    @State private var clienteSeleccionado: String = "Todos"

    @State private var fechaInicio = Date()
    @State private var fechaFin = Date()
    @State private var mes = Calendar.current.component(.month, from: Date())
    @State private var anio = Calendar.current.component(.year, from: Date())

    // CONTROL PICKERS
    @State private var mostrarPickerMes = false
    @State private var mostrarPickerAnio = false
    @State private var mostrarPickerStatus = false
    @State private var mostrarPickerCliente = false

    // MARK: - DATA
    private var clientes: [String] {
        ["Todos"] + Array(Set(ordenes.map { $0.cliente })).sorted()
    }

    // MARK: - FILTRADO
    private var ordenesFiltradas: [OrdenCliente] {
        ordenes.filter { orden in

            let matchSearch =
                searchText.isEmpty ||
                orden.cliente.localizedCaseInsensitiveContains(searchText) ||
                orden.numeroPedidoCliente.localizedCaseInsensitiveContains(searchText)

            let matchCliente =
                clienteSeleccionado == "Todos" ||
                orden.cliente == clienteSeleccionado

            let matchFecha: Bool
            switch periodo {
            case .semana:
                matchFecha = orden.fechaCreacion >= fechaInicio &&
                             orden.fechaCreacion <= fechaFin
            case .mes:
                let c = Calendar.current.dateComponents([.month, .year], from: orden.fechaCreacion)
                matchFecha = c.month == mes && c.year == anio
            case .anio:
                matchFecha = Calendar.current.component(.year, from: orden.fechaCreacion) == anio
            }

            let bloqueada = orden.detalles.contains {
                ($0.produccion?.pzCortadas ?? 0) > 0
            }

            let produccionCancelada = orden.detalles.contains {
                $0.produccion?.cancelada == true
            }

            let matchStatus: Bool
            switch status {
            case .todos:
                matchStatus = true
            case .activas:
                matchStatus = !bloqueada && !orden.cancelada && !produccionCancelada
            case .bloqueadas:
                matchStatus = bloqueada
            }

            return matchSearch && matchCliente && matchFecha && matchStatus
        }
    }

    // ❌ NO SUMA CANCELADAS
    private var totalPZ: Int {
        ordenesFiltradas
            .filter { !$0.cancelada }
            .flatMap { $0.detalles }
            .reduce(0) { $0 + $1.cantidad }
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {

                    // 🔍 BUSCADOR
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Buscar cliente o pedido", text: $searchText)
                    }
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.horizontal)

                    // 📅 FILTROS
                    VStack(spacing: 0) {

                        Picker("", selection: $periodo) {
                            ForEach(Periodo.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()

                        Divider()

                        if periodo == .semana {
                            DatePicker("Desde", selection: $fechaInicio, displayedComponents: .date)
                                .padding()
                            Divider()
                            DatePicker("Hasta", selection: $fechaFin, displayedComponents: .date)
                                .padding()
                        }

                        if periodo == .mes {
                            Button { mostrarPickerMes = true } label: {
                                filaTexto("Mes", Calendar.current.monthSymbols[mes - 1])
                            }
                            .buttonStyle(.plain)

                            Divider()

                            Button { mostrarPickerAnio = true } label: {
                                filaTexto("Año", String(anio))
                            }
                            .buttonStyle(.plain)
                        }

                        if periodo == .anio {
                            Button { mostrarPickerAnio = true } label: {
                                filaTexto("Año", String(anio))
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()

                        HStack {
                            Text("Total PZ")
                            Spacer()
                            Text("\(totalPZ)")
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 8)
                    .padding(.horizontal)

                    // 👤 CLIENTE
                    Button { mostrarPickerCliente = true } label: {
                        filaTexto("Cliente", clienteSeleccionado)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 8)
                    .padding(.horizontal)

                    // 🎛 STATUS
                    Button { mostrarPickerStatus = true } label: {
                        filaTexto("Status", status.rawValue)
                    }
                    .buttonStyle(.plain)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(radius: 8)
                    .padding(.horizontal)

                    // 📋 LISTA
                    ForEach(ordenesFiltradas) { orden in
                        Button {
                            ordenSeleccionada = orden
                        } label: {
                            tarjetaOrden(orden)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Ventas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        mostrarNuevaOrden = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarNuevaOrden) {
                AltaOrdenClienteView(ordenExistente: nil)
            }
            .sheet(item: $ordenSeleccionada) { orden in
                OrdenClienteDetalleEditableView(orden: orden)
            }

            // PICKERS
            .confirmationDialog("Mes", isPresented: $mostrarPickerMes) {
                ForEach(1...12, id: \.self) { m in
                    Button(Calendar.current.monthSymbols[m - 1]) { mes = m }
                }
            }

            .confirmationDialog("Año", isPresented: $mostrarPickerAnio) {
                ForEach((2022...2030).reversed(), id: \.self) { y in
                    Button(String(y)) { anio = y }
                }
            }

            .confirmationDialog("Status", isPresented: $mostrarPickerStatus) {
                ForEach(Status.allCases, id: \.self) { s in
                    Button(s.rawValue) { status = s }
                }
            }

            .confirmationDialog("Cliente", isPresented: $mostrarPickerCliente) {
                ForEach(clientes, id: \.self) { c in
                    Button(c) { clienteSeleccionado = c }
                }
            }
        }
    }

    // MARK: - HELPERS

    func filaTexto(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // TARJETA
    func tarjetaOrden(_ orden: OrdenCliente) -> some View {

        let bloqueada = orden.detalles.contains {
            ($0.produccion?.pzCortadas ?? 0) > 0
        }

        let produccionCancelada = orden.detalles.contains {
            $0.produccion?.cancelada == true
        }

        let statusTexto: String
        let statusColor: Color

        if orden.cancelada || produccionCancelada {
            statusTexto = "CANCELADA"
            statusColor = .red
        } else if bloqueada {
            statusTexto = "BLOQUEADA"
            statusColor = .orange
        } else {
            statusTexto = "ACTIVA"
            statusColor = .green
        }

        return HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Proveedor: \(orden.cliente)")
                    .font(.headline)

                Text("Pedido: \(orden.numeroPedidoCliente)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Modelos: \(orden.detalles.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Creado: \(orden.fechaCreacion.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {

                Text(statusTexto)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                if !(orden.cancelada || produccionCancelada) {
                    Text("MX $ \(String(format: "%.2f", orden.total))")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Text(orden.aplicaIVA ? "CON IVA" : "SIN IVA")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 4)
    }
}
