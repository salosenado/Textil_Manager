//
//  ResumenComprasClientesView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//
//
import SwiftUI
import SwiftData

struct ResumenComprasClientesView: View {

    // MARK: - DATA

    @Query(sort: \OrdenCompra.fechaOrden, order: .reverse)
    private var ordenes: [OrdenCompra]

    @Query private var recibosDetalle: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]

    // MARK: - FILTROS

    @State private var buscarTexto = ""
    @State private var estadoFiltro = "Todos"
    @State private var proveedorFiltro = "Todos"
    @State private var modeloFiltro = "Todos"
    @State private var mesFiltro = "Todos"
    @State private var anoFiltro = "Todos"

    @State private var fechaDesde =
        Calendar.current.date(from: DateComponents(year: 2020)) ?? Date()
    @State private var fechaHasta = Date()

    private let estados = ["Todos", "Pendiente", "Parcial", "Completa"]

    // MARK: - OPCIONES DINÁMICAS

    var proveedoresDisponibles: [String] {
        let lista = Set(ordenes.map { $0.proveedor })
        return ["Todos"] + lista.sorted()
    }

    var modelosDisponibles: [String] {
        let lista = Set(
            ordenes.flatMap { $0.detalles.map { $0.modelo } }
        )
        return ["Todos"] + lista.sorted()
    }

    var mesesDisponibles: [String] {
        ["Todos","Enero","Febrero","Marzo","Abril","Mayo","Junio",
         "Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"]
    }

    var anosDisponibles: [String] {
        let lista = Set(
            ordenes.map {
                Calendar.current.component(.year, from: $0.fechaOrden)
            }
        )
        return ["Todos"] + lista.sorted().map { String($0) }
    }

    // MARK: - BODY

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                filtrosView
                resumenPorProveedorView
                listaOrdenesView
            }
            .padding()
        }
        .navigationTitle("Resumen Compras Clientes")
    }

    // MARK: - FILTROS (UNO POR LÍNEA)

    var filtrosView: some View {

        VStack(spacing: 0) {

            TextField("Buscar folio o proveedor", text: $buscarTexto)
                .textFieldStyle(.roundedBorder)
                .padding(.bottom, 12)

            filtroLinea("Estado", $estadoFiltro, estados)
            filtroLinea("Proveedor", $proveedorFiltro, proveedoresDisponibles)
            filtroLinea("Modelo", $modeloFiltro, modelosDisponibles)
            filtroLinea("Mes", $mesFiltro, mesesDisponibles)
            filtroLinea("Año", $anoFiltro, anosDisponibles)

            HStack {
                Text("Desde")
                Spacer()
                DatePicker("", selection: $fechaDesde, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.vertical, 8)

            Divider()

            HStack {
                Text("Hasta")
                Spacer()
                DatePicker("", selection: $fechaHasta, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    func filtroLinea(
        _ titulo: String,
        _ seleccion: Binding<String>,
        _ opciones: [String]
    ) -> some View {

        VStack(spacing: 0) {

            HStack {
                Text(titulo)
                    .foregroundStyle(.primary)

                Spacer()

                Picker("", selection: seleccion) {
                    ForEach(opciones, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
            .padding(.vertical, 8)

            Divider()
        }
    }

    // MARK: - RESUMEN POR PROVEEDOR

    var resumenPorProveedorView: some View {

        let proveedores = Set(ordenesFiltradas.map { $0.proveedor })

        return VStack(alignment: .leading, spacing: 16) {

            Text("Resumen por proveedor")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(Array(proveedores), id: \.self) { proveedor in

                let ordenesProveedor = ordenesFiltradas.filter {
                    $0.proveedor == proveedor
                }

                let completas = ordenesProveedor.filter {
                    porcentajeRecibido($0) >= 1
                }.count

                let pendientes = ordenesProveedor.count - completas

                let totalPagado = ordenesProveedor.reduce(0) {
                    $0 + calcularTotalPagado($1)
                }

                let totalOrden = ordenesProveedor.reduce(0) {
                    $0 + calcularTotalOrden($1)
                }

                let pendientePago = totalOrden - totalPagado


                VStack(alignment: .leading, spacing: 8) {

                    Text("Proveedor: \(proveedor)")
                        .font(.headline)

                    filaResumen("Órdenes totales", "\(ordenesProveedor.count)")
                    filaResumen("Completas", "\(completas)", color: .green)
                    filaResumen("Pendientes", "\(pendientes)", color: .red)
                    filaResumen("Pagado", formatoMX(totalPagado), color: .green)
                    filaResumen("Pendiente", formatoMX(pendientePago), color: .red)

                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(18)
            }
        }
    }

    // MARK: - LISTA ÓRDENES

    var listaOrdenesView: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Órdenes de compra")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(ordenesFiltradas, id: \.persistentModelID) { orden in

                let porcentaje = porcentajeRecibido(orden)
                let estado = estadoOrden(orden)
                let nota = numeroNotaFactura(orden)
                let notaTexto = nota.isEmpty ? "-" : nota

                NavigationLink {
                    DetalleOrdenCompraView(orden: orden)
                } label: {

                    VStack(alignment: .leading, spacing: 8) {

                        HStack {
                            Text("Proveedor: \(orden.proveedor)")
                                .font(.headline)

                            Spacer()

                            Text(estado.texto)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(estado.color.opacity(0.15))
                                .foregroundStyle(estado.color)
                                .cornerRadius(10)
                        }

                        Text("Orden: \(orden.folio)")
                            .foregroundStyle(.secondary)

                        Text("Nota / Factura: \(notaTexto)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Fecha orden: \(formatoFecha(orden.fechaOrden))")
                        Text("Fecha entrega: \(formatoFecha(orden.fechaEntrega))")

                        Text("\(Int(porcentaje * 100))% recibido")
                            .foregroundStyle(.green)

                        ProgressView(value: porcentaje)
                            .tint(.green)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }
                .buttonStyle(.plain) // 🔥 evita el azul feo del NavigationLink
            }
        }
    }

    // MARK: - FILTRADO

    var ordenesFiltradas: [OrdenCompra] {

        var lista = ordenes.filter {
            $0.tipoCompra == "cliente" && !$0.cancelada
        }

        if !buscarTexto.isEmpty {
            lista = lista.filter {
                $0.folio.lowercased().contains(buscarTexto.lowercased()) ||
                $0.proveedor.lowercased().contains(buscarTexto.lowercased())
            }
        }

        if estadoFiltro != "Todos" {
            lista = lista.filter {
                estadoOrden($0).texto == estadoFiltro
            }
        }

        if proveedorFiltro != "Todos" {
            lista = lista.filter { $0.proveedor == proveedorFiltro }
        }

        if modeloFiltro != "Todos" {
            lista = lista.filter {
                $0.detalles.contains { $0.modelo == modeloFiltro }
            }
        }

        if anoFiltro != "Todos", let ano = Int(anoFiltro) {
            lista = lista.filter {
                Calendar.current.component(.year, from: $0.fechaOrden) == ano
            }
        }

        if mesFiltro != "Todos",
           let index = mesesDisponibles.firstIndex(of: mesFiltro) {
            lista = lista.filter {
                Calendar.current.component(.month, from: $0.fechaOrden) == index
            }
        }

        lista = lista.filter {
            $0.fechaOrden >= fechaDesde &&
            $0.fechaOrden <= fechaHasta
        }

        return lista
    }

    // MARK: - CÁLCULOS

    func calcularTotalOrden(_ orden: OrdenCompra) -> Double {
        let subtotal = orden.detalles.reduce(0) { $0 + $1.subtotal }
        return orden.aplicaIVA ? subtotal * 1.16 : subtotal
    }

    func calcularTotalPagado(_ orden: OrdenCompra) -> Double {
        pagos
            .filter { $0.fechaEliminacion == nil && $0.recibo?.ordenCompra == orden }
            .reduce(0) { $0 + $1.monto }
    }

    func numeroNotaFactura(_ orden: OrdenCompra) -> String {
        let reciboActivo = pagos
            .compactMap { $0.recibo }
            .first { $0.ordenCompra == orden && $0.cancelado == false }

        return reciboActivo?.numeroFacturaNota ?? ""
    }

    func piezasOrdenadas(_ orden: OrdenCompra) -> Int {
        orden.detalles.reduce(0) { $0 + $1.cantidad }
    }

    func piezasRecibidas(_ orden: OrdenCompra) -> Int {
        recibosDetalle
            .filter { $0.ordenCompra == orden && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + Int($1.monto) }
    }

    func porcentajeRecibido(_ orden: OrdenCompra) -> Double {
        let ordenadas = piezasOrdenadas(orden)
        guard ordenadas > 0 else { return 0 }
        return Double(piezasRecibidas(orden)) / Double(ordenadas)
    }

    func estadoOrden(_ orden: OrdenCompra) -> (texto: String, color: Color) {
        let porcentaje = porcentajeRecibido(orden)

        if porcentaje <= 0.001 {
            return ("Pendiente", .red)
        } else if porcentaje < 1 {
            return ("Parcial", .yellow)
        } else {
            return ("Completa", .green)
        }
    }

    func formatoFecha(_ fecha: Date) -> String {
        fecha.formatted(.dateTime.day().month(.abbreviated).year())
    }

    func filaResumen(_ titulo: String, _ valor: String, color: Color = .primary) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(color)
        }
    }

    func formatoMX(_ valor: Double) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.currencySymbol = "MX $"
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: valor)) ?? "MX $ 0.00"
    }
}
