//
//  SalidaInsumoDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//
//
//  SalidaInsumoDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//

import SwiftUI
import SwiftData
import UIKit

struct SalidaInsumoDetalleView: View {

    // MARK: - ENV
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var salida: SalidaInsumo

    // MARK: - SEGURIDAD
    private let PASSWORD_ADMIN = "1234"
    @State private var mostrarPassword = false
    @State private var password = ""
    @State private var accionPendiente: Accion?

    enum Accion {
        case editar
        case confirmar
        case cancelar
    }

    // MARK: - UI STATE
    @State private var modoEdicion = false
    @State private var mostrarConfirmacionConfirmar = false
    @State private var mostrarConfirmacionEliminar = false
    @State private var indiceDetalleAEliminar: Int?
    
    @State private var ivaPendiente: Bool?

    // Firmas
    @State private var mostrarFirmaEntrega = false
    @State private var mostrarFirmaRecibe = false
    @State private var firmaEntregaData: Data?
    @State private var firmaRecibeData: Data?

    @State private var mostrarErrorImpresion = false
    @State private var mensajeErrorImpresion = ""

    @State private var mostrarConfirmacionCancelar = false
    @State private var alertaActiva: AlertaActiva?
    
    @Query private var reingresosDetalle: [ReingresoDetalle]
    
    enum AlertaActiva: Identifiable {
        case confirmarSalida
        case cancelarSalida
        case eliminarDetalle
        case errorImpresion
        case password

        var id: Int { hashValue }
    }

    // MARK: - BLOQUEO
    var bloqueada: Bool {
        salida.confirmada || salida.cancelada
    }
    // MARK: - MIGRACIÓN DE DATOS ANTIGUOS
    func migrarFacturaDesdeObservacionesSiAplica() {
        if salida.facturaNota.isEmpty,
           !salida.observaciones.isEmpty {

            salida.facturaNota = salida.observaciones
            salida.observaciones = ""

            registrarMovimiento(
                "Migración factura desde observaciones",
                "arrow.triangle.branch",
                "blue"
            )

            try? context.save()
        }
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    encabezado
                    responsables
                    detalles
                    ivaToggle
                    totales
                    observaciones
                    firmas
                    exportar
                    confirmarSalida
                    cancelarSalida
                    movimientos
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Detalle de salida")
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
        }
        // 🔐 PASSWORD
        .alert("Contraseña", isPresented: $mostrarPassword) {
            SecureField("Contraseña", text: $password)
            Button("Cancelar", role: .cancel) {
                password = ""
            }
            Button("Confirmar") {
                validarPassword()
            }
        }

        // ✅ CONFIRMAR SALIDA
        .alert("Confirmar salida", isPresented: $mostrarConfirmacionConfirmar) {
            Button("Confirmar", role: .destructive) {
                solicitar(.confirmar)
            }
            Button("Cancelar", role: .cancel) {}
        }

        // ❌ CONFIRMAR CANCELACIÓN (IGUAL QUE ELIMINAR)
        .alert("Cancelar salida", isPresented: $mostrarConfirmacionCancelar) {
            Button("Cancelar salida", role: .destructive) {
                accionPendiente = .cancelar
                mostrarPassword = true
            }
            Button("Cerrar", role: .cancel) {}
        } message: {
            Text(
                """
                ¿Estás seguro de cancelar esta salida?

                Esta acción no se puede deshacer.
                """
            )
        }

        // 🗑️ ELIMINAR DETALLE
        .alert("Eliminar registro", isPresented: $mostrarConfirmacionEliminar) {
            Button("Eliminar", role: .destructive) {
                if let index = indiceDetalleAEliminar {
                    eliminarDetalle(at: index)
                    indiceDetalleAEliminar = nil
                }
            }
            Button("Cancelar", role: .cancel) {
                indiceDetalleAEliminar = nil
            }
        }

