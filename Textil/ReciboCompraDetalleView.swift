//
//  ReciboCompraDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//
//
//  ReciboCompraDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//

import SwiftUI
import SwiftData
import UIKit

struct ReciboCompraDetalleView: View {

    @Environment(\.modelContext) private var context

    let orden: OrdenCompra
    @State private var recibo: ReciboProduccion?

    let usuarioActual = "Salomon Senado"

    // Sheets
    @State private var showCodigoSheet = false
    @State private var showPagoSheet = false
    @State private var showRecepcionSheet = false

    // Seguridad
    @State private var accionPendiente: AccionSegura?
    @State private var codigoIngresado = ""
    private let codigoSeguridad = "1234"

    // Alertas
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""

    // Share
    @State private var mostrarShare = false
    @State private var archivoURL: URL?
    
    @State private var numeroFacturaNota: String = ""
    
    @State private var detalleSeleccionado: OrdenCompraDetalle?

    enum AccionSegura {
        case registrarRecepcion
        case registrarPago
        case eliminarRecepcion(ReciboCompraDetalle)
        case eliminarPago(PagoRecibo)
    }

    // DATA
    @Query private var recepciones: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]
    
    
    // 🔒 BLOQUEO SOLO VISUAL
    var bloqueada: Bool {
        orden.cancelada
    }

    // MARK: - BODY

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resumenCard
                facturaBar
                conceptoCard
                recepcionesCard
                pagosCard
                exportarCard
                movimientosCard
            }
            .padding()
        }
        .navigationTitle("Recibo Compras")
        .onAppear { prepararRecibo() }

        // ALERTA
        .alert("Acción realizada", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mensajeAlerta)
        }

        // ============================
        // CÓDIGO DE SEGURIDAD
        // ============================
        .sheet(isPresented: $showCodigoSheet) {
            VStack(spacing: 20) {

                Text("Código de seguridad")
                    .font(.headline)

                SecureField("Código", text: $codigoIngresado)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

                Button("Confirmar") {
                    validarCodigo()
                }
                .buttonStyle(.borderedProminent)

                Button("Cancelar", role: .cancel) {
                    codigoIngresado = ""
                    accionPendiente = nil
                    showCodigoSheet = false
                }
            }
            .padding()
        }

        // ============================
        // REGISTRAR RECEPCIÓN COMPRA ✅
        // ============================
        .sheet(isPresented: $showRecepcionSheet) {

            RegistrarRecepcionCompraSheet { monto, obs in

                guard let recibo,
                      let detalle = detalleSeleccionado
                else { return }

                let nuevo = ReciboCompraDetalle(
                    concepto: "Recepción",
                    monto: monto,
                    modelo: detalle.modelo,
                    articulo: detalle.articulo,
                    recibo: recibo,
                    ordenCompra: orden
                )

                nuevo.observaciones = obs
                context.insert(nuevo)

                DispatchQueue.main.async {
                    try? context.save()
                    showRecepcionSheet = false
                }
            }
        }

        // ============================
        // REGISTRAR PAGO
        // ============================
        .sheet(isPresented: $showPagoSheet) {
            RegistrarPagoSheet { monto, obs in

                guard let recibo else { return }

                let pago = PagoRecibo(
                    monto: monto,
                    observaciones: obs,
                    recibo: recibo
                )

                context.insert(pago)

                DispatchQueue.main.async {
                    try? context.save()
                    showPagoSheet = false
                }
            }
        }

        // ============================
        // SHARE
        // ============================
        .sheet(isPresented: $mostrarShare) {
            if let url = archivoURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - RESUMEN (HEADER CORREGIDO)

    var resumenCard: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {

                Text("Orden de compra")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))

                Text(orden.folio)
                    .font(.title2.bold())

                Divider()

                fila("Proveedor", orden.proveedor)
                fila(
                    "Fecha orden",
                    orden.fechaOrden.formatted(date: .abbreviated, time: .omitted)
                )
                fila(
                    "Fecha entrega",
                    orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted)
                )
                fila("Tipo", orden.tipoCompra.capitalized)

                Divider()

                Text(formatoMX(totalRecibidoMX))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.green)

                Divider()

                fila("Subtotal", formatoMX(subtotalPedido))
                fila("IVA", formatoMX(ivaPedido))
                fila("Total pedido", formatoMX(totalPedido))

                Divider()

                fila("Recibido", "\(piezasRecibidas) / \(piezasPedidas) PZ")
                fila("Pagado", formatoMX(totalPagado))
                fila(
                    "Saldo pendiente",
                    formatoMX(max(totalRecibidoMX - totalPagado, 0)),
                    color: totalRecibidoMX - totalPagado <= 0 ? .green : .primary
                )
            }
        }
    }
    var facturaBar: some View {
        card {
            HStack {

                Text("# Factura / Nota")
                    .font(.caption)
                    .foregroundColor(Color(uiColor: .secondaryLabel))


                Spacer()

                TextField(
                    "# De Factura / Nota",
                    text: Binding(
                        get: { recibo?.numeroFacturaNota ?? "" },
                        set: { nuevoValor in
                            if !bloqueada {
                                recibo?.numeroFacturaNota = nuevoValor
                                try? context.save()
                            }
                        }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .autocapitalization(.allCharacters)
                .disabled(bloqueada)
                .opacity(bloqueada ? 0.5 : 1)
            }
        }
    }
    
    // MARK: - CONCEPTO / SERVICIO

    var conceptoCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {

                Text("Modelos / Servicios")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(orden.detalles, id: \.persistentModelID) { d in

                    Text("Modelo: \(d.modelo)")
                        .font(.title2.bold())

                    if !d.articulo.isEmpty {
                        Text(d.articulo)
                            .font(.caption)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Divider()

                    // 🔹 CÁLCULOS POR MODELO
                    let recibidas = piezasRecibidasPorModelo(d)
                    let pendientes = max(d.cantidad - recibidas, 0)

                    fila("Cantidad pedida", "\(d.cantidad)")
                    fila("Recibidas", "\(recibidas)")
                    fila(
                        "Pendiente",
                        "\(pendientes)",
                        color: pendientes == 0 ? .green : .primary
                    )
                    fila("Subtotal", formatoMX(d.subtotal))

                    // =========================
                    // RECEPCIONES DE ESTE MODELO
                    // =========================
                    let recepcionesModelo = recepcionesActivasPorModelo(d.modelo)

                    if !recepcionesModelo.isEmpty {

                        Divider()

                        Text("Recepciones")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(recepcionesModelo, id: \.persistentModelID) { r in
                            HStack {
                                Text(
                                    r.recibo?.fechaRecibo.formatted(
                                        date: .abbreviated,
                                        time: .omitted
                                    ) ?? ""
                                )
                                Spacer()
                                Text("\(Int(r.monto)) PZ")
                                    .fontWeight(.semibold)
                            }

                            if !r.observaciones.isEmpty {
                                Text(r.observaciones)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if d.persistentModelID != orden.detalles.last?.persistentModelID {
                        Divider()
                    }
                }
            }
        }
    }

    
    // MARK: - RECEPCIONES

    var recepcionesCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {

                Text("Recepciones")
                    .font(.headline)

                ForEach(recepcionesActivas, id: \.persistentModelID) { r in
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text(
                                r.recibo?.fechaRecibo.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                ) ?? ""
                            )
                            Spacer()
                            Text("\(Int(r.monto)) PZ")
                                .fontWeight(.semibold)
                        }

                        // ✅ OBSERVACIONES
                        if !r.observaciones.isEmpty {
                            Text(r.observaciones)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button(role: .destructive) {
                            accionPendiente = .eliminarRecepcion(r)
                            showCodigoSheet = true
                        } label: {
                            Label("Eliminar recepción", systemImage: "trash")
                        }
                        .font(.caption)
                        .disabled(bloqueada)
                        .opacity(bloqueada ? 0.4 : 1)

                        Divider()
                    }
                }

                ForEach(orden.detalles, id: \.self) { d in
                    Button {
                        detalleSeleccionado = d
                        accionPendiente = .registrarRecepcion
                        showCodigoSheet = true
                    } label: {
                        Label("Registrar recepción \(d.modelo)", systemImage: "plus.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(bloqueada)
                    .opacity(bloqueada ? 0.4 : 1)
                }

                .buttonStyle(.bordered)
                .disabled(bloqueada)
                .opacity(bloqueada ? 0.4 : 1)
            }
        }
    }

    // MARK: - PAGOS

    var pagosCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {

                Text("Pagos")
                    .font(.headline)

                ForEach(pagosActivos, id: \.persistentModelID) { p in
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text(
                                p.fechaPago.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                            Spacer()
                            Text(formatoMX(p.monto))
                                .fontWeight(.semibold)
                        }

                        // ✅ OBSERVACIONES
                        if !p.observaciones.isEmpty {
                            Text(p.observaciones)
                                .font(.caption)
                                .foregroundColor(Color(uiColor: .secondaryLabel))
                        }

                        Button(role: .destructive) {
                            accionPendiente = .eliminarPago(p)
                            showCodigoSheet = true
                        } label: {
                            Label("Eliminar pago", systemImage: "trash")
                        }
                        .font(.caption)
                        .disabled(bloqueada)
                        .opacity(bloqueada ? 0.4 : 1)

                        Divider()
                    }
                }

                Button {
                    accionPendiente = .registrarPago
                    showCodigoSheet = true
                } label: {
                    Label("Registrar pago", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .disabled(bloqueada)
                .opacity(bloqueada ? 0.4 : 1)
            }
        }
    }

    // MARK: - EXPORTAR

    var exportarCard: some View {
        card {
            HStack(spacing: 12) {
                Button("Excel") { exportarExcel() }.buttonStyle(.bordered)
                Button("PDF") { exportarPDF() }.buttonStyle(.bordered)
                Button("Imprimir") { imprimir() }.buttonStyle(.bordered)
            }
        }
    }

    // MARK: - MOVIMIENTOS

    struct Movimiento: Identifiable {
        let id = UUID()
        let titulo: String
        let usuario: String
        let fecha: Date
        let icono: String
        let color: Color
    }

    var movimientos: [Movimiento] {
        var items: [Movimiento] = []

        // ===============================
        // FACTURA / NOTA
        // ===============================
        if let factura = recibo?.numeroFacturaNota,
           !factura.isEmpty {

            items.append(
                Movimiento(
                    titulo: "Factura / Nota asignada: \(factura)",
                    usuario: usuarioActual,
                    fecha: recibo?.fechaRecibo ?? Date(),
                    icono: "doc.text.fill",
                    color: .purple
                )
            )
        }

        // ===============================
        // RECEPCIONES
        // ===============================
        for r in recepciones where r.ordenCompra == orden {

            let eliminado = r.fechaEliminacion != nil

            items.append(
                Movimiento(
                    titulo: eliminado
                        ? "Recepción eliminada (\(Int(r.monto)) PZ)"
                        : "Recepción registrada (\(Int(r.monto)) PZ)",
                    usuario: r.usuarioEliminacion ?? "Sistema",
                    fecha: r.fechaEliminacion ?? r.recibo?.fechaRecibo ?? Date(),
                    icono: eliminado ? "trash.fill" : "shippingbox.fill",
                    color: eliminado ? .red : .blue
                )
            )
        }

        // ===============================
        // PAGOS
        // ===============================
        for p in pagos
        where p.recibo == recibo && p.recibo?.ordenCompra == orden {

            let eliminado = p.fechaEliminacion != nil

            items.append(
                Movimiento(
                    titulo: eliminado
                        ? "Pago eliminado (\(formatoMX(p.monto)))"
                        : "Pago registrado (\(formatoMX(p.monto)))",
                    usuario: p.usuarioEliminacion ?? "Sistema",
                    fecha: p.fechaEliminacion ?? p.fechaPago,
                    icono: eliminado ? "trash.fill" : "creditcard.fill",
                    color: eliminado ? .red : .green
                )
            )
        }

        // MISMO ORDEN QUE PRODUCCIÓN (más reciente primero)
        return items.sorted { $0.fecha > $1.fecha }
    }

    @ViewBuilder
    var movimientosCard: some View {
        Group {
            if !movimientos.isEmpty {
                card {
                    VStack(alignment: .leading, spacing: 14) {

                        Text("Movimientos de la orden")
                            .font(.headline)

                        ForEach(movimientos) { mov in
                            VStack(alignment: .leading, spacing: 0) {

                                HStack(alignment: .top, spacing: 12) {

                                    Image(systemName: mov.icono)
                                        .foregroundStyle(mov.color)

                                    VStack(alignment: .leading, spacing: 4) {

                                        Text(mov.titulo)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Text("Usuario: \(mov.usuario)")
                                            .font(.caption)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))


                                        Text(
                                            mov.fecha.formatted(
                                                date: .abbreviated,
                                                time: .shortened
                                            )
                                        )
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Divider()
                            }
                        }
                    }
                }
            } else {
                card {
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Movimientos de la orden")
                            .font(.headline)

                        Text("Sin movimientos registrados")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - DATA (AGREGADO)

    var recepcionesActivas: [ReciboCompraDetalle] {
        recepciones.filter {
            $0.ordenCompra == orden &&
            $0.fechaEliminacion == nil
        }
    }

    func recepcionesActivasPorModelo(_ modelo: String) -> [ReciboCompraDetalle] {
        recepciones.filter {
            $0.ordenCompra == orden &&
            $0.modelo == modelo &&
            $0.fechaEliminacion == nil
        }
    }

    var pagosActivos: [PagoRecibo] {
        pagos.filter {
            $0.recibo == recibo &&
            $0.recibo?.ordenCompra == orden &&
            $0.fechaEliminacion == nil
        }
    }

    var totalPagado: Double {
        pagosActivos.reduce(0) { $0 + $1.monto }
    }

    // 🔽 CÁLCULOS DE PIEZAS

    var piezasPedidas: Int {
        orden.detalles.reduce(0) { $0 + $1.cantidad }
    }

    var piezasRecibidas: Int {
        recepcionesActivas.reduce(0) { $0 + Int($1.monto) }
    }

    // 🔽 COSTOS

    var costoPromedio: Double {
        let totalPedido = orden.detalles.reduce(0) { $0 + $1.subtotal }
        return piezasPedidas == 0 ? 0 : totalPedido / Double(piezasPedidas)
    }

    var totalRecibidoMX: Double {
        Double(piezasRecibidas) * costoPromedio
    }

    // 🔽 TOTALES DE LA ORDEN

    var subtotalPedido: Double {
        orden.detalles.reduce(0) { $0 + $1.subtotal }
    }

    var ivaPedido: Double {
        orden.aplicaIVA ? subtotalPedido * 0.16 : 0
    }

    var totalPedido: Double {
        subtotalPedido + ivaPedido
    }

    // 🔽 RECEPCIONES POR MODELO (POR AHORA GLOBAL)

    func piezasRecibidasPorModelo(_ detalle: OrdenCompraDetalle) -> Int {
        recepcionesActivasPorModelo(detalle.modelo)
            .reduce(0) { $0 + Int($1.monto) }
    }

    // MARK: - RECIBO

    func prepararRecibo() {
        if let existente = try? context.fetch(
            FetchDescriptor<ReciboProduccion>()
        ).first(where: {
            $0.ordenCompra == orden && !$0.cancelado
        }) {
            recibo = existente
            return
        }

        let nuevo = ReciboProduccion(
            produccion: nil,
            fechaRecibo: Date(),
            ordenCompra: orden
        )

        context.insert(nuevo)
        try? context.save()
        recibo = nuevo
    }

    // MARK: - SEGURIDAD

    func validarCodigo() {
        guard codigoIngresado == codigoSeguridad else {
            codigoIngresado = ""
            return
        }

        showCodigoSheet = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            switch accionPendiente {
            case .registrarRecepcion:
                showRecepcionSheet = true
            case .registrarPago:
                showPagoSheet = true
            case .eliminarRecepcion(let r):
                r.usuarioEliminacion = usuarioActual
                r.fechaEliminacion = Date()
                try? context.save()
                mensajeAlerta = "Recepción eliminada"
                mostrarAlerta = true
            case .eliminarPago(let p):
                p.usuarioEliminacion = usuarioActual
                p.fechaEliminacion = Date()
                try? context.save()
                mensajeAlerta = "Pago eliminado"
                mostrarAlerta = true
            case .none:
                break
            }

            codigoIngresado = ""
            accionPendiente = nil
        }
    }

    // MARK: - EXPORTS

    // MARK: - TEXTO COMPLETO RECIBO COMPRA

    func textoCompletoReciboCompra() -> String {

        var texto = ""

        // ===============================
        // ENCABEZADO
        // ===============================
        texto += "RECIBO DE COMPRA\n"
        texto += "Folio: \(orden.folio)\n"
        texto += "Proveedor: \(orden.proveedor)\n"
        texto += "Fecha orden: \(orden.fechaOrden.formatted())\n"
        texto += "Fecha entrega: \(orden.fechaEntrega.formatted())\n"
        texto += "Tipo: \(orden.tipoCompra)\n"

        // 👇 NUEVO
        texto += "Factura / Nota: \(recibo?.numeroFacturaNota ?? "—")\n\n"

        // ===============================
        // ARTÍCULOS / SERVICIOS
        // ===============================
        texto += "DETALLE DE LA ORDEN\n"
        for d in orden.detalles {
            texto += "- \(d.articulo) | Modelo: \(d.modelo) | Cant: \(d.cantidad) | \(formatoMX(d.subtotal))\n"
        }
        texto += "\n"

        // ===============================
        // RESUMEN ECONÓMICO
        // ===============================
        texto += "RESUMEN ECONÓMICO\n"
        texto += "Subtotal pedido: \(formatoMX(subtotalPedido))\n"
        texto += "IVA: \(formatoMX(ivaPedido))\n"
        texto += "Total pedido: \(formatoMX(totalPedido))\n\n"

        texto += "Piezas pedidas: \(piezasPedidas)\n"
        texto += "Piezas recibidas: \(piezasRecibidas)\n"
        texto += "Total recibido: \(formatoMX(totalRecibidoMX))\n"
        texto += "Pagado: \(formatoMX(totalPagado))\n"
        texto += "Saldo pendiente: \(formatoMX(max(totalRecibidoMX - totalPagado, 0)))\n\n"

        // ===============================
        // RECEPCIONES
        // ===============================
        texto += "RECEPCIONES\n"
        for r in recepciones {
            let estado = r.fechaEliminacion == nil ? "ACTIVA" : "ELIMINADA"
            texto += "- \(r.recibo?.fechaRecibo.formatted() ?? "") | \(Int(r.monto)) PZ | \(estado)\n"
        }
        texto += "\n"

        // ===============================
        // PAGOS
        // ===============================
        texto += "PAGOS\n"
        for p in pagos where p.recibo?.ordenCompra == orden {
            let estado = p.fechaEliminacion == nil ? "ACTIVO" : "ELIMINADO"
            texto += "- \(p.fechaPago.formatted()) | \(formatoMX(p.monto)) | \(estado)\n"
        }
        texto += "\n"

        // ===============================
        // MOVIMIENTOS
        // ===============================
        texto += "MOVIMIENTOS\n"
        for m in movimientos {
            texto += "- \(m.fecha.formatted()) | \(m.titulo)\n"
        }

        return texto
    }
    
    func exportarExcel() {

        var csv = ""

        // ===============================
        // ENCABEZADO ORDEN
        // ===============================
        csv += "RECIBO DE COMPRA\n"
        csv += "Folio,\(orden.folio)\n"
        csv += "Proveedor,\(orden.proveedor)\n"
        csv += "Fecha orden,\(orden.fechaOrden.formatted())\n"
        csv += "Fecha entrega,\(orden.fechaEntrega.formatted())\n"
        csv += "Tipo,\(orden.tipoCompra)\n"

        // 👇 NUEVO
        csv += "Factura / Nota,\(recibo?.numeroFacturaNota ?? "")\n\n"

        // ===============================
        // ARTÍCULOS / SERVICIOS
        // ===============================
        csv += "DETALLE DE LA ORDEN\n"
        csv += "Articulo,Modelo,Cantidad,Subtotal\n"
        for d in orden.detalles {
            csv += "\(d.articulo),\(d.modelo),\(d.cantidad),\(d.subtotal)\n"
        }
        csv += "\n"

        // ===============================
        // RESUMEN ECONÓMICO
        // ===============================
        csv += "RESUMEN ECONOMICO\n"
        csv += "Subtotal pedido,\(subtotalPedido)\n"
        csv += "IVA,\(ivaPedido)\n"
        csv += "Total pedido,\(totalPedido)\n"
        csv += "Piezas pedidas,\(piezasPedidas)\n"
        csv += "Piezas recibidas,\(piezasRecibidas)\n"
        csv += "Total recibido,\(totalRecibidoMX)\n"
        csv += "Pagado,\(totalPagado)\n"
        csv += "Saldo pendiente,\(max(totalRecibidoMX - totalPagado, 0))\n\n"

        // ===============================
        // RECEPCIONES
        // ===============================
        csv += "RECEPCIONES\n"
        csv += "Fecha,Piezas,Estado\n"
        for r in recepciones {
            let estado = r.fechaEliminacion == nil ? "ACTIVA" : "ELIMINADA"
            csv += "\(r.recibo?.fechaRecibo.formatted() ?? ""),\(Int(r.monto)),\(estado)\n"
        }
        csv += "\n"

        // ===============================
        // PAGOS
        // ===============================
        csv += "PAGOS\n"
        csv += "Fecha,Monto,Estado\n"
        for p in pagos where p.recibo?.ordenCompra == orden {
            let estado = p.fechaEliminacion == nil ? "ACTIVO" : "ELIMINADO"
            csv += "\(p.fechaPago.formatted()),\(p.monto),\(estado)\n"
        }
        csv += "\n"

        // ===============================
        // MOVIMIENTOS
        // ===============================
        csv += "MOVIMIENTOS\n"
        csv += "Fecha,Descripcion\n"
        for m in movimientos {
            csv += "\(m.fecha.formatted()),\(m.titulo)\n"
        }

        // ===============================
        // EXPORTAR
        // ===============================
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Compras.csv")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)

            DispatchQueue.main.async {
                archivoURL = url
                mostrarShare = true
            }

        } catch {
            print("Error exportando Excel")
        }
    }

    func exportarPDF() {
        let texto = textoCompletoReciboCompra()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Compras.pdf")

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 612, height: 792)
        )

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                texto.draw(
                    in: CGRect(x: 40, y: 40, width: 532, height: 712),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
                )
            }
            archivoURL = url
            mostrarShare = true
        } catch {
            print("Error PDF")
        }
    }

    func imprimir() {

        let texto = textoCompletoReciboCompra()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Compras_Impresion.pdf")

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 612, height: 792)
        )

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                texto.draw(
                    in: CGRect(x: 40, y: 40, width: 532, height: 712),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
                )
            }

            let controller = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)
            info.outputType = .general
            info.jobName = "Recibo Compra"

            controller.printInfo = info
            controller.printingItem = url
            controller.present(animated: true)

        } catch {
            print("Error al imprimir")
        }
    }

    // MARK: - HELPERS

    func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
    }

    func fila(_ t: String, _ v: String, color: Color = .primary) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v)
                .foregroundStyle(color)
        }
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }

    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: Context
        ) {}
    }
}
