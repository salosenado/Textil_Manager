//
//  VentaClienteDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
import SwiftUI
import SwiftData
import UIKit

struct VentaClienteDetalleView: View {

    // MARK: - ENV
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var venta: VentaCliente

    // MARK: - SEGURIDAD
    private let PASSWORD_ADMIN = "1234"
    @State private var mostrarPassword = false
    @State private var password = ""
    @State private var accionPendiente: Accion?

    enum Accion {
        case enviarMercancia
        case cambiarIVA
        case editar
        case cancelar
    }

    // MARK: - UI STATE
    @State private var modoEdicion = false
    @State private var mostrarConfirmacionEnvio = false

    // Firmas
    @State private var mostrarFirmaAgente = false
    @State private var mostrarFirmaResponsable = false
    @State private var firmaAgenteData: Data?
    @State private var firmaResponsableData: Data?
    
    @State private var mostrarAlertaInventario = false
    @State private var mensajeInventario = ""
    
    @State private var cantidadesOriginales: [String: Int] = [:]
    
    @State private var forzarSobreventa = false

    @State private var mostrarConfirmacionEliminar = false
    @State private var indiceModeloAEliminar: Int?
    
    @State private var mostrarErrorImpresion = false
    @State private var mensajeErrorImpresion = ""

    @Query private var reingresosDetalle: [ReingresoDetalle]
    @Query private var marcas: [Marca]
    

    // MARK: - BLOQUEO REAL
    var bloqueada: Bool {
        venta.mercanciaEnviada || venta.cancelada
    }