        // 🚫 BLOQUEO DE IMPRESIÓN
        .alert("No se puede imprimir", isPresented: $mostrarErrorImpresion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mensajeErrorImpresion)
        }

        // ✍️ FIRMAS
        .sheet(isPresented: $mostrarFirmaEntrega) {
            FirmaView(
                titulo: "Firma de entrega",
                firmaData: $firmaEntregaData
            ) { data in
                salida.firmaEntrega = data
                try? context.save()
            }
        }
        .sheet(isPresented: $mostrarFirmaRecibe) {
            FirmaView(
                titulo: "Firma de quien recibe",
                firmaData: $firmaRecibeData
            ) { data in
                salida.firmaRecibe = data
                try? context.save()
            }
        }
        .onAppear {
            migrarFacturaDesdeObservacionesSiAplica()
        }
    }
    // MARK: - EXPORTAR
    var exportar: some View {
        VStack(spacing: 12) {

            // 📄 EXPORTAR PDF
            Button {
                let empresa = try? context.fetch(
                    FetchDescriptor<Empresa>(
                        predicate: #Predicate { $0.activo }
                    )
                ).first

                let pdfData = SalidaInsumoPDFService.generarPDF(
                    salida: salida,
                    empresa: empresa
                )

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("Salida_\(salida.folio).pdf")

                try? pdfData.write(to: url)

                registrarMovimiento(
                    "PDF generado",
                    "doc.richtext",
                    "blue"
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

            // 📊 EXPORTAR EXCEL
            Button {
                let url = SalidaInsumoExcelService.generarCSV(
                    salida: salida
                )

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

            // 🖨 IMPRIMIR
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

    // MARK: - ENCABEZADO
    var encabezado: some View {
        VStack(alignment: .leading, spacing: 8) {

            fila("Folio de salida", salida.folio)

            fila(
                "# Factura / Nota",
                salida.facturaNota.isEmpty ? "—" : salida.facturaNota
            )

            fila(
                "Cliente",
                salida.cliente?.nombreComercial ?? "—"
            )

            fila(
                "Agente",
                salida.agente != nil
                    ? "\(salida.agente!.nombre) \(salida.agente!.apellido)"
                    : "—"
            )

            fila(
                "Fecha de salida",
                formatoFecha(salida.fecha)
            )

            fila(
                "Fecha de entrega",
                formatoFecha(salida.fechaEntrega)
            )

            if salida.confirmada {
                estado("SALIDA CONFIRMADA", .green)
            }

            if salida.cancelada {
                estado("SALIDA CANCELADA", .red)
            }
        }
        .cardWhite()
    }


    // MARK: - RESPONSABLES
    var responsables: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Responsables")
                .font(.headline)
                .foregroundStyle(.secondary)

            // RESPONSABLE
            VStack(alignment: .leading, spacing: 6) {
                Text("Responsable")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if modoEdicion && !bloqueada {
                    TextField(
                        "Nombre del responsable",
                        text: Binding(
                            get: { salida.responsable },
                            set: { salida.responsable = $0 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(
                        salida.responsable.isEmpty
                        ? "—"
                        : salida.responsable
                    )
                }
            }

            // QUIÉN RECIBE
            VStack(alignment: .leading, spacing: 6) {
                Text("Recibe material / servicio")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if modoEdicion && !bloqueada {
                    TextField(
                        "Nombre de quien recibe",
                        text: Binding(
                            get: { salida.recibeMaterial },
                            set: { salida.recibeMaterial = $0 }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(
                        salida.recibeMaterial.isEmpty
                        ? "—"
                        : salida.recibeMaterial
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardWhite()
    }

    // MARK: - DETALLES
    var detalles: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Insumos / Servicios")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(salida.detalles.indices, id: \.self) { index in
                let d = salida.detalles[index]

                VStack(alignment: .leading, spacing: 12) {

                    // MODELO / SERVICIO + ELIMINAR
                    HStack {
                        Text(
                            d.esServicio
                            ? "Servicio: \(d.nombreServicio ?? "—")"
                            : "Modelo: \(d.modeloNombre ?? "—")"
                        )
                        .font(.headline)

                        Spacer()

                        if modoEdicion && !bloqueada {
                            Button(role: .destructive) {
                                indiceDetalleAEliminar = index
                                mostrarConfirmacionEliminar = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }

                    // DESCRIPCIÓN (IGUAL QUE VENTAS)
                    if !d.esServicio,
                       let modelo = obtenerModelo(nombre: d.modeloNombre),
                       !modelo.descripcion.isEmpty {

                        Text(modelo.descripcion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // EXISTENCIA (IGUAL QUE VENTAS)
                    Text(
                        "Existencia: \(existenciaDetalle(d)) pz"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // CANTIDAD / COSTO (EDITABLES)
                    HStack {
                        campoEntero(
                            "Cantidad",
                            value: Binding(
                                get: { salida.detalles[index].cantidad },
                                set: { salida.detalles[index].cantidad = $0 }
                            ),
                            enabled: modoEdicion && !bloqueada
                        )

                        campoCosto(
                            value: Binding(
                                get: { salida.detalles[index].costoUnitario },
                                set: { salida.detalles[index].costoUnitario = $0 }
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
                get: { salida.aplicaIVA },
                set: { nuevoValor in
                    ivaPendiente = nuevoValor
                    solicitar(.editar)
                }
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

                fila("IVA (16%)", formatoMX(iva))

                Divider()

                HStack {
                    Text("Total")
                        .fontWeight(.bold)
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
                TextEditor(text: $salida.observaciones)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(salida.observaciones.isEmpty ? "—" : salida.observaciones)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)   // 👈 CLAVE
        .cardWhite()
    }
    
    // MARK: - FIRMAS
    var firmas: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Firmas")
                .font(.headline)
                .foregroundStyle(.secondary)

            // FIRMA ENTREGA
            Button {
                guard !bloqueada else { return }

                if modoEdicion {
                    salida.firmaEntrega = nil
                }

                firmaEntregaData = salida.firmaEntrega
                mostrarFirmaEntrega = true

            } label: {
                HStack {
                    Text("✍️ Firma entrega")
                    Spacer()
                    estadoFirma(salida.firmaEntrega)
                }
            }
            .disabled(bloqueada)

            Divider()

            // FIRMA RECIBE
            Button {
                guard !bloqueada else { return }

                if modoEdicion {
                    salida.firmaRecibe = nil
                }

                firmaRecibeData = salida.firmaRecibe
                mostrarFirmaRecibe = true

            } label: {
                HStack {
                    Text("✍️ Firma recibe")
                    Spacer()
                    estadoFirma(salida.firmaRecibe)
                }
            }
            .disabled(bloqueada)
        }
        .cardWhite()
    }

    // MARK: - CONFIRMAR
    var confirmarSalida: some View {
        Group {
            if !salida.confirmada && !salida.cancelada {
                Button {
                    mostrarConfirmacionConfirmar = true
                } label: {
                    boton("✅ Confirmar salida", .green)
                }
                .cardWhite()
            }
        }
    }

    // MARK: - CANCELAR
    var cancelarSalida: some View {
        Group {
            if !salida.cancelada {
                Button(role: .destructive) {
                    mostrarConfirmacionCancelar = true   // 👈 AQUÍ
                } label: {
                    boton("❌ Cancelar salida", .red)
                }
                .cardWhite()
            }
        }
    }

    // MARK: - MOVIMIENTOS
    
    var movimientosOrdenados: [SalidaInsumoMovimiento] {
        salida.movimientos.sorted { $0.fecha > $1.fecha }
    }
    
    // =====================================================
    // MARK: - MOVIMIENTOS (UI EXACTA)
    // =====================================================

    @ViewBuilder
    var movimientos: some View {
        Group {
            if !movimientosOrdenados.isEmpty {
                VStack(alignment: .leading, spacing: 14) {

                    Text("Movimientos de la salida")
                        .font(.headline)

                    ForEach(movimientosOrdenados) { mov in
                        VStack(alignment: .leading, spacing: 0) {

                            HStack(alignment: .top, spacing: 12) {

                                Image(systemName: mov.icono)
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
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Divider()
                        }
                    }
                }
                .cardWhite()
            }
        }
    }

    // MARK: - ACCIONES
    func solicitar(_ accion: Accion) {
        accionPendiente = accion
        mostrarPassword = true
    }

    func validarPassword() {
        guard password == PASSWORD_ADMIN else {
            password = ""
            return
        }
        password = ""

        switch accionPendiente {
        case .editar:

            // 👉 aplicar cambio de IVA si viene del toggle
            if let nuevoIVA = ivaPendiente {
                salida.aplicaIVA = nuevoIVA
                ivaPendiente = nil

                registrarMovimiento(
                    "Cambio de IVA",
                    "percent",
                    "blue"
                )
            } else {
                modoEdicion.toggle()
            }

        case .confirmar:
            guard !salida.enviada else { break }

            salida.enviada = true
            salida.confirmada = true

            registrarMovimiento(
                "Producto / servicio completado",
                "checkmark.circle.fill",
                "green"
            )

        case .cancelar:
            salida.cancelada = true
            registrarMovimiento("Salida cancelada", "xmark.octagon.fill", "red")

        case .none:
            break
        }

        try? context.save()
    }

    func eliminarDetalle(at index: Int) {
        let d = salida.detalles[index]
        salida.detalles.remove(at: index)

        registrarMovimiento(
            "Registro eliminado (\(d.cantidad))",
            "trash.fill",
            "red"
        )

        try? context.save()
    }

    func registrarMovimiento(_ titulo: String, _ icono: String, _ color: String) {
        let mov = SalidaInsumoMovimiento(
            titulo: titulo,
            usuario: "Administrador",
            icono: icono,
            color: color,
            salida: salida
        )
        salida.movimientos.append(mov)
        context.insert(mov)
    }

    // MARK: - CÁLCULOS
    var subtotal: Double {
        salida.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
    }

    var iva: Double {
        salida.aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }


    // MARK: - UI HELPERS
    func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t).foregroundStyle(.secondary)
            Spacer()
            Text(v)
        }
    }

    func estado(_ t: String, _ c: Color) -> some View {
        Text(t)
            .font(.caption.bold())
            .foregroundStyle(c)
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
            Text(t)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .disabled(!enabled)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
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
                    .fill(Color(.systemGray6))
            )
        }
    }

    func campoTexto(_ t: String, texto: Binding<String>, enabled: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(t).font(.caption)
            TextField("", text: texto)
                .disabled(!enabled)
        }
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }

    func colorDesdeString(_ c: String) -> Color {
        switch c {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        default: return .primary
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

    // =====================================================
    // HELPERS MODELO / INVENTARIO
    // =====================================================

    func obtenerModelo(nombre: String?) -> Modelo? {
        guard let nombre else { return nil }

        return try? context.fetch(
            FetchDescriptor<Modelo>(
                predicate: #Predicate { $0.nombre == nombre }
            )
        ).first
    }

    func existenciaDisponible(modeloNombre: String?) -> Int {
        guard let modeloNombre else { return 0 }

        return InventarioService
            .existenciaActual(
                modeloNombre: modeloNombre,
                context: context
            )
            .cantidad
    }
    func existenciaDetalle(_ d: SalidaInsumoDetalle) -> Int {

        let nombre: String

        if d.esServicio {
            guard let n = d.nombreServicio else { return 0 }
            nombre = n
        } else {
            guard let n = d.modeloNombre else { return 0 }
            nombre = n
        }

        // 1️⃣ Base histórica
        let base = InventarioService
            .existenciaActual(
                modeloNombre: nombre,
                context: context
            )
            .cantidad

        // 2️⃣ Reingresos PRODUCTO
        let reingresosProducto = reingresosDetalle
            .filter {
                !$0.esServicio &&
                $0.modelo?.nombre == nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 3️⃣ Reingresos SERVICIO
        let reingresosServicio = reingresosDetalle
            .filter {
                $0.esServicio &&
                $0.nombreServicio == nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        return base + reingresosProducto + reingresosServicio
    }

    func puedeImprimir() -> Bool {

        if salida.responsable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mensajeErrorImpresion = "Debes capturar el nombre del responsable."
            return false
        }

        if salida.recibeMaterial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            mensajeErrorImpresion = "Debes capturar el nombre de quien recibe."
            return false
        }

        if salida.firmaEntrega == nil {
            mensajeErrorImpresion = "Falta la firma de entrega."
            return false
        }

        if salida.firmaRecibe == nil {
            mensajeErrorImpresion = "Falta la firma de quien recibe."
            return false
        }

        return true
    }

    // =====================================================
    // IMPRESIÓN
    // =====================================================
    func imprimir() {
        let empresa = try? context.fetch(
            FetchDescriptor<Empresa>(
                predicate: #Predicate { $0.activo }
            )
        ).first

        let pdfData = SalidaInsumoPDFService.generarPDF(
            salida: salida,
            empresa: empresa
        )

        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Salida \(salida.folio)"

        printController.printInfo = info
        printController.printingItem = pdfData
        printController.present(animated: true)
    }

}
func formatoFecha(_ d: Date?) -> String {
    guard let d else { return "—" }
    return d.formatted(.dateTime.day().month(.abbreviated).year())
    
    
}
