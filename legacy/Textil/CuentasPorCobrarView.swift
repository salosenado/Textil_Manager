//
//  CuentasPorCobrarView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct CuentasPorCobrarView: View {
    
    // MARK: - DATA
    
    @Query(sort: \VentaCliente.fechaVenta, order: .reverse)
    private var ventas: [VentaCliente]
    
    @Query private var cobros: [CobroVenta]
    
    // MARK: - FILTROS
    
    @State private var buscarCliente = ""
    @State private var filtroEstado = "Todos"
    
    @State private var clienteSeleccionado: String = "Todos los clientes"
    @State private var anoSeleccionado: Int = 0
    @State private var mesSeleccionado: Int = 0
    @State private var usarRangoPersonalizado = false
    @State private var fechaDesde = Date()
    @State private var fechaHasta = Date()
    
    @State private var exportURL: URL?
    @State private var mostrarShare = false
    
    private let estados = ["Todos", "Vencidos", "Pendientes", "Cobrados"]
    
    // MARK: - BODY
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // 🔎 BUSCADOR
                    TextField("Buscar cliente...", text: $buscarCliente)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    // 🔎 ESTADO
                    Picker("Estado", selection: $filtroEstado) {
                        ForEach(estados, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 🔵 AGING
                    
                    let aging = calcularAgingGlobal()
                    let semanaActual = rangoSemanaLaboral(0)
                    let semanaSiguiente = rangoSemanaLaboral(1)

                    VStack(spacing: 6) {
                        
                        agingRow("Vigente", aging.vigente, .blue)
                        
                        agingRow(
                            "Semana actual (\(fechaCorta(semanaActual.inicio)) - \(fechaCorta(semanaActual.fin)))",
                            aging.semanaActual,
                            .purple
                        )
                        
                        agingRow(
                            "Próxima semana (\(fechaCorta(semanaSiguiente.inicio)) - \(fechaCorta(semanaSiguiente.fin)))",
                            aging.semanaSiguiente,
                            .mint
                        )
                        
                        agingRow("1 - 30 días", aging.dias30, .green)
                        agingRow("31 - 60 días", aging.dias60, .yellow)
                        agingRow("61 - 90 días", aging.dias90, .orange)
                        agingRow("+ 90 días", aging.mas90, .red)
                    }
                    .padding(.horizontal)
                    
                    // 🔵 BOTONES EXPORTACIÓN
                    
                    HStack(spacing: 12) {
                        
                        Button { generarPDF() } label: {
                            Label("PDF", systemImage: "doc.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                        
                        Button { generarExcel() } label: {
                            Label("Excel", systemImage: "tablecells.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(12)
                        }
                        
                        Button { imprimirReporte() } label: {
                            Label("Imprimir", systemImage: "printer.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // 🔵 HISTÓRICO FINANCIERO
                    
                    let resumen = resumenHistoricoReal()
                    
                    VStack(spacing: 14) {
                        
                        // CLIENTE
                        HStack {
                            Text("Cliente")
                            Spacer()
                            Picker("", selection: $clienteSeleccionado) {
                                Text("Todos").tag("Todos los clientes")
                                ForEach(clientesUnicos(), id: \.self) { cliente in
                                    Text(cliente).tag(cliente)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // AÑO
                        let anos = Array(
                            Set(
                                ventas.map {
                                    Calendar.current.component(.year, from: $0.fechaEntrega)
                                }
                            )
                        ).sorted()
                        
                        HStack {
                            Text("Año")
                            Spacer()
                            Picker("", selection: $anoSeleccionado) {
                                Text("Todos").tag(0)
                                ForEach(anos, id: \.self) { ano in
                                    Text(String(ano)).tag(ano)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // MES
                        HStack {
                            Text("Mes")
                            Spacer()
                            Picker("", selection: $mesSeleccionado) {
                                Text("Todos").tag(0)
                                ForEach(1...12, id: \.self) { mes in
                                    Text(nombreMes(mes)).tag(mes)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Toggle("Usar rango personalizado", isOn: $usarRangoPersonalizado)
                        
                        if usarRangoPersonalizado {
                            HStack {
                                DatePicker("Desde", selection: $fechaDesde, displayedComponents: .date)
                                DatePicker("Hasta", selection: $fechaHasta, displayedComponents: .date)
                            }
                        }
                        
                        Divider()
                        
                        resumenRow("Total Cobrado", resumen.cobrado, .primary)
                        resumenRow("Total Vencido", resumen.vencido, .red)
                        resumenRow("Total Por Cobrar", resumen.porCobrar, .blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    
                    Divider()
                    
                    // 🔵 LISTA CLIENTES
                    
                    LazyVStack(spacing: 14) {
                        
                        let clientes = clientesFiltrados()
                        
                        if clientes.isEmpty {
                            Text("No hay cuentas por cobrar.")
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(clientes, id: \.self) { cliente in
                            
                            let resumen = calcularResumen(cliente: cliente)
                            
                            if mostrarSegunFiltro(resumen) {
                                
                                NavigationLink {
                                    CxCDetalleClienteView(
                                        cliente: cliente,
                                        ventasCliente: resumen.ventas
                                    )
                                } label: {
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        
                                        HStack {
                                            Text(cliente)
                                                .font(.headline)
                                            
                                            Spacer()
                                            
                                            if resumen.vencido > 0 {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                        }
                                        
                                        Divider()
                                        
                                        ForEach(resumen.ventas.prefix(3), id: \.persistentModelID) { venta in
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Venta: \(venta.folio)")
                                                    .font(.caption)
                                                    .bold()
                                                Text("Entrega: \(fechaCorta(venta.fechaEntrega))")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        
                                        if resumen.ventas.count > 3 {
                                            Text("+ \(resumen.ventas.count - 3) ventas más...")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }
                                        
                                        Divider()
                                        
                                        Text("Pendiente: MX$ \(resumen.pendiente.formatoMoneda)")
                                        Text("Vencido: MX$ \(resumen.vencido.formatoMoneda)")
                                            .foregroundStyle(.red)
                                        Text("Total por cobrar: MX$ \(resumen.total.formatoMoneda)")
                                            .bold()
                                    }
                                    .padding(14)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.gray.opacity(0.3))
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: .black.opacity(0.04), radius: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Cuentas por Cobrar")
            .toolbar {
                if existeDeudaVencida {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .sheet(isPresented: $mostrarShare) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
        }
    }
}
extension CuentasPorCobrarView {
    
    func clientesUnicos() -> [String] {
        let base = ventas.filter { $0.mercanciaEnviada && !$0.cancelada }
        return Array(Set(base.map { $0.cliente.nombreComercial })).sorted()
    }
    
    func clientesFiltrados() -> [String] {
        var lista = clientesUnicos()
        if !buscarCliente.isEmpty {
            lista = lista.filter {
                $0.lowercased().contains(buscarCliente.lowercased())
            }
        }
        return lista
    }
    
    func totalVentaDe(_ venta: VentaCliente) -> Double {
        let subtotal = venta.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
        return venta.aplicaIVA ? subtotal * 1.16 : subtotal
    }
    
    func totalCobradoDe(_ venta: VentaCliente) -> Double {
        cobros
            .filter { $0.venta == venta && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + $1.monto }
    }
    
    func calcularResumen(cliente: String) -> (
        pendiente: Double,
        vencido: Double,
        total: Double,
        ventas: [VentaCliente]
    ) {
        
        let ventasCliente = ventas.filter {
            $0.mercanciaEnviada &&
            !$0.cancelada &&
            $0.cliente.nombreComercial == cliente
        }
        
        var pendiente: Double = 0
        var vencido: Double = 0
        var total: Double = 0
        
        for venta in ventasCliente {
            
            let saldo = totalVentaDe(venta) - totalCobradoDe(venta)
            total += saldo
            
            if saldo > 0 {
                pendiente += saldo
                
                let vencimiento = Calendar.current.date(
                    byAdding: .day,
                    value: venta.cliente.plazoDias,
                    to: venta.fechaEntrega
                )!
                
                if Date() > vencimiento {
                    vencido += saldo
                }
            }
        }
        
        return (pendiente, vencido, total, ventasCliente)
    }
    
    func mostrarSegunFiltro(
        _ resumen: (pendiente: Double, vencido: Double, total: Double, ventas: [VentaCliente])
    ) -> Bool {
        
        switch filtroEstado {
        case "Vencidos": return resumen.vencido > 0
        case "Pendientes": return resumen.pendiente > 0
        case "Cobrados": return resumen.pendiente == 0
        default: return true
        }
    }
    
    func calcularAgingGlobal() -> (
        vigente: Double,
        semanaActual: Double,
        semanaSiguiente: Double,
        dias30: Double,
        dias60: Double,
        dias90: Double,
        mas90: Double
    ) {
        
        var vigente = 0.0
        var semanaActual = 0.0
        var semanaSiguiente = 0.0
        var dias30 = 0.0
        var dias60 = 0.0
        var dias90 = 0.0
        var mas90 = 0.0
        
        let hoy = Date()
        let calendar = Calendar.current
        
        let inicioSemana = calendar.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        let finSemanaLaboral = calendar.date(byAdding: .day, value: 4, to: inicioSemana)!
        
        let inicioSemanaSiguiente = calendar.date(byAdding: .day, value: 7, to: inicioSemana)!
        let finSemanaLaboralSiguiente = calendar.date(byAdding: .day, value: 4, to: inicioSemanaSiguiente)!
        
        for venta in ventas where venta.mercanciaEnviada && !venta.cancelada {
            
            let saldo = totalVentaDe(venta) - totalCobradoDe(venta)
            if saldo <= 0 { continue }
            
            let vencimiento = calendar.date(
                byAdding: .day,
                value: venta.cliente.plazoDias,
                to: venta.fechaEntrega
            )!
            
            let dias = calendar.dateComponents([.day], from: vencimiento, to: hoy).day ?? 0
            
            if dias <= 0 {
                vigente += saldo
            }
            else if vencimiento >= inicioSemana && vencimiento <= finSemanaLaboral {
                semanaActual += saldo
            }
            else if vencimiento >= inicioSemanaSiguiente && vencimiento <= finSemanaLaboralSiguiente {
                semanaSiguiente += saldo
            }
            else if dias <= 30 {
                dias30 += saldo
            }
            else if dias <= 60 {
                dias60 += saldo
            }
            else if dias <= 90 {
                dias90 += saldo
            }
            else {
                mas90 += saldo
            }
        }
        
        return (vigente, semanaActual, semanaSiguiente, dias30, dias60, dias90, mas90)
    }

    func resumenHistoricoReal() -> (cobrado: Double, vencido: Double, porCobrar: Double) {
        
        var cobrado = 0.0
        var vencido = 0.0
        var porCobrar = 0.0
        
        for venta in ventas where venta.mercanciaEnviada && !venta.cancelada {
            
            let totalVenta = totalVentaDe(venta)
            let totalCobrado = totalCobradoDe(venta)
            
            cobrado += totalCobrado
            
            let saldo = totalVenta - totalCobrado
            if saldo <= 0 { continue }
            
            let vencimiento = Calendar.current.date(
                byAdding: .day,
                value: venta.cliente.plazoDias,
                to: venta.fechaEntrega
            )!
            
            if Date() > vencimiento { vencido += saldo }
            else { porCobrar += saldo }
        }
        
        return (cobrado, vencido, porCobrar)
    }
    
    func agingRow(_ titulo: String, _ monto: Double, _ color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(titulo)
            Spacer()
            Text("MX$ \(monto.formatoMoneda)").bold()
        }
    }
    
    func resumenRow(_ titulo: String, _ monto: Double, _ color: Color) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text("MX$ \(monto.formatoMoneda)")
                .foregroundStyle(color)
                .bold()
        }
    }
    func rangoSemanaLaboral(_ desplazamiento: Int) -> (inicio: Date, fin: Date) {
        
        let calendar = Calendar.current
        let hoy = Date()
        
        let inicioSemana = calendar.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        
        let inicio = calendar.date(
            byAdding: .day,
            value: desplazamiento * 7,
            to: inicioSemana
        )!
        
        let fin = calendar.date(
            byAdding: .day,
            value: 4,
            to: inicio
        )!
        
        return (inicio, fin)
    }

    func fechaCorta(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: fecha)
    }
    
    func nombreMes(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.monthSymbols[mes - 1].capitalized
    }
    
    var existeDeudaVencida: Bool {
        ventas.contains {
            let saldo = totalVentaDe($0) - totalCobradoDe($0)
            if saldo <= 0 { return false }
            
            let vencimiento = Calendar.current.date(
                byAdding: .day,
                value: $0.cliente.plazoDias,
                to: $0.fechaEntrega
            )!
            
            return Date() > vencimiento
        }
    }
    
    // MARK: - EXPORT REAL

    func construirReporteActual() -> CuentasPorCobrarReporte {

        let clienteFiltro: String? =
            clienteSeleccionado == "Todos los clientes" ? nil : clienteSeleccionado

        return CuentasPorCobrarReportBuilder.construirReporte(
            ventas: ventas,
            cobros: cobros,
            clienteFiltro: clienteFiltro,
            fechaInicio: usarRangoPersonalizado ? fechaDesde : nil,
            fechaFin: usarRangoPersonalizado ? fechaHasta : nil
        )
    }

    func generarPDF() {
        let reporte = construirReporteActual()
        if let url = CuentasPorCobrarExportManager.exportarPDF(reporte) {
            exportURL = url
            mostrarShare = true
        }
    }

    func generarExcel() {
        let reporte = construirReporteActual()
        if let url = CuentasPorCobrarExportManager.exportarExcel(reporte) {
            exportURL = url
            mostrarShare = true
        }
    }

    func imprimirReporte() {
        let reporte = construirReporteActual()
        CuentasPorCobrarExportManager.imprimir(reporte)
    }
}