    // MARK: - BODY
    // MARK: - BODY
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    detalle
                    responsables
                    modelos
                    ivaToggle
                    totales
                    observaciones
                    firmas
                    exportar
                    confirmarEnvio
                    cancelarVenta
                    movimientos
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Detalle de venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(modoEdicion ? "Guardar" : "Editar") {
                        solicitar(.editar)
                    }
                    .disabled(bloqueada)
                }
            }
            // 🔐 PASSWORD
            .alert("Contraseña", isPresented: $mostrarPassword) {
                SecureField("Contraseña", text: $password)
                Button("Cancelar", role: .cancel) { password = "" }
                Button("Confirmar") { validarPassword() }
            }

            // 🚚 CONFIRMAR ENVÍO
            .alert("Confirmar envío de mercancía", isPresented: $mostrarConfirmacionEnvio) {
                Button("Confirmar", role: .destructive) {
                    solicitar(.enviarMercancia)
                }
                Button("Cancelar", role: .cancel) {}
            }

            // 🚫 INVENTARIO INSUFICIENTE
            .alert("Inventario insuficiente", isPresented: $mostrarAlertaInventario) {
                Button("Forzar", role: .destructive) {
                    forzarSobreventa = true
                    solicitar(.editar)
                }
                Button("Cancelar", role: .cancel) {
                    forzarSobreventa = false
                }
            } message: {
                Text(mensajeInventario)
            }

            // 🗑️ ELIMINAR MODELO
            .alert("Eliminar modelo", isPresented: $mostrarConfirmacionEliminar) {
                Button("Eliminar", role: .destructive) {
                    if let index = indiceModeloAEliminar {
                        eliminarModelo(at: index)
                        indiceModeloAEliminar = nil
                    }
                }
                Button("Cancelar", role: .cancel) {
                    indiceModeloAEliminar = nil
                }
            } message: {
                Text(
                    """
                    ¿Estás seguro de eliminar este modelo de la venta?

                    Esta acción no se puede deshacer.
                    """
                )
            }

            // 🚫 BLOQUEO DE IMPRESIÓN
            .alert("No se puede imprimir", isPresented: $mostrarErrorImpresion) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(mensajeErrorImpresion)
            }

            // ✍️ FIRMA AGENTE
            .sheet(isPresented: $mostrarFirmaAgente) {
                FirmaView(
                    titulo: "Firma agente",
                    firmaData: $firmaAgenteData
                ) { data in
                    venta.firmaAgente = data
                    try? context.save()
                }
            }

            // ✍️ FIRMA RESPONSABLE
            .sheet(isPresented: $mostrarFirmaResponsable) {
                FirmaView(
                    titulo: "Firma responsable",
                    firmaData: $firmaResponsableData
                ) { data in
                    venta.firmaResponsable = data
                    try? context.save()
                }
            }

            // ▶️ INIT
            .onAppear {
                if venta.movimientos.isEmpty {
                    let mov = VentaClienteMovimiento(
                        titulo: "Venta registrada",
                        usuario: "Sistema",
                        icono: "cart.fill",
                        color: "blue",
                        venta: venta
                    )
                    venta.movimientos.append(mov)
                    context.insert(mov)
                    try? context.save()
                }
    }
    }
    }
                  
            // MARK: - DETALLE
            var detalle: some View {

        VStack(alignment: .leading, spacing: 8) {

            fila("Folio", venta.folio)

            fila(
                "Factura / Nota",
                venta.numeroFactura.isEmpty ? "—" : venta.numeroFactura
            )

            fila("Cliente", venta.cliente.nombreComercial)

            fila(
                "Agente",
                venta.agente != nil
                ? "\(venta.agente?.nombre ?? "") \(venta.agente?.apellido ?? "")"
                : "—"
            )

            fila("Fecha venta", formatoFecha(venta.fechaVenta))
            fila("Fecha entrega", formatoFecha(venta.fechaEntrega))

            if venta.mercanciaEnviada {
                Text("MERCANCÍA ENVIADA")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .cardWhite()
    }

    // MARK: - RESPONSABLES
    var responsables: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Responsables")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Agente")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if modoEdicion {
                    TextField("Nombre del agente", text: $venta.nombreAgenteVenta)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(
                        venta.nombreAgenteVenta.isEmpty
                        ? "—"
                        : venta.nombreAgenteVenta
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Responsable")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if modoEdicion {
                    TextField("Nombre del responsable", text: $venta.nombreResponsableVenta)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(
                        venta.nombreResponsableVenta.isEmpty
                        ? "—"
                        : venta.nombreResponsableVenta
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)   // 👈 CLAVE
        .cardWhite()
    }

    // MARK: - MODELOS
    var modelos: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Modelos")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(venta.detalles.indices, id: \.self) { index in
                let d = venta.detalles[index]

                VStack(alignment: .leading, spacing: 12) {

                    // 🔥 MARCA (ARRIBA DEL MODELO)
                    if let marca = d.marca {
                        HStack {
                            Text("Marca:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(marca.nombre)
                                .font(.caption)
                                .bold()
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.15))
                                )
                        }
                    }

                    // MODELO + ELIMINAR
                    HStack {
                        Text("Modelo: \(d.modeloNombre)")
                            .font(.headline)

                        Spacer()

                        if modoEdicion && !bloqueada {
                            Button(role: .destructive) {
                                indiceModeloAEliminar = index
                                mostrarConfirmacionEliminar = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }


                    // DESCRIPCIÓN
                    if let modelo = obtenerModelo(nombre: d.modeloNombre),
                       !modelo.descripcion.isEmpty {
                        Text(modelo.descripcion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // EXISTENCIA REAL
                    Text(
                        "Existencia: \(existenciaDisponible(modeloNombre: d.modeloNombre)) pz"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // CANTIDAD / COSTO
                    HStack {
                        campoEntero(
                            "Cantidad",
                            value: Binding(
                                get: { venta.detalles[index].cantidad },
                                set: { venta.detalles[index].cantidad = $0 }
                            ),
                            enabled: modoEdicion && !bloqueada
                        )

                        campoCosto(
                            value: Binding(
                                get: { venta.detalles[index].costoUnitario },
                                set: { venta.detalles[index].costoUnitario = $0 }
                            ),
                            enabled: modoEdicion && !bloqueada
                        )
                    }

                    // SUBTOTAL
                    HStack {
                        Spacer()
                        Text(
                            formatoMX(
                                Double(d.cantidad) * d.costoUnitario
                            )
                        )
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
                get: { venta.aplicaIVA },
                set: { _ in solicitar(.cambiarIVA) }
            )
        )
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
                fila("Subtotal", formatoMX(subtotal))
                fila("IVA", formatoMX(iva))
                Divider()
                HStack {
                    Text("Total").fontWeight(.bold)
                    Spacer()
                    Text(formatoMX(total))
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .cardWhite()
        }
    }

    // MARK: - OBSERVACIONES
    var observaciones: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Observaciones")
                .font(.headline)

            if modoEdicion && !bloqueada {
                TextEditor(text: $venta.observaciones)
                    .frame(height: 160)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

            } else {
                Text(venta.observaciones.isEmpty ? "—" : venta.observaciones)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardWhite()
    }

    // MARK: - FIRMAS
    var firmas: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Firmas")
                .font(.headline)
                .foregroundStyle(.secondary)

            // FIRMA AGENTE
            Button {
                guard !bloqueada else { return }

                // 👉 si está en edición, permite volver a firmar
                if modoEdicion {
                    venta.firmaAgente = nil
                }

                firmaAgenteData = venta.firmaAgente
                mostrarFirmaAgente = true
            } label: {
                HStack {
                    Text("✍️ Firma agente")
                    Spacer()
                    estadoFirma(venta.firmaAgente)
                }
            }
            .disabled(bloqueada)

            Divider()

            // FIRMA RESPONSABLE
            Button {
                guard !bloqueada else { return }

                if modoEdicion {
                    venta.firmaResponsable = nil
                }

                firmaResponsableData = venta.firmaResponsable
                mostrarFirmaResponsable = true
            } label: {
                HStack {
                    Text("✍️ Firma responsable")
                    Spacer()
                    estadoFirma(venta.firmaResponsable)
                }
            }
            .disabled(bloqueada)
        }
        .cardWhite()
    }

    // MARK: - EXPORTAR
    var exportar: some View {
        VStack(spacing: 12) {

            Button {
                let empresa = try? context.fetch(
                    FetchDescriptor<Empresa>(predicate: #Predicate { $0.activo })
                ).first

                let pdfData = VentaClientePDFService.generarPDF(
                    venta: venta,
                    empresa: empresa
                )

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("Venta_\(venta.folio).pdf")

                try? pdfData.write(to: url)

                registrarMovimiento(
                    titulo: "PDF generado",
                    icono: "doc.richtext",
                    color: "blue"
                )

                let vc = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                UIApplication.shared.windows.first?
                    .rootViewController?
                    .present(vc, animated: true)

            } label: {
                boton("📄 Exportar PDF", .red)
            }

            Button {
                let url = VentaClienteExcelService.generarCSV(venta: venta)
                let vc = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                UIApplication.shared.windows.first?
                    .rootViewController?
                    .present(vc, animated: true)
            } label: {
                boton("📊 Exportar Excel", .green)
            }

            Button {
                if puedeImprimir() {
                    imprimir()
                } else {
                    mostrarErrorImpresion = true
                }
            } label: {
                boton("🖨 Imprimir", .blue)
            }
        }
        .cardWhite()
    }

    func puedeImprimir() -> Bool {

        if venta.nombreResponsableVenta
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {

            mensajeErrorImpresion = "Debes capturar el nombre del responsable."
            return false
        }

        return true
    }
    
    // MARK: - CONFIRMAR ENVÍO
    var confirmarEnvio: some View {
        Group {
            if !venta.mercanciaEnviada && !venta.cancelada {
                Button {
                    mostrarConfirmacionEnvio = true
                } label: {
                    boton("🚚 Confirmar envío", .green)
                }
                .cardWhite()
            }
        }
    }

            
    // MARK: - CANCELAR VENTA
    var cancelarVenta: some View {
        Group {
            if !venta.cancelada {
                Button(role: .destructive) {
                    accionPendiente = .cancelar
                    mostrarPassword = true
                } label: {
                    boton("❌ Cancelar venta", .red)
                }
                .cardWhite()
            }
        }
    }
    
    // MARK: - MOVIMIENTOS
    var movimientos: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Movimientos de la venta")
                .font(.headline)

            VStack(spacing: 0) {

                ForEach(venta.movimientos.sorted { $0.fecha > $1.fecha }) { mov in

                    HStack(alignment: .top, spacing: 12) {

                        Image(systemName: mov.icono)
                            .font(.title2)
                            .foregroundStyle(colorDesdeString(mov.color))

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
                    .padding(.vertical, 10)

                    Divider()
                }
            }
            .padding()
            .cardWhite()
        }
    }
 
    // MARK: - ACCIONES
    func solicitar(_ accion: Accion) {
        accionPendiente = accion
        mostrarPassword = true
    }

    // MARK: - VALIDAR PASSWORD
    func validarPassword() {
        guard password == PASSWORD_ADMIN else {
            password = ""
            return
        }
        password = ""

        switch accionPendiente {

        case .editar:

            // 👉 GUARDAR CAMBIOS
            if modoEdicion {

                if !validarInventario() && !forzarSobreventa {
                    mostrarAlertaInventario = true
                    return
                }

                registrarMovimiento(
                    titulo: "Detalle de venta actualizado",
                    icono: "pencil.circle.fill",
                    color: "orange"
                )
            }

            // 👉 ENTRAR A EDICIÓN
            if !modoEdicion {
                cantidadesOriginales = [:]
                for d in venta.detalles {
                    cantidadesOriginales[d.modeloNombre] = d.cantidad
                }
            }

            modoEdicion.toggle()
            forzarSobreventa = false

            registrarMovimiento(
                titulo: modoEdicion ? "Edición habilitada" : "Edición finalizada",
                icono: "pencil",
                color: "orange"
            )

        case .cambiarIVA:
            venta.aplicaIVA.toggle()

            registrarMovimiento(
                titulo: "Cambio de IVA",
                icono: "percent",
                color: "blue"
            )

        case .enviarMercancia:
            guard !venta.mercanciaEnviada else { break }

            venta.mercanciaEnviada = true
            venta.fechaEnvio = Date()

            registrarMovimiento(
                titulo: "Mercancía enviada",
                icono: "truck.box.fill",
                color: "green"
            )

        case .cancelar:
            guard !venta.cancelada else { break }

            venta.cancelada = true

            registrarMovimiento(
                titulo: "Venta cancelada",
                icono: "xmark.octagon.fill",
                color: "red"
            )

        case .none:
            break
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - ELIMINAR MODELO
    func eliminarModelo(at index: Int) {

        let modelo = venta.detalles[index].modeloNombre
        let cantidad = venta.detalles[index].cantidad

        venta.detalles.remove(at: index)

        registrarMovimiento(
            titulo: "Modelo eliminado: \(modelo) (\(cantidad) pz)",
            icono: "trash.fill",
            color: "red"
        )

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - CÁLCULOS
    var subtotal: Double {
        venta.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
    }

    var iva: Double {
        venta.aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    // =====================================================
    // INVENTARIO
    // =====================================================
    func existenciaDisponible(modeloNombre: String) -> Int {

        let base = InventarioService
            .existenciaActual(
                modeloNombre: modeloNombre,
                context: context
            )
            .cantidad

        let reingresosProducto = reingresosDetalle
            .filter {
                !$0.esServicio &&
                $0.modelo?.nombre == modeloNombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        let reingresosServicio = reingresosDetalle
            .filter {
                $0.esServicio &&
                $0.nombreServicio == modeloNombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        return base + reingresosProducto + reingresosServicio
    }

    // ✅ Aplica SOLO diferencias reales (guardar)
    
    // 🚫 Validación antes de guardar
    func validarInventario() -> Bool {
        for d in venta.detalles {
            let existencia = existenciaDisponible(modeloNombre: d.modeloNombre)

            if d.cantidad > existencia {
                mensajeInventario =
                """
                Inventario insuficiente

                Modelo: \(d.modeloNombre)
                Existencia: \(existencia) pz
                Intentas usar: \(d.cantidad) pz

                ¿Deseas forzar la operación?
                """
                return false
            }
        }
        return true
    }

    // =====================================================
    // MOVIMIENTOS
    // =====================================================
    func registrarMovimiento(titulo: String, icono: String, color: String) {
        let mov = VentaClienteMovimiento(
            titulo: titulo,
            usuario: "Administrador",
            icono: icono,
            color: color,
            venta: venta
        )
        venta.movimientos.append(mov)
        context.insert(mov)
    }

    // =====================================================
    // MODELOS
    // =====================================================
    func obtenerModelo(nombre: String) -> Modelo? {
        try? context.fetch(
            FetchDescriptor<Modelo>(
                predicate: #Predicate { $0.nombre == nombre }
            )
        ).first
    }

    // =====================================================
    // UI HELPERS
    // =====================================================
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
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }

    func campoCosto(value: Binding<Double>, enabled: Bool) -> some View {
        let txt = Binding<String>(
            get: { String(format: "%.2f", value.wrappedValue) },
            set: { value.wrappedValue = Double($0) ?? value.wrappedValue }
        )

        return VStack(alignment: .leading) {
            Text("Costo unitario")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Text("MX$")
                    .foregroundStyle(.secondary)
                TextField("0.00", text: txt)
                    .keyboardType(.decimalPad)
                    .disabled(!enabled)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    func estadoFirma(_ data: Data?) -> some View {
        Group {
            if data != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("Pendiente")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }

    func formatoFecha(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year())
    }

    func colorDesdeString(_ c: String) -> Color {
        switch c {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        default: return .primary
        }
    }

    // =====================================================
    // IMPRESIÓN
    // =====================================================
    func imprimir() {
        let empresa = try? context.fetch(
            FetchDescriptor<Empresa>(predicate: #Predicate { $0.activo })
        ).first

        let pdfData = VentaClientePDFService.generarPDF(
            venta: venta,
            empresa: empresa
        )

        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Venta \(venta.folio)"
        printController.printInfo = info
        printController.printingItem = pdfData
        printController.present(animated: true)
    }
    }

