//
//  ReciboDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
//
//  ReciboDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftUI
import SwiftData
import UIKit

struct ReciboDetalleView: View {
    
    @Environment(\.modelContext) private var context
    
    let detalle: OrdenClienteDetalle
    @State private var recibo: ReciboProduccion?
    
    // Usuario actual (temporal)
    let usuarioActual = "Salomon Senado"
    
    // Sheets
    @State private var showCodigoSheet = false
    @State private var showRecepcionSheet = false
    @State private var showPagoSheet = false
    
    // Alertas
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""
    
    // Seguridad
    @State private var accionPendiente: AccionSegura?
    @State private var codigoIngresado = ""
    
    @State private var mostrarShare = false
    @State private var archivoURL: URL?
    
    private let codigoSeguridad = "1234"
    
    enum AccionSegura {
        case registrarRecepcion
        case registrarPago
        case eliminarRecepcion(ReciboDetalle)
        case eliminarPago(PagoRecibo)
    }
    
    // Data
    @Query private var recepciones: [ReciboDetalle]
    @Query private var pagos: [PagoRecibo]
    
    // MARK: - BODY

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resumenRecibo
                modeloCard
                recepcionesCard
                pagosCard
                exportarCard
                movimientosCard
            }
            .padding()
        }
        .navigationTitle("Recibo")
        .onAppear {
            prepararRecibo()
        }

        // ALERTA
        .alert("Acción realizada", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mensajeAlerta)
        }

        // CÓDIGO DE SEGURIDAD
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

        // REGISTRAR RECEPCIÓN
        .sheet(isPresented: $showRecepcionSheet) {

            RegistrarRecepcionSheet { primera, saldo, observaciones, numeroFactura in

                guard let recibo else { return }

                // 1️⃣ GUARDAR NOTA / FACTURA EN EL RECIBO
                recibo.numeroFacturaNota = numeroFactura

                // 2️⃣ CREAR RECEPCIÓN
                let nueva = ReciboDetalle(
                    modelo: detalle.modelo,
                    pzPrimera: primera,
                    pzSaldo: saldo,
                    recibo: recibo,
                    detalleOrden: detalle
                )

                // 3️⃣ OBSERVACIONES (OPCIONALES)
                nueva.observaciones = observaciones

                // 4️⃣ INSERTAR Y GUARDAR
                context.insert(nueva)

                DispatchQueue.main.async {
                    try? context.save()
                    showRecepcionSheet = false
                }
            }
        }

        // REGISTRAR PAGO
        .sheet(isPresented: $showPagoSheet) {
            RegistrarPagoSheet { monto, obs in
                guard let recibo else { return }

                let pago = PagoRecibo(
                    monto: monto,
                    observaciones: obs,
                    recibo: recibo
                )

                context.insert(pago)
                try? context.save()

                showPagoSheet = false
            }
        }

        // SHARE (EXCEL / PDF)
        .sheet(isPresented: $mostrarShare) {
            if let url = archivoURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

        // MARK: - SECCIONES
        
    var modeloCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {

                Text("Modelo")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(detalle.modelo)
                    .font(.title2.bold())
                

                // Descripción del modelo (desde catálogo)
                if let descripcion = detalle.modeloCatalogo?.descripcion,
                   !descripcion.isEmpty {

                    Text(descripcion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider()

                fila("Maquilero", detalle.produccion?.maquilero ?? "—")
                fila("Enviado", "\(pzCortadas)")
                fila("Recibido", "\(totalRecibido)")
                fila("Pendiente", "\(pendiente)", color: pendiente == 0 ? .green : .primary)
                fila("Costo recibido", formatoMX(subtotal))
            }
        }
    }

    var recepcionesCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {

                Text("Recepciones")
                    .font(.headline)

                ForEach(recepcionesDelModelo) { r in
                    VStack(alignment: .leading, spacing: 6) {

                        // FECHA + TOTAL
                        HStack {
                            Text(
                                r.recibo?.fechaRecibo.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                ) ?? ""
                            )
                            Spacer()
                            Text("\(r.pzPrimera + r.pzSaldo) PZ")
                                .fontWeight(.semibold)
                        }

                        // DESGLOSE
                        Text("Primera: \(r.pzPrimera)")
                            .font(.caption)

                        Text("Saldo: \(r.pzSaldo)")
                            .font(.caption)

                        // 👇 NUMERO DE NOTA / FACTURA (DEL RECIBO)
                        if let nota = r.recibo?.numeroFacturaNota,
                           !nota.isEmpty {

                            Text("Nota / Factura: \(nota)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // 👇 OBSERVACIONES (DEL DETALLE)
                        if let obs = r.observaciones,
                           !obs.isEmpty {

                            Text(obs)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // ELIMINAR
                        Button(role: .destructive) {
                            accionPendiente = .eliminarRecepcion(r)
                            showCodigoSheet = true
                        } label: {
                            Label("Eliminar recepción", systemImage: "trash")
                        }
                        .font(.caption)

                        Divider()
                    }
                }

                Button {
                    accionPendiente = .registrarRecepcion
                    showCodigoSheet = true
                } label: {
                    Label("Registrar recepción", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
        }
    }
        
    var pagosCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pagos")
                    .font(.headline)
                
                ForEach(pagosDelRecibo) { pago in
                    VStack(alignment: .leading, spacing: 6) {

                        HStack {
                            Text(
                                pago.fechaPago.formatted(
                                    date: .abbreviated,
                                    time: .omitted
                                )
                            )
                            Spacer()
                            Text(formatoMX(pago.monto))
                                .fontWeight(.semibold)
                        }

                        // ✅ OBSERVACIONES (CORRECTO)
                        if !pago.observaciones.isEmpty {
                            Text(pago.observaciones)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Button(role: .destructive) {
                            accionPendiente = .eliminarPago(pago)
                            showCodigoSheet = true
                        } label: {
                            Label("Eliminar pago", systemImage: "trash")
                        }
                        .font(.caption)

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
            }
        }
    }
        
        var exportarCard: some View {
            return card {
                HStack(spacing: 12) {

                    Button("Excel") {
                        exportarExcel()
                    }
                    .buttonStyle(.bordered)

                    Button("PDF") {
                        exportarPDF()
                    }
                    .buttonStyle(.bordered)

                    Button("Imprimir") {
                        imprimir()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }

        
        // MARK: - MOVIMIENTOS
        
        @ViewBuilder
        var movimientosCard: some View {
            return Group {
                if !movimientosOrden.isEmpty {
                    card {
                        VStack(alignment: .leading, spacing: 14) {

                            Text("Movimientos de la orden")
                                .font(.headline)

                            ForEach(movimientosOrden) { mov in
                                HStack(alignment: .top, spacing: 12) {

                                    Image(systemName: mov.icono)
                                        .foregroundStyle(mov.color)

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
                                }
                                Divider()
                            }
                        }
                    }
                }
            }
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
                    mensajeAlerta = "Recepción eliminada por \(usuarioActual)."
                    mostrarAlerta = true
                    
                case .eliminarPago(let p):
                    p.usuarioEliminacion = usuarioActual
                    p.fechaEliminacion = Date()
                    try? context.save()
                    recibo?.fechaRecibo = Date()
                    mensajeAlerta = "Pago eliminado por \(usuarioActual)."
                    mostrarAlerta = true
                    
                case .none:
                    break
                }
                
                codigoIngresado = ""
                accionPendiente = nil
            }
        }
        
        // MARK: - DATOS
        
        struct MovimientoOrden: Identifiable {
            let id = UUID()
            let titulo: String
            let usuario: String
            let fecha: Date
            let icono: String
            let color: Color
        }
        
        var movimientosOrden: [MovimientoOrden] {
            
            var items: [MovimientoOrden] = []
            
            // RECEPCIONES (ACTIVAS Y ELIMINADAS)
            for r in recepciones where r.detalleOrden == detalle {
                
                if let fechaElim = r.fechaEliminacion,
                   let usuario = r.usuarioEliminacion {
                    
                    items.append(
                        MovimientoOrden(
                            titulo: "Recepción eliminada (\(r.pzPrimera + r.pzSaldo) pz)",
                            usuario: usuario,
                            fecha: fechaElim,
                            icono: "trash.fill",
                            color: .red
                        )
                    )
                    
                } else {
                    
                    items.append(
                        MovimientoOrden(
                            titulo: "Recepción registrada (\(r.pzPrimera + r.pzSaldo) pz)",
                            usuario: "Sistema",
                            fecha: r.recibo?.fechaRecibo ?? Date(),
                            icono: "shippingbox.fill",
                            color: .blue
                        )
                    )
                }
            }
            
            // PAGOS (ACTIVOS Y ELIMINADOS)
            for p in pagos where p.recibo == recibo {
                
                if let fechaElim = p.fechaEliminacion,
                   let usuario = p.usuarioEliminacion {
                    
                    items.append(
                        MovimientoOrden(
                            titulo: "Pago eliminado (\(formatoMX(p.monto)))",
                            usuario: usuario,
                            fecha: fechaElim,
                            icono: "trash.fill",
                            color: .red
                        )
                    )
                    
                } else {
                    
                    items.append(
                        MovimientoOrden(
                            titulo: "Pago registrado (\(formatoMX(p.monto)))",
                            usuario: "Sistema",
                            fecha: p.fechaPago,
                            icono: "creditcard.fill",
                            color: .green
                        )
                    )
                }
            }
            
            // CANCELACIÓN
            if let prod = detalle.produccion,
               let u = prod.usuarioCancelacion,
               let f = prod.fechaCancelacion {
                
                items.append(
                    MovimientoOrden(
                        titulo: "Orden cancelada",
                        usuario: u,
                        fecha: f,
                        icono: "xmark.circle.fill",
                        color: .red
                    )
                )
            }
            
            return items.sorted { $0.fecha > $1.fecha }
        }
        
    // MARK: - CÁLCULOS PRODUCCIÓN

    var pzCortadas: Int {
        detalle.produccion?.pzCortadas ?? 0
    }

    var recepcionesDelModelo: [ReciboDetalle] {
        recepciones.filter {
            $0.detalleOrden == detalle &&
            $0.fechaEliminacion == nil
        }
    }

    var totalRecibido: Int {
        recepcionesDelModelo.reduce(0) {
            $0 + $1.pzPrimera + $1.pzSaldo
        }
    }

    var pendiente: Int {
        max(pzCortadas - totalRecibido, 0)
    }

    var costoMaquila: Double {
        detalle.produccion?.costoMaquila ?? 0
    }

    var subtotal: Double {
        Double(totalRecibido) * costoMaquila
    }

    var iva: Double {
        (detalle.orden?.aplicaIVA ?? false)
            ? subtotal * 0.16
            : 0
    }

    var total: Double {
        subtotal + iva
    }

    var pagosDelRecibo: [PagoRecibo] {
        pagos.filter {
            $0.recibo == recibo &&
            $0.fechaEliminacion == nil
        }
    }

    var totalPagado: Double {
        pagosDelRecibo.reduce(0) { $0 + $1.monto }
    }

    var saldoPendiente: Double {
        max(total - totalPagado, 0)
    }

        
        // MARK: - HEADER
        
    var resumenRecibo: some View {
        card {
            VStack(alignment: .leading, spacing: 8) {

                // FECHA ENTREGA
                Text("Fecha de entrega")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    detalle.orden?.fechaEntrega
                        .formatted(date: .abbreviated, time: .omitted)
                    ?? "—"
                )
                .font(.headline)

                Divider()

                // DATOS DE LA ORDEN
                fila(
                    "No. Venta",
                    "\(detalle.orden?.numeroVenta ?? 0)"
                )

                fila(
                    "No. Pedido",
                    detalle.orden?.numeroPedidoCliente ?? "—"
                )

                fila(
                    "Orden de maquila",
                    detalle.produccion?.ordenMaquila ?? "—"
                )

                fila(
                    "Cliente",
                    detalle.orden?.cliente ?? "—"
                )
                

                Divider()

                // TOTAL
                Text(formatoMX(total))
                    .font(.largeTitle.bold())
                    .foregroundStyle(.green)

                Divider()

                fila("Subtotal", formatoMX(subtotal))
                fila("IVA", formatoMX(iva))
                fila("Total", formatoMX(total))

                Divider()

                fila("Piezas recibidas", "\(totalRecibido) / \(pzCortadas)")
                fila("Pagado", formatoMX(totalPagado))
                fila(
                    "Saldo pendiente",
                    formatoMX(saldoPendiente),
                    color: saldoPendiente == 0 ? .green : .primary
                )
            }
        }
    }


        // MARK: - HELPERS
        
        func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
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
        
    // MARK: - PREPARAR

    func prepararRecibo() {
        guard let produccion = detalle.produccion else { return }

        if let existente = try? context.fetch(
            FetchDescriptor<ReciboProduccion>()
        ).first(where: {
            $0.produccion == produccion && !$0.cancelado
        }) {
            recibo = existente
            return
        }

        let nuevo = ReciboProduccion(
            produccion: produccion,
            fechaRecibo: Date()
        )

        context.insert(nuevo)
        try? context.save()
        recibo = nuevo
    }

    // MARK: - TEXTO COMPLETO (PDF / IMPRIMIR)

    func textoCompletoRecibo() -> String {

        var texto = ""

        // ===============================
        // DATOS DE LA ORDEN
        // ===============================
        texto += "RECIBO DE PRODUCCIÓN\n\n"

        texto += "Modelo: \(detalle.modelo)\n"
        texto += "Cliente: \(detalle.orden?.cliente ?? "—")\n"
        texto += "No. Venta: \(detalle.orden?.numeroVenta ?? 0)\n"
        texto += "No. Pedido: \(detalle.orden?.numeroPedidoCliente ?? "—")\n"
        texto += "Orden de maquila: \(detalle.produccion?.ordenMaquila ?? "—")\n"

        texto += "Maquilero: \(detalle.produccion?.maquilero ?? "—")\n"
        texto += "Piezas cortadas: \(pzCortadas)\n"
        texto += "Fecha recibo: \(recibo?.fechaRecibo.formatted() ?? "—")\n"

        // ✅ NOTA / FACTURA (AQUÍ ESTABA EL FALTANTE)
        texto += "Nota / Factura: \(recibo?.numeroFacturaNota ?? "—")\n\n"

        // ===============================
        // RESUMEN ECONÓMICO
        // ===============================
        texto += "RESUMEN ECONÓMICO\n"
        texto += "Subtotal: \(formatoMX(subtotal))\n"
        texto += "IVA: \(formatoMX(iva))\n"
        texto += "Total: \(formatoMX(total))\n"
        texto += "Pagado: \(formatoMX(totalPagado))\n"
        texto += "Saldo pendiente: \(formatoMX(saldoPendiente))\n\n"

        // ===============================
        // RECEPCIONES
        // ===============================
        texto += "RECEPCIONES\n"
        for r in recepciones {
            let estado = r.fechaEliminacion == nil ? "ACTIVA" : "ELIMINADA"
            texto += """
            - \(r.recibo?.fechaRecibo.formatted() ?? "")
              Piezas: \(r.pzPrimera + r.pzSaldo)
              Primera: \(r.pzPrimera)
              Saldo: \(r.pzSaldo)
              Observaciones: \(r.observaciones ?? "—")
              Estado: \(estado)

            """
        }

        // ===============================
        // PAGOS
        // ===============================
        texto += "PAGOS\n"
        for p in pagos {
            let estado = p.fechaEliminacion == nil ? "ACTIVO" : "ELIMINADO"
            texto += """
            - \(p.fechaPago.formatted())
              Monto: \(formatoMX(p.monto))
              Observaciones: \(p.observaciones ?? "—")
              Estado: \(estado)

            """
        }

        // ===============================
        // MOVIMIENTOS
        // ===============================
        texto += "MOVIMIENTOS DE LA ORDEN\n"
        for m in movimientosOrden {
            texto += "- \(m.fecha.formatted()) | \(m.titulo) | Usuario: \(m.usuario)\n"
        }

        return texto
    }

    // MARK: - EXPORTAR EXCEL

    func exportarExcel() {

        var csv = ""

        // ===============================
        // ENCABEZADO
        // ===============================
        csv += "RECIBO DE PRODUCCIÓN\n"
        csv += "Modelo,\(detalle.modelo)\n"
        csv += "Cliente,\(detalle.orden?.cliente ?? "")\n"
        csv += "No Venta,\(detalle.orden?.numeroVenta ?? 0)\n"
        csv += "No Pedido,\(detalle.orden?.numeroPedidoCliente ?? "")\n"
        csv += "Orden Maquila,\(detalle.produccion?.ordenMaquila ?? "")\n"
        csv += "Maquilero,\(detalle.produccion?.maquilero ?? "")\n"
        csv += "Nota / Factura,\(recibo?.numeroFacturaNota ?? "")\n\n"

        // RECEPCIONES
        for r in recepciones {

            let estado = r.fechaEliminacion == nil ? "ACTIVA" : "ELIMINADA"

            csv += """
            \(r.recibo?.fechaRecibo.formatted() ?? ""),
            Recepción,
            \(detalle.modelo),
            \(r.pzPrimera + r.pzSaldo),
            \(r.pzPrimera),
            \(r.pzSaldo),
            \(r.recibo?.numeroFacturaNota ?? ""),
            \(r.observaciones ?? ""),
            \(estado),
            0
            \n
            """
        }

        // PAGOS
        for p in pagos {

            let estado = p.fechaEliminacion == nil ? "ACTIVO" : "ELIMINADO"

            csv += """
            \(p.fechaPago.formatted()),
            Pago,
            ,
            ,
            ,
            ,
            \(recibo?.numeroFacturaNota ?? ""),
            \(p.observaciones ?? ""),
            \(estado),
            \(p.monto)
            \n
            """
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Completo.csv")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)

            DispatchQueue.main.async {
                archivoURL = url
                mostrarShare = true
            }

        } catch {
            print("Error al exportar Excel")
        }
    }

    // MARK: - EXPORTAR PDF

    func exportarPDF() {

        let texto = textoCompletoRecibo()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Completo.pdf")

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
            print("Error al exportar PDF")
        }
    }

    // MARK: - IMPRIMIR

    func imprimir() {

        let texto = textoCompletoRecibo()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Recibo_Impresion.pdf")

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

            let controlador = UIPrintInteractionController.shared
            let info = UIPrintInfo(dictionary: nil)

            info.outputType = .general
            info.jobName = "Recibo Producción"

            controlador.printInfo = info
            controlador.printingItem = url
            controlador.present(animated: true)

        } catch {
            print("Error al imprimir")
        }
    }

    // MARK: - SHARE SHEET

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
    
    struct RegistrarRecepcionSheetConFactura: View {

        @Environment(\.dismiss) private var dismiss

        @State private var pzPrimera: String = ""
        @State private var pzSaldo: String = ""
        @State private var observaciones: String = ""
        @State private var numeroFactura: String

        let onGuardar: (Int, Int, String, String) -> Void

        init(
            numeroFactura: String,
            onGuardar: @escaping (Int, Int, String, String) -> Void
        ) {
            _numeroFactura = State(initialValue: numeroFactura)
            self.onGuardar = onGuardar
        }

        var body: some View {
            NavigationStack {
                Form {

                    // 🔵 NOTA / FACTURA (MISMO MODULO)
                    Section("Nota / Factura") {
                        TextField(
                            "# de nota / # de factura",
                            text: $numeroFactura
                        )
                        .textInputAutocapitalization(.characters)
                    }

                    // 🔵 RECEPCIÓN
                    Section("Recepción") {

                        TextField("Piezas primera", text: $pzPrimera)
                            .keyboardType(.numberPad)

                        TextField("Piezas saldo", text: $pzSaldo)
                            .keyboardType(.numberPad)

                        TextField(
                            "Observaciones",
                            text: $observaciones,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                    }
                }
                .navigationTitle("Registrar recepción")
                .toolbar {

                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            onGuardar(
                                Int(pzPrimera) ?? 0,
                                Int(pzSaldo) ?? 0,
                                observaciones,
                                numeroFactura
                            )
                        }
                        .disabled(
                            (Int(pzPrimera) ?? 0) == 0 &&
                            (Int(pzSaldo) ?? 0) == 0
                        )
                    }
                }
            }
        }
    }

    
}
