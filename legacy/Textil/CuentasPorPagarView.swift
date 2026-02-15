//
//  CuentasPorPagarView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  CuentasPorPagarView.swift
//  Textil
//
//
//  CuentasPorPagarView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CuentasPorPagarView: View {
    
    // MARK: - DATA
    
    @Query(sort: \OrdenCompra.fechaOrden, order: .reverse)
    private var ordenes: [OrdenCompra]
    
    @Query private var recepciones: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]
    
    // MARK: - FILTROS
    
    @State private var buscarProveedor = ""
    @State private var filtroEstado = "Todos"
    
    @State private var exportURL: URL?
    @State private var mostrarShare = false
    
    @State private var usarFiltroFecha = false
    @State private var fechaInicio = Date()
    @State private var fechaFin = Date()

    @State private var proveedorSeleccionado: String = "Todos los proveedores"
    @State private var anoSeleccionado: Int = 0
    @State private var mesSeleccionado: Int = 0
    @State private var usarRangoPersonalizado = false
    @State private var fechaDesde = Date()
    @State private var fechaHasta = Date()
    
    
    private let estados = ["Todos", "Vencidos", "Pendientes", "Pagados"]
    
    // MARK: - BODY
    
    var body: some View {

        NavigationStack {

            ScrollView {
                VStack(spacing: 16) {

                TextField("Buscar proveedor...", text: $buscarProveedor)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Picker("Estado", selection: $filtroEstado) {
                    ForEach(estados, id: \.self) { estado in
                        Text(estado)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Toggle("Filtrar por rango de fechas", isOn: $usarFiltroFecha)
                    .padding(.horizontal)

                if usarFiltroFecha {

                    HStack {
                        DatePicker("Inicio",
                                   selection: $fechaInicio,
                                   displayedComponents: .date)

                        DatePicker("Fin",
                                   selection: $fechaFin,
                                   displayedComponents: .date)
                    }
                    .padding(.horizontal)
                }


                // 🔵 AGING
                let aging = calcularAgingGlobal()
                let semanaActual = rangoSemanaLaboral(desplazamientoSemanas: 0)
                let semanaSiguiente = rangoSemanaLaboral(desplazamientoSemanas: 1)

                VStack(spacing: 6) {

                    agingRow(titulo: "Vigente", monto: aging.vigente, color: .blue)

                    agingRow(
                        titulo: "Semana actual (\(fechaCorta(semanaActual.inicio)) - \(fechaCorta(semanaActual.fin)))",
                        monto: aging.semanaActual,
                        color: .purple
                    )

                    agingRow(
                        titulo: "Próxima semana (\(fechaCorta(semanaSiguiente.inicio)) - \(fechaCorta(semanaSiguiente.fin)))",
                        monto: aging.semanaSiguiente,
                        color: .mint
                    )

                    agingRow(titulo: "1 - 30 días", monto: aging.dias30, color: .green)
                    agingRow(titulo: "31 - 60 días", monto: aging.dias60, color: .yellow)
                    agingRow(titulo: "61 - 90 días", monto: aging.dias90, color: .orange)
                    agingRow(titulo: "+ 90 días", monto: aging.mas90, color: .red)
                }
                .padding(.horizontal)
                .padding(.top, 6)

                // 🔵 BOTONES EXPORTACIÓN
                HStack(spacing: 12) {

                    Button {
                        generarPDF()
                    } label: {
                        Label("PDF", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }

                    Button {
                        generarExcel()
                    } label: {
                        Label("Excel", systemImage: "tablecells.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }

                    Button {
                        imprimirReporte()
                    } label: {
                        Label("Imprimir", systemImage: "printer.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                    
                    Divider()
                        .padding(.vertical, 8)

                    
                    // 🔵 HISTÓRICO FINANCIERO
                    let resumenH = resumenHistoricoReal()

                    VStack(spacing: 14) {

                        // PROVEEDOR
                        HStack {
                            Text("Proveedor")
                                .font(.subheadline)

                            Spacer()

                            Picker("", selection: $proveedorSeleccionado) {
                                Text("Todos").tag("Todos los proveedores")
                                ForEach(proveedoresUnicos(), id: \.self) { prov in
                                    Text(prov).tag(prov)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }


                        // AÑO

                    let anos = Array(
                        Set(
                            ordenes.map {
                                Calendar.current.component(.year, from: $0.fechaEntrega)
                            }
                        )
                    ).sorted()
                        
                        HStack {
                            Text("Año")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Picker("", selection: $anoSeleccionado) {
                                Text("Todos").tag(0)
                                ForEach(anos, id: \.self) { ano in
                                    Text(String(ano)).tag(ano)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                        
                        // MES
                        HStack {
                            Text("Mes")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Picker("", selection: $mesSeleccionado) {
                                Text("Todos").tag(0)
                                ForEach(1...12, id: \.self) { mes in
                                    Text(nombreMes(mes)).tag(mes)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.primary)
                        }
                        
                        Toggle("Usar rango personalizado", isOn: $usarRangoPersonalizado)
                        
                        if usarRangoPersonalizado {
                            HStack {
                                DatePicker("Desde", selection: $fechaDesde, displayedComponents: .date)
                                DatePicker("Hasta", selection: $fechaHasta, displayedComponents: .date)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Pagado")
                            Spacer()
                            Text("MX$ \(resumenH.pagado.formatoMoneda)")
                                .bold()
                        }
                        
                        HStack {
                            Text("Total Vencido")
                            Spacer()
                            Text("MX$ \(resumenH.vencido.formatoMoneda)")
                                .foregroundStyle(.red)
                                .bold()
                        }
                        
                        HStack {
                            Text("Total Por Vencer")
                            Spacer()
                            Text("MX$ \(resumenH.porVencer.formatoMoneda)")
                                .foregroundStyle(.blue)
                                .bold()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.06))
                    .cornerRadius(14)
                    .padding(.horizontal)

                
                    // 🔵 LISTA PROVEEDORES
                    LazyVStack {

                        let proveedores = proveedoresUnicos()

                        if proveedores.isEmpty {
                            Text("No hay cuentas por pagar.")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(proveedores, id: \.self) { proveedor in

                            let resumen = calcularResumen(proveedor: proveedor)

                            if mostrarSegunFiltro(resumen) {

                                NavigationLink {
                                    CxPDetalleProveedorView(
                                        proveedor: proveedor,
                                        recibosProveedor: resumen.ordenes
                                    )
                                } label: {

                                    VStack(alignment: .leading, spacing: 8) {

                                        HStack {
                                            Text(proveedor)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            if resumen.vencido > 0 {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .foregroundStyle(.red)
                                            }
                                        }

                                        Divider()

                                        ForEach(resumen.ordenes.prefix(3), id: \.persistentModelID) { orden in
                                            VStack(alignment: .leading, spacing: 2) {

                                                Text("Orden: \(orden.folio)")
                                                    .font(.caption)
                                                    .bold()
                                                    .foregroundStyle(.primary)

                                                Text("Fecha OC: \(fechaCorta(orden.fechaOrden))")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)

                                                Text("Entrega: \(fechaCorta(orden.fechaEntrega))")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }

                                        if resumen.ordenes.count > 3 {
                                            Text("+ \(resumen.ordenes.count - 3) órdenes más...")
                                                .font(.caption2)
                                                .foregroundStyle(.gray)
                                        }

                                        Divider()

                                        Text("Pendiente: MX$ \(resumen.pendiente.formatoMoneda)")
                                            .foregroundStyle(.primary)

                                        Text("Vencido: MX$ \(resumen.vencido.formatoMoneda)")
                                            .foregroundStyle(.red)

                                        Text("Total deuda: MX$ \(resumen.total.formatoMoneda)")
                                            .bold()
                                            .foregroundStyle(.primary)
                                    }
                                    .padding(14)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(14)
                                    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)

                                }
                                .buttonStyle(.plain) // 👈 evita que todo se ponga azul
                            }
                        }
                    }
                    .padding(.horizontal)

                    }       // ← CIERRA VStack(spacing:16)
                    }       // ← CIERRA ScrollView
                    .navigationTitle("Cuentas por Pagar")
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
                    }       // ← CIERRA NavigationStack
                    }       // ← CIERRA struct body
 
    
    // MARK: - AGING GLOBAL
    
    func calcularAgingGlobal() -> (
        vigente: Double,
        semanaActual: Double,
        semanaSiguiente: Double,
        dias30: Double,
        dias60: Double,
        dias90: Double,
        mas90: Double
    ) {
        
        var vigente: Double = 0
        var semanaActual: Double = 0
        var semanaSiguiente: Double = 0
        var dias30: Double = 0
        var dias60: Double = 0
        var dias90: Double = 0
        var mas90: Double = 0
        
        let calendario = Calendar.current
        let hoy = Date()
        
        let inicioSemana = calendario.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        let finSemanaLaboral = calendario.date(byAdding: .day, value: 4, to: inicioSemana) ?? hoy
        
        let inicioSemanaSiguiente = calendario.date(byAdding: .day, value: 7, to: inicioSemana) ?? hoy
        let finSemanaLaboralSiguiente = calendario.date(byAdding: .day, value: 4, to: inicioSemanaSiguiente) ?? hoy
        
        for orden in ordenes where !orden.cancelada {
            
            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let piezasRecibidas = recepcionesOrden.reduce(0) {
                $0 + Int($1.monto)
            }
            
            let piezasPedidas = orden.detalles.reduce(0) {
                $0 + $1.cantidad
            }
            
            let subtotal = orden.detalles.reduce(0) {
                $0 + $1.subtotal
            }
            
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let costoPromedio = piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
            let totalRecibido = Double(piezasRecibidas) * costoPromedio
            
            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }
            let saldo = totalRecibido - totalPagado
            
            if saldo <= 0 { continue }
            
            let vencimiento = calendario.date(
                byAdding: .day,
                value: orden.plazoDias ?? 0,
                to: orden.fechaOrden
            ) ?? hoy
            
            let dias = calendario.dateComponents([.day], from: vencimiento, to: hoy).day ?? 0
            
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
    
    func agingRow(titulo: String, monto: Double, color: Color) -> some View {
        
        HStack {
            
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(titulo)
                .font(.subheadline)
            
            Spacer()
            
            Text("MX$ \(monto.formatoMoneda)")
                .bold()
        }
    }
    
    func rangoSemanaLaboral(desplazamientoSemanas: Int = 0) -> (inicio: Date, fin: Date) {
        
        let calendario = Calendar.current
        let hoy = Date()
        
        let inicioSemana = calendario.dateInterval(of: .weekOfYear, for: hoy)?.start ?? hoy
        let inicio = calendario.date(byAdding: .day, value: desplazamientoSemanas * 7, to: inicioSemana) ?? hoy
        let fin = calendario.date(byAdding: .day, value: 4, to: inicio) ?? hoy
        
        return (inicio, fin)
    }
    
    func fechaCorta(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: fecha)
    }
    
    
    // MARK: - RESTO DE TU LÓGICA (SIN CAMBIOS)
    
    var existeDeudaVencida: Bool {
        for orden in ordenes where !orden.cancelada {
            
            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let piezasRecibidas = recepcionesOrden.reduce(0) {
                $0 + Int($1.monto)
            }
            
            let piezasPedidas = orden.detalles.reduce(0) {
                $0 + $1.cantidad
            }
            
            let subtotal = orden.detalles.reduce(0) {
                $0 + $1.subtotal
            }
            
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let costoPromedio = piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
            let totalRecibido = Double(piezasRecibidas) * costoPromedio
            
            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }
            let saldo = totalRecibido - totalPagado
            
            if saldo > 0 {
                
                let vencimiento = Calendar.current.date(
                    byAdding: .day,
                    value: orden.plazoDias ?? 0,
                    to: orden.fechaOrden
                ) ?? Date()
                
                if Date() > vencimiento {
                    return true
                }
            }
        }
        return false
    }
    
    func proveedoresUnicos() -> [String] {
        
        let activas = ordenes.filter { !$0.cancelada }
        
        let lista = activas.map {
            $0.proveedor.trimmingCharacters(in: .whitespaces)
        }
        
        let unicos = Array(Set(lista)).sorted()
        
        if buscarProveedor.isEmpty {
            return unicos
        }
        
        return unicos.filter {
            $0.lowercased().contains(buscarProveedor.lowercased())
        }
    }
    
    func mostrarSegunFiltro(
        _ resumen: (pendiente: Double, vencido: Double, total: Double, ordenes: [OrdenCompra])
    ) -> Bool {
        
        switch filtroEstado {
        case "Vencidos": return resumen.vencido > 0
        case "Pendientes": return resumen.pendiente > 0
        case "Pagados": return resumen.pendiente == 0
        default: return true
        }
    }
    
    func calcularResumen(proveedor: String) -> (
        pendiente: Double,
        vencido: Double,
        total: Double,
        ordenes: [OrdenCompra]
    ) {
        
        let ordenesProveedor = ordenes.filter {
            !$0.cancelada &&
            $0.proveedor.trimmingCharacters(in: .whitespaces) == proveedor
        }
        
        var pendiente: Double = 0
        var vencido: Double = 0
        var total: Double = 0
        
        for orden in ordenesProveedor {
            
            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let piezasRecibidas = recepcionesOrden.reduce(0) {
                $0 + Int($1.monto)
            }
            
            let piezasPedidas = orden.detalles.reduce(0) {
                $0 + $1.cantidad
            }
            
            let subtotal = orden.detalles.reduce(0) {
                $0 + $1.subtotal
            }
            
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let costoPromedio = piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
            let totalRecibido = Double(piezasRecibidas) * costoPromedio
            
            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let totalPagado = pagosOrden.reduce(0) { $0 + $1.monto }
            let saldo = totalRecibido - totalPagado
            
            total += saldo
            
            if saldo > 0 {
                
                pendiente += saldo
                
                let vencimiento = Calendar.current.date(
                    byAdding: .day,
                    value: orden.plazoDias ?? 0,
                    to: orden.fechaOrden
                ) ?? Date()
                
                if Date() > vencimiento {
                    vencido += saldo
                }
            }
        }
        
        return (pendiente, vencido, total, ordenesProveedor)
    }
    // MARK: - EXPORTACIONES
    
    func construirReporteActual() -> CuentasPorPagarReporte {

        let proveedorSeleccionado: String? =
            buscarProveedor.isEmpty ? nil : buscarProveedor

        return CuentasPorPagarReportBuilder.construirReporte(
            ordenes: ordenes,
            recepciones: recepciones,
            pagos: pagos,
            proveedorFiltro: proveedorSeleccionado,
            fechaInicio: usarFiltroFecha ? fechaInicio : nil,
            fechaFin: usarFiltroFecha ? fechaFin : nil
        )
    }
    
    func generarPDF() {
        let reporte = construirReporteActual()
        if let url = CuentasPorPagarExportManager.exportarPDF(reporte) {
            exportURL = url
            mostrarShare = true
        }
    }
    
    func generarExcel() {
        let reporte = construirReporteActual()
        if let url = CuentasPorPagarExportManager.exportarExcel(reporte) {
            exportURL = url
            mostrarShare = true
        }
    }
    
    func imprimirReporte() {
        let reporte = construirReporteActual()
        CuentasPorPagarExportManager.imprimir(reporte)
    }
    // MARK: - HISTÓRICO PROVEEDOR

    func historicoProveedor(nombre: String) -> [Int: [Int: (comprado: Double, pagado: Double)]] {
        
        var resultado: [Int: [Int: (Double, Double)]] = [:]
        let calendar = Calendar.current
        
        // 🔵 COMPRADO
        let ordenesProveedor = ordenes.filter {
            !$0.cancelada &&
            $0.proveedor.trimmingCharacters(in: .whitespaces) == nombre
        }
        
        for orden in ordenesProveedor {
            
            let year = calendar.component(.year, from: orden.fechaOrden)
            let month = calendar.component(.month, from: orden.fechaOrden)
            
            let subtotal = orden.detalles.reduce(0) { $0 + $1.subtotal }
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            
            resultado[year, default: [:]][month, default: (0,0)].0 += totalPedido
        }
        
        // 🔵 PAGADO
        let pagosProveedor = pagos.filter {
            $0.recibo?.ordenCompra?.proveedor == nombre &&
            $0.fechaEliminacion == nil
        }
        
        for pago in pagosProveedor {
            
            let year = calendar.component(.year, from: pago.fechaPago)
            let month = calendar.component(.month, from: pago.fechaPago)
            
            resultado[year, default: [:]][month, default: (0,0)].1 += pago.monto
        }
        
        return resultado
    }

    func nombreMes(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.monthSymbols[mes - 1].capitalized
    }
    // MARK: - RESUMEN SIMPLE POR RECEPCIÓN

    // MARK: - RESUMEN HISTÓRICO REAL

    func resumenHistoricoReal() -> (pagado: Double, vencido: Double, porVencer: Double) {
        
        var totalPagado: Double = 0
        var totalVencido: Double = 0
        var totalPorVencer: Double = 0
        
        let hoy = Date()
        let calendar = Calendar.current
        
        for orden in ordenes where !orden.cancelada {
            
            // 🔹 FILTRO PROVEEDOR
            if proveedorSeleccionado != "Todos los proveedores" &&
                orden.proveedor.trimmingCharacters(in: .whitespaces) != proveedorSeleccionado {
                continue
            }
            
            // 🔹 FILTRO FECHA (usamos fechaEntrega)
            let fechaBase = orden.fechaEntrega
            
            if usarRangoPersonalizado {
                if fechaBase < fechaDesde || fechaBase > fechaHasta { continue }
            } else {
                if anoSeleccionado != 0 {
                    if calendar.component(.year, from: fechaBase) != anoSeleccionado { continue }
                }
                if mesSeleccionado != 0 {
                    if calendar.component(.month, from: fechaBase) != mesSeleccionado { continue }
                }
            }
            
            // 🔹 TOTAL RECIBIDO (misma lógica que ya usas)
            let recepcionesOrden = recepciones.filter {
                $0.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let piezasRecibidas = recepcionesOrden.reduce(0) { $0 + Int($1.monto) }
            
            let piezasPedidas = orden.detalles.reduce(0) { $0 + $1.cantidad }
            let subtotal = orden.detalles.reduce(0) { $0 + $1.subtotal }
            
            let totalPedido = orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let costoPromedio = piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
            let totalRecibido = Double(piezasRecibidas) * costoPromedio
            
            // 🔹 PAGOS
            let pagosOrden = pagos.filter {
                $0.recibo?.ordenCompra == orden &&
                $0.fechaEliminacion == nil
            }
            
            let pagado = pagosOrden.reduce(0) { $0 + $1.monto }
            totalPagado += pagado
            
            let saldo = totalRecibido - pagado
            if saldo <= 0 { continue }
            
            // 🔹 VENCIMIENTO = ENTREGA + PLAZO
            let vencimiento = calendar.date(
                byAdding: .day,
                value: orden.plazoDias ?? 0,
                to: orden.fechaEntrega
            ) ?? hoy
            
            if hoy > vencimiento {
                totalVencido += saldo
            } else {
                totalPorVencer += saldo
            }
        }
        
        return (totalPagado, totalVencido, totalPorVencer)
    }
}

