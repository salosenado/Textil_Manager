//
//  ResumenProduccionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
//
//  ResumenProduccionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//

import SwiftUI
import SwiftData

enum SeccionImpresion {
    case todo
    case orden
    case recibos
    case pagos
}

struct ResumenProduccionDetalleView: View {

    let produccion: Produccion
    @Environment(\.dismiss) private var dismiss

    // =========================
    // QUERIES REACTIVOS (CLAVE)
    // =========================
    @Query private var recibos: [ReciboProduccion]
    @Query private var pagos: [PagoRecibo]
    @Query private var detalles: [ReciboDetalle]

    // =========================
    // EMPRESAS
    // =========================
    @Query(filter: #Predicate<Empresa> { $0.activo })
    private var empresas: [Empresa]

    @State private var empresaID: PersistentIdentifier?
    
    @Environment(\.modelContext) private var context

    @State private var responsableEdit: String = ""
    
    @State private var firmaMaquilero: [CGPoint] = []
    @State private var firmaResponsable: [CGPoint] = []
    
    @Query private var firmas: [ProduccionFirma]
    

    // MARK: - BODY
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                header
                // =========================
                // EMPRESA
                // =========================
                sectionTitle("Empresa")
                whiteCard {
                    HStack {
                        Text("Empresa")
                        Spacer()
                        Picker(nombreEmpresaSeleccionada, selection: $empresaID) {
                            Text("Empresa")
                                .tag(PersistentIdentifier?.none)

                            ForEach(empresas) { empresa in
                                Text(empresa.nombre)
                                    .tag(Optional(empresa.persistentModelID))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // =========================
                // ORDEN DE MAQUILA
                // =========================
                sectionTitle("Orden de maquila")
                whiteCard {

                    fila("Orden", produccion.ordenMaquila ?? "—")
                    Divider()

                    fila("Fecha creación", formatearFecha(produccion.fechaOrdenMaquila))
                    Divider()

                    fila("Fecha solicitud entrega", formatearFecha(fechaSolicitudEntrega))
                    Divider()

                    fila("Primera recepción", formatearFecha(reciboBase?.fechaRecibo))
                    Divider()

                    fila("Nota / Factura", reciboBase?.numeroFacturaNota ?? "—")
                    Divider()

                    fila("IVA", aplicaIVA ? "Aplica" : "No aplica")
                }

                // =========================
                // MODELOS + RESUMEN
                // =========================
                sectionTitle("Modelos")
                ForEach(modelosResumen, id: \.modelo) { m in
                    whiteCard {

                        Text("Modelo: \(m.modelo)")
                            .font(.headline)

                        if let desc = m.descripcion, !desc.isEmpty {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        fila("PZ cortadas", "\(produccion.pzCortadas)")
                        fila("Total recibido", "\(m.recibidas)", color: .green)
                        fila("Pendiente", "\(m.pendiente)")
                        Divider()
                        fila("Costo unitario", formatoMX(m.costo))
                        fila("Subtotal", formatoMX(m.subtotal))
                        fila("IVA", formatoMX(m.iva))
                        fila("TOTAL", formatoMX(m.total), color: .green)
                    }
                }

                // =========================
                // RECEPCIONES
                // =========================
                sectionTitle("Recepciones")
                ForEach(recepcionesResumen) { r in
                    whiteCard {
                        fila("Nota / Factura", r.nota)
                        fila("Fecha", formatearFecha(r.fecha))
                        fila(
                            "Observación",
                            r.observacion.isEmpty ? "—" : r.observacion
                        )
                        Divider()
                        fila("PZ Primera", "\(r.primera)")
                        fila("PZ Saldo", "\(r.saldo)")
                        fila("TOTAL", "\(r.total)", color: .green)
                    }
                }

                // =========================
                // PAGOS (SIN DUPLICAR)
                // =========================
                sectionTitle("Pagos")
                whiteCard {
                    if pagosProduccion.isEmpty {
                        Text("Sin pagos registrados")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pagosProduccion) { pago in

                            fila("Fecha", formatearFecha(pago.fechaPago))
                            fila("Monto", formatoMX(pago.monto), color: .green)

                            fila(
                                "Observación",
                                pago.observaciones
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                                ? "—"
                                : pago.observaciones
                            )

                            Divider()
                        }
                    }
                }

                // =========================
                // DATOS DE CONTROL
                // =========================
                sectionTitle("Datos de control")

                whiteCard {
                    VStack(spacing: 12) {

                        HStack {
                            Text("Responsable")
                            Spacer()
                            TextField("Nombre del responsable", text: $responsableEdit)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                        }

                        Divider()

                        Button("Guardar") {
                            guardarFirmasSiEsNecesario()
                            try? context.save()
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                    }
                }

                // =========================
                // FIRMAS DIGITALES
                // =========================
                sectionTitle("Firmas")

                whiteCard {
                    VStack(spacing: 16) {

                        Text("Firma del maquilero")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SignaturePad(points: $firmaMaquilero)

                        Divider()

                        Text("Firma del responsable")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        SignaturePad(points: $firmaResponsable)
                    }
                }

                // =========================
                // IMPRIMIR
                // =========================
                sectionTitle("Imprimir")

                whiteCard {
                    VStack(spacing: 14) {

                        botonImpresion(
                            titulo: "Imprimir todo",
                            icono: "printer.fill",
                            color: .blue,
                            action: imprimirTodo
                        )

                        botonImpresion(
                            titulo: "Solo orden",
                            icono: "doc.text.fill",
                            color: .purple,
                            action: imprimirOrden
                        )

                        botonImpresion(
                            titulo: "Solo recibos",
                            icono: "shippingbox.fill",
                            color: .green,
                            action: imprimirRecibos
                        )

                        botonImpresion(
                            titulo: "Solo pagos",
                            icono: "dollarsign.circle.fill",
                            color: .orange,
                            action: imprimirPagos
                        )
                    }
                }

                Spacer(minLength: 20)
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onAppear {
            if let firma = firmas.first(where: { $0.produccion == produccion }) {
                responsableEdit = firma.responsable
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func generarHTMLImpresion(seccion: SeccionImpresion) -> String {

        let empresa = empresas.first { $0.persistentModelID == empresaID }
        let firma = firmas.first { $0.produccion == produccion }
        let fechaImpresion = Date().formatted(date: .long, time: .shortened)

        func logoHTML(_ data: Data?) -> String {
            guard let data else { return "" }
            let base64 = data.base64EncodedString()
            return "<img src='data:image/png;base64,\(base64)' height='70'/>"
        }

        var html = """
        <html>
        <head>
            <meta charset="utf-8">
            <style>

                @page { margin: 28px; }

                body {
                    font-family: -apple-system, Helvetica;
                    font-size: 13px;
                    margin: 0;
                }

                h1 { font-size: 20px; margin: 0; }
                h2 { font-size: 16px; margin-top: 22px; }

                .box {
                    border: 1px solid #ccc;
                    padding: 10px;
                    margin-top: 10px;
                    page-break-inside: avoid;
                }

                .header {
                    display: flex;
                    gap: 16px;
                    align-items: center;
                }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 12px;
                    page-break-inside: avoid;
                }

                td {
                    padding: 6px;
                    vertical-align: top;
                }

                .right {
                    text-align: right;
                }

                .footer {
                    margin-top: 32px;
                    padding-top: 8px;
                    border-top: 1px solid #ddd;
                    font-size: 11px;
                    color: #666;
                    text-align: center;
                }

            </style>
        </head>
        <body>

        <div class="header">
            \(logoHTML(empresa?.logoData))
            <div>
                <h1>\(empresa?.nombre ?? "—")</h1>
                <div>RFC: \(empresa?.rfc ?? "—")</div>
                <div>\(empresa?.direccion ?? "")</div>
                <div>Tel: \(empresa?.telefono ?? "")</div>
            </div>
        </div>

        <hr>

        <div class="box">
            <table width="100%">
                <tr>
                    <td>
                        <b>Orden de maquila:</b> \(produccion.ordenMaquila ?? "—")<br>
                        <b>Fecha de orden:</b> \(formatearFecha(produccion.fechaOrdenMaquila))<br>
                        <b>Fecha de entrega:</b> \(formatearFecha(fechaSolicitudEntrega))
                    </td>
                    <td class="right">
                        <b>Fecha de recibo:</b> \(formatearFecha(reciboBase?.fechaRecibo))<br>
                        <b>Nota / Factura:</b> \(reciboBase?.numeroFacturaNota ?? "—")
                    </td>
                </tr>
            </table>
        </div>

        <div class="box">
            <b>Maquilero:</b> \(produccion.maquilero)<br>
            <b>Responsable:</b> \(firma?.responsable ?? "—")
        </div>
        """

        if seccion == .todo || seccion == .orden {
            html += """
            <h2>Detalle de orden</h2>
            <div class="box">
                <b>Modelo:</b> \(produccion.detalle?.modelo ?? "—")<br>
                <b>Descripción:</b> \(produccion.detalle?.modeloCatalogo?.descripcion ?? "—")<br>
                <b>Piezas cortadas:</b> \(produccion.pzCortadas)<br>
                <b>Costo maquila:</b> \(formatoMX(produccion.costoMaquila))
            </div>
            """
        }

        if seccion == .todo || seccion == .recibos {
            html += "<h2>Recepciones</h2>"
            for r in recepcionesResumen {
                html += """
                <div class="box">
                    <b>Nota:</b> \(r.nota)<br>
                    <b>Fecha:</b> \(formatearFecha(r.fecha))<br>
                    <b>PZ Primera:</b> \(r.primera)<br>
                    <b>PZ Saldo:</b> \(r.saldo)<br>
                    <b>Total:</b> \(r.total)<br>
                    <b>Observaciones:</b> \(r.observacion.isEmpty ? "—" : r.observacion)
                </div>
                """
            }
        }

        if seccion == .todo || seccion == .pagos {
            html += "<h2>Pagos</h2>"
            for p in pagosProduccion {
                html += """
                <div class="box">
                    <b>Fecha:</b> \(formatearFecha(p.fechaPago))<br>
                    <b>Monto:</b> \(formatoMX(p.monto))<br>
                    <b>Observaciones:</b> \(p.observaciones.isEmpty ? "—" : p.observaciones)
                </div>
                """
            }
        }

        html += """
        <h2>Firmas</h2>
        <table>
            <tr>
                <td>
                    <b>Maquilero:</b> \(produccion.maquilero)<br><br>
                    \(firmaHTML(firma?.firmaMaquilero))
                </td>
                <td class="right">
                    <b>Responsable:</b> \(firma?.responsable ?? "—")<br><br>
                    \(firmaHTML(firma?.firmaResponsable))
                </td>
            </tr>
        </table>

        <div class="footer">
            Documento oficial de producción · Textil Manager<br>
            Fecha de impresión: \(fechaImpresion)
        </div>

        </body>
        </html>
        """

        return html
    }

    // MARK: - HEADER
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("Detalle producción")
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - DATA CORRECTA (SIN DUPLICADOS)

    private var recibosProduccion: [ReciboProduccion] {
        recibos.filter {
            $0.produccion == produccion &&
            !$0.cancelado
        }
    }

    private var pagosProduccion: [PagoRecibo] {
        pagos.filter {
            $0.recibo?.produccion == produccion &&
            $0.fechaEliminacion == nil
        }
        .sorted { $0.fechaPago < $1.fechaPago }
    }

    private var recepcionesProduccion: [ReciboDetalle] {
        detalles.filter {
            $0.recibo?.produccion == produccion &&
            $0.fechaEliminacion == nil
        }
    }

    private var reciboBase: ReciboProduccion? {
        recibosProduccion.sorted { $0.fechaRecibo < $1.fechaRecibo }.first
    }

    // =========================
    // RECEPCIONES RESUMEN
    // =========================
    private var recepcionesResumen: [RecepcionResumen] {

        recibosProduccion.map { recibo in

            // 🔹 Detalles reales de ESTE recibo
            let detallesRecibo = detalles.filter {
                $0.recibo == recibo &&
                $0.fechaEliminacion == nil
            }

            let primera = detallesRecibo.reduce(0) { $0 + $1.pzPrimera }
            let saldo   = detallesRecibo.reduce(0) { $0 + $1.pzSaldo }

            // 🔹 OBSERVACIONES REALES (DESDE DETALLE)
            let observaciones = detallesRecibo
                .compactMap { $0.observaciones }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")

            return RecepcionResumen(
                id: recibo.persistentModelID,
                nota: recibo.numeroFacturaNota ?? "—",
                fecha: recibo.fechaRecibo,
                observacion: observaciones,
                primera: primera,
                saldo: saldo,
                total: primera + saldo
            )
        }
    }

    // =========================
    // MODELOS RESUMEN
    // =========================
    private var modelosResumen: [ModeloResumen] {

        let recibidas = recepcionesProduccion.reduce(0) {
            $0 + $1.pzPrimera + $1.pzSaldo
        }

        let subtotal = Double(recibidas) * produccion.costoMaquila
        let iva = aplicaIVA ? subtotal * 0.16 : 0

        return [
            ModeloResumen(
                modelo: produccion.detalle?.modelo ?? "—",
                descripcion: produccion.detalle?.modeloCatalogo?.descripcion,
                recibidas: recibidas,
                pendiente: max(produccion.pzCortadas - recibidas, 0),
                costo: produccion.costoMaquila,
                subtotal: subtotal,
                iva: iva,
                total: subtotal + iva
            )
        ]
    }

    // MARK: - AUX

    private var fechaSolicitudEntrega: Date? {
        produccion.detalle?.orden?.fechaEntrega
    }

    private var aplicaIVA: Bool {
        produccion.detalle?.orden?.aplicaIVA ?? false
    }

    private var nombreEmpresaSeleccionada: String {
        guard
            let id = empresaID,
            let empresa = empresas.first(where: { $0.persistentModelID == id })
        else { return "Selecciona una empresa" }
        return empresa.nombre
    }
    
    private var empresaSeleccionada: Empresa? {
        guard let id = empresaID else { return nil }
        return empresas.first { $0.persistentModelID == id }
    }

    
    // MARK: - UI HELPERS

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func whiteCard<Content: View>(
        @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }

    private func fila(
        _ t: String,
        _ v: String,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v)
                .foregroundStyle(color)
        }
    }

    private func formatearFecha(_ d: Date?) -> String {
        guard let d else { return "—" }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: d)
    }

// MARK: - UI HELPERS

private func formatoMX(_ v: Double) -> String {
    let nf = NumberFormatter()
    nf.numberStyle = .currency
    nf.currencyCode = "MXN"
    return nf.string(from: NSNumber(value: v)) ?? "$0.00"
}
    
    private func firmaComoPNG(_ points: [CGPoint], size: CGSize) -> Data? {
        guard points.count > 1 else { return nil }

        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.setLineCap(.round)

            for i in 1..<points.count {
                ctx.cgContext.move(to: points[i - 1])
                ctx.cgContext.addLine(to: points[i])
                ctx.cgContext.strokePath()
            }
        }

        return image.pngData()
    }

    private func firmaHTML(_ data: Data?) -> String {
        guard let data else { return "___________________________" }
        let base64 = data.base64EncodedString()
        return """
        <img src="data:image/png;base64,\(base64)" width="200"/>
        """
    }
    
// MARK: - IMPRESIÓN (PLACEHOLDER)

    private func guardarFirmasSiEsNecesario() {

        if let existente = firmas.first(where: { $0.produccion == produccion }) {

            existente.responsable = responsableEdit

            if !firmaMaquilero.isEmpty {
                existente.firmaMaquilero = firmaComoPNG(
                    firmaMaquilero,
                    size: CGSize(width: 300, height: 120)
                )
            }

            if !firmaResponsable.isEmpty {
                existente.firmaResponsable = firmaComoPNG(
                    firmaResponsable,
                    size: CGSize(width: 300, height: 120)
                )
            }

            try? context.save()
            return
        }

        let registro = ProduccionFirma(
            produccion: produccion,
            maquilero: produccion.maquilero,
            responsable: responsableEdit,
            firmaMaquilero: firmaComoPNG(
                firmaMaquilero,
                size: CGSize(width: 300, height: 120)
            ),
            firmaResponsable: firmaComoPNG(
                firmaResponsable,
                size: CGSize(width: 300, height: 120)
            )
        )

        context.insert(registro)
        try? context.save()
    }

    private func imprimirTodo() {
        guardarFirmasSiEsNecesario()
        imprimir(seccion: .todo)
    }
    
    private func imprimirOrden() {
        imprimir(seccion: .orden)
    }

    private func imprimirRecibos() {
        imprimir(seccion: .recibos)
    }

    private func imprimirPagos() {
        imprimir(seccion: .pagos)
    }
    
    private func imprimir(seccion: SeccionImpresion) {

        let html = generarHTMLImpresion(seccion: seccion)

        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let controller = UIPrintInteractionController.shared
        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    private func botonImpresion(
        titulo: String,
        icono: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icono)
                Text(titulo)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .foregroundStyle(.white)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    } // ⬅️ aquí CIERRA ResumenProduccionDetalleView

// =========================
// MODELOS DE APOYO
// =========================
struct RecepcionResumen: Identifiable {
    let id: PersistentIdentifier
    let nota: String
    let fecha: Date
    let observacion: String
    let primera: Int
    let saldo: Int
    let total: Int
}

struct ModeloResumen {
    let modelo: String
    let descripcion: String?
    let recibidas: Int
    let pendiente: Int
    let costo: Double
    let subtotal: Double
    let iva: Double
    let total: Double
}

struct SignaturePad: View {

    @Binding var points: [CGPoint]

    var body: some View {
        Canvas { context, size in
            guard points.count > 1 else { return }

            var path = Path()
            path.addLines(points)

            context.stroke(path, with: .color(.black), lineWidth: 2)
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.4))
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    points.append(value.location)
                }
        )
        .overlay(
            Button("Limpiar") {
                points.removeAll()
            }
            .font(.caption)
            .padding(6),
            alignment: .topTrailing
        )
    }
}
