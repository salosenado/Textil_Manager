//
//  OrdenClienteDetalleEditableView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//
import SwiftUI
import SwiftData
import UIKit

struct OrdenClienteDetalleEditableView: View {

    // MARK: - ENV
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var orden: OrdenCliente

    // MARK: - SEGURIDAD
    private let codigoSeguridad = "1234"
    @State private var mostrarCodigo = false
    @State private var codigoIngresado = ""
    @State private var accionPendiente: Accion?
    @State private var modoEdicion = false

    enum Accion {
        case editar
        case eliminarModelo(OrdenClienteDetalle)
        case cancelar
        case cambiarIVA
    }

    // MARK: - EXPORT
    @State private var pdfURL: URL?
    @State private var excelURL: URL?

    // MARK: - BLOQUEO PRODUCCIÓN
    var ordenBloqueada: Bool {
        orden.detalles.contains {
            ($0.produccion?.pzCortadas ?? 0) > 0 ||
            !($0.produccion?.maquilero ?? "").isEmpty
        }
    }

    // MARK: - BODY
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    detalle
                    modelos
                    ivaToggle
                    totales
                    observaciones
                    accionesExportar
                    movimientos
                    botonesInferiores
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Detalle del pedido")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .alert("Código de seguridad", isPresented: $mostrarCodigo) {
                SecureField("Código", text: $codigoIngresado)
                Button("Cancelar", role: .cancel) { codigoIngresado = "" }
                Button("Confirmar") { validarCodigo() }
            }
            .onAppear {
                registrarMovimientoInicial()
            }
        }
    }

    // MARK: - DETALLE
    var detalle: some View {
        VStack(alignment: .leading, spacing: 8) {
            fila("Venta", "Venta #\(String(format: "%06d", orden.numeroVenta))")
            fila("Cliente", orden.cliente)
            fila(
                "Agente",
                orden.agente.map { "\($0.nombre) \($0.apellido)" } ?? "—"
            )
            fila("Pedido", orden.numeroPedidoCliente)
            fila("Captura", orden.fechaCreacion.formatted(date: .abbreviated, time: .omitted))
            fila("Entrega", orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted))

            if ordenBloqueada {
                Text("ORDEN BLOQUEADA POR PRODUCCIÓN")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }

            if orden.cancelada {
                Text("ORDEN CANCELADA")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
        .cardWhite()
    }

    // MARK: - MODELOS
    var modelos: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Modelos")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach($orden.detalles) { $detalle in
                VStack(alignment: .leading, spacing: 12) {

                    // MODELO + ELIMINAR
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {

                            Text(detalle.modelo)
                                .font(.headline)

                            if let descripcion = detalle.modeloCatalogo?.descripcion,
                               !descripcion.isEmpty {

                                Text(descripcion)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            solicitarEliminar(detalle)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(!modoEdicion || ordenBloqueada || orden.cancelada)
                    }

                    // CANTIDAD / COSTO
                    HStack {

                        campoEntero(
                            "Cantidad",
                            value: $detalle.cantidad,
                            enabled: modoEdicion && !ordenBloqueada && !orden.cancelada
                        )

                        campoCosto(
                            value: $detalle.precioUnitario,
                            enabled: modoEdicion && !ordenBloqueada && !orden.cancelada
                        )
                    }

                    // SUBTOTAL
                    HStack {
                        Spacer()
                        Text(formatoMX(detalle.subtotal))
                            .font(.title3.bold())
                    }
                }
                .cardWhite()
            }
        }
    }


    // MARK: - IVA
    var ivaToggle: some View {
        Toggle(
            "Aplicar IVA (16%)",
            isOn: Binding(
                get: { orden.aplicaIVA },
                set: { _ in solicitarCambioIVA() }
            )
        )
        .disabled(ordenBloqueada || orden.cancelada)
        .padding()
        .cardWhite()
    }

    // MARK: - TOTALES
    var totales: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Totales")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                fila("Subtotal", formatoMX(orden.subtotal))
                fila("IVA", formatoMX(orden.iva))

                Divider()

                HStack {
                    Text("Total").fontWeight(.bold)
                    Spacer()
                    Text(formatoMX(orden.total))
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .cardWhite()
        }
    }

    // MARK: - OBSERVACIONES (VISUAL)
    var observaciones: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observaciones").font(.headline)
            TextEditor(text: .constant(""))
                .frame(height: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .disabled(true)
        }
    }

    // MARK: - EXPORT
    var accionesExportar: some View {
        VStack(spacing: 12) {

            if let pdf = generarPDF() {
                ShareLink(item: pdf) {
                    boton("Exportar PDF", .red)
                }
            }

            if let excel = generarExcel() {
                ShareLink(item: excel) {
                    boton("Exportar Excel", .green)
                }
            }

            Button {
                imprimir()
            } label: {
                boton("Imprimir", .blue)
            }
        }
    }

    // MARK: - MOVIMIENTOS (DESDE SWIFTDATA)
    var movimientos: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Movimientos de la orden")
                .font(.headline)

            VStack(spacing: 0) {

                ForEach(
                    orden.movimientos.sorted { $0.fecha > $1.fecha }
                ) { mov in

                    HStack(alignment: .top, spacing: 12) {

                        Image(systemName: mov.icono)
                            .foregroundStyle(Color(hex: mov.colorHex))
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {

                            Text(mov.titulo)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Usuario: \(mov.usuario)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(
                                mov.fecha.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)

                    Divider()
                }
            }
            .padding()
            .cardWhite()
        }
    }

    // MARK: - BOTONES
    var botonesInferiores: some View {
        HStack(spacing: 12) {

            Button {
                solicitarEdicion()
            } label: {
                boton(modoEdicion ? "Editando…" : "Editar", .orange)
            }
            .disabled(ordenBloqueada || orden.cancelada)

            if !orden.cancelada {
                Button(role: .destructive) {
                    solicitarCancelacion()
                } label: {
                    boton("Cancelar pedido", .red)
                }
                .disabled(ordenBloqueada)
            }
        }
    }

    // MARK: - ACCIONES
    func solicitarEdicion() {
        accionPendiente = .editar
        mostrarCodigo = true
    }

    func solicitarEliminar(_ detalle: OrdenClienteDetalle) {
        accionPendiente = .eliminarModelo(detalle)
        mostrarCodigo = true
    }

    func solicitarCancelacion() {
        accionPendiente = .cancelar
        mostrarCodigo = true
    }

    func solicitarCambioIVA() {
        accionPendiente = .cambiarIVA
        mostrarCodigo = true
    }

    func validarCodigo() {
        guard codigoIngresado == codigoSeguridad else {
            codigoIngresado = ""
            return
        }
        codigoIngresado = ""
        ejecutarAccion()
    }

    func ejecutarAccion() {
        switch accionPendiente {

        case .editar:
            modoEdicion = true
            registrarMovimiento(
                titulo: "Edición habilitada",
                detalle: "Se habilitó edición del pedido",
                icono: "pencil",
                color: "#FFA500"
            )

        case .eliminarModelo(let detalle):
            if let i = orden.detalles.firstIndex(where: { $0.id == detalle.id }) {
                orden.detalles.remove(at: i)
                registrarMovimiento(
                    titulo: "Modelo eliminado",
                    detalle: detalle.modelo,
                    icono: "trash",
                    color: "#FF3B30"
                )
            }

        case .cancelar:
            orden.cancelada = true
            orden.usuarioCancelacion = "Admin"
            orden.fechaCancelacion = Date()
            modoEdicion = false

            registrarMovimiento(
                titulo: "Pedido cancelado",
                detalle: "La orden fue cancelada",
                icono: "xmark.circle",
                color: "#FF3B30"
            )

        case .cambiarIVA:
            orden.aplicaIVA.toggle()
            registrarMovimiento(
                titulo: "Cambio de IVA",
                detalle: orden.aplicaIVA ? "IVA aplicado" : "IVA retirado",
                icono: "percent",
                color: "#34C759"
            )

        case .none:
            break
        }

        try? context.save()
    }

    // MARK: - MOVIMIENTOS HELPERS
    func registrarMovimiento(
        titulo: String,
        detalle: String,
        icono: String,
        color: String
    ) {
        let mov = MovimientoPedido(
            titulo: titulo,
            detalle: detalle,
            usuario: "Admin",
            icono: icono,
            colorHex: color,
            orden: orden
        )
        orden.movimientos.append(mov)
        context.insert(mov)
    }

    func registrarMovimientoInicial() {
        if orden.movimientos.isEmpty {
            registrarMovimiento(
                titulo: "Pedido creado",
                detalle: "Alta del pedido",
                icono: "doc.text",
                color: "#007AFF"
            )
        }
    }

    // MARK: - EXPORT
    func generarPDF() -> URL? {

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Pedido_\(orden.numeroVenta).pdf")

        try? renderer.writePDF(to: url) { ctx in
            ctx.beginPage()

            var y: CGFloat = 24

            func draw(_ text: String, bold: Bool = false, size: CGFloat = 12) {
                let font = bold
                    ? UIFont.boldSystemFont(ofSize: size)
                    : UIFont.systemFont(ofSize: size)

                text.draw(
                    at: CGPoint(x: 24, y: y),
                    withAttributes: [.font: font]
                )
                y += size + 6
            }

            // ===== TÍTULO =====
            draw("PEDIDO DE CLIENTE", bold: true, size: 20)
            y += 8

            // ===== DATOS ORDEN =====
            draw("Venta: \(String(format: "%06d", orden.numeroVenta))", bold: true)
            draw("Cliente: \(orden.cliente)")
            draw("Agente: \(orden.agente?.nombre ?? "") \(orden.agente?.apellido ?? "")")
            draw("Pedido cliente: \(orden.numeroPedidoCliente)")
            draw("Fecha captura: \(orden.fechaCreacion.formatted(date: .abbreviated, time: .omitted))")
            draw("Fecha entrega: \(orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")

            if orden.cancelada {
                y += 6
                draw("ESTADO: CANCELADO", bold: true)
            }

            y += 14

            // ===== MODELOS =====
            draw("MODELOS", bold: true)
            y += 6

            for d in orden.detalles {
                draw("Modelo: \(d.modelo)", bold: true)
                draw("Cantidad: \(d.cantidad)")
                draw("Costo unitario: \(formatoMX(d.precioUnitario))")
                draw("Subtotal modelo: \(formatoMX(d.subtotal))")
                y += 6
            }

            y += 10

            // ===== TOTALES =====
            draw("Subtotal: \(formatoMX(orden.subtotal))", bold: true)
            draw("IVA: \(formatoMX(orden.iva))", bold: true)
            draw("TOTAL: \(formatoMX(orden.total))", bold: true)

            y += 20

            // ===== PIE DE PÁGINA =====
            draw("Documento generado el \(Date().formatted(date: .abbreviated, time: .shortened))", size: 10)
            draw("Usuario: Sistema", size: 10)
        }

        return url
    }


    func generarExcel() -> URL? {

        var csv =
        """
        Venta,Cliente,Agente,Pedido,Fecha Captura,Fecha Entrega,Modelo,Cantidad,Costo Unitario,Subtotal,IVA,Total
        """

        for d in orden.detalles {
            csv.append("""
            \n\(orden.numeroVenta),\(orden.cliente),\(orden.agente?.nombre ?? ""),\(orden.numeroPedidoCliente),\(orden.fechaCreacion),\(orden.fechaEntrega),\(d.modelo),\(d.cantidad),\(d.precioUnitario),\(d.subtotal),\(orden.iva),\(orden.total)
            """)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Pedido_\(orden.numeroVenta).csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func imprimir() {

        guard let pdfURL = generarPDF() else { return }

        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)

        info.outputType = .general
        info.jobName = "Pedido \(orden.numeroVenta)"

        printController.printInfo = info
        printController.printingItem = pdfURL

        printController.present(animated: true)
    }
    
    // MARK: - UI HELPERS
    func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).foregroundStyle(.secondary)
            Spacer()
            Text(v)
        }
    }

    func boton(_ t: String, _ c: Color) -> some View {
        Text(t)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(c.opacity(0.15))
            )
            .foregroundStyle(c)
    }

    func campoEntero(_ t: String, value: Binding<Int>, enabled: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(t).font(.caption).foregroundStyle(.secondary)
            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .disabled(!enabled)
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        }
    }

    func campoCosto(value: Binding<Double>, enabled: Bool) -> some View {
        let txt = Binding<String>(
            get: { String(format: "%.2f", value.wrappedValue) },
            set: { value.wrappedValue = Double($0) ?? value.wrappedValue }
        )

        return VStack(alignment: .leading) {
            Text("Costo unitario").font(.caption).foregroundStyle(.secondary)
            HStack {
                Text("MX$").foregroundStyle(.secondary)
                TextField("0.00", text: txt)
                    .keyboardType(.decimalPad)
                    .disabled(!enabled)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    func formatoMX(_ v: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "MX $ "
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        
        return formatter.string(from: NSNumber(value: v)) ?? "MX $ 0.00"
    }
}

// MARK: - ESTILO
extension View {
    func cardWhite() -> some View {
        self
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
    }
}

// MARK: - COLOR HEX
extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}
