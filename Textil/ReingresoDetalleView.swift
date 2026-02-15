
//
//  ReingresoDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
//
//
//  ReingresoDetalleView.swift
//  Textil
//

//
//  ReingresoDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//

import SwiftUI
import SwiftData
import UIKit

struct ReingresoDetalleView: View {

    // MARK: - ENV
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var reingreso: Reingreso

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
    @State private var mostrarFirmaDevuelve = false
    @State private var mostrarFirmaRecibe = false
    @State private var firmaDevuelveData: Data?
    @State private var firmaRecibeData: Data?
    
    @State private var mostrarErrorImpresion = false
    @State private var mensajeErrorImpresion = ""

    @State private var mostrarErrorConfirmacion = false
    @State private var mensajeErrorConfirmacion = ""

    @Query private var reingresosDetalle: [ReingresoDetalle]


    // MARK: - BLOQUEO
    var bloqueada: Bool {
        reingreso.confirmado || reingreso.cancelado
    }

    // MARK: - MOVIMIENTOS (DATOS)
    var movimientosOrdenados: [ReingresoMovimiento] {
        reingreso.movimientos.sorted { $0.fecha > $1.fecha }
    }

    // MARK: - BODY
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
                    confirmarReingreso

                    // 👇 BLOQUE FINAL
                    VStack(spacing: 16) {
                        cancelarReingreso
                        movimientos
                    }
                }
                .padding()

            }
            .background(Color(.systemGray6))
            .navigationTitle("Detalle de reingreso")
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
            Button("Cancelar", role: .cancel) { password = "" }
            Button("Confirmar") { validarPassword() }
        }

        // ✅ CONFIRMAR
        .alert("Confirmar reingreso", isPresented: $mostrarConfirmacionConfirmar) {
            Button("Confirmar", role: .destructive) {
                solicitar(.confirmar)
            }
            Button("Cancelar", role: .cancel) {}
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

        .alert("No se puede confirmar", isPresented: $mostrarErrorConfirmacion) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mensajeErrorConfirmacion)
        }
        
        // ✍️ FIRMAS
        .sheet(isPresented: $mostrarFirmaDevuelve) {
            FirmaView(
                titulo: "Firma de quien devuelve",
                firmaData: $firmaDevuelveData
            ) { data in
                reingreso.firmaDevuelve = data
                try? context.save()
            }
        }
        .sheet(isPresented: $mostrarFirmaRecibe) {
            FirmaView(
                titulo: "Firma de quien recibe",
                firmaData: $firmaRecibeData
            ) { data in
                reingreso.firmaRecibe = data
                try? context.save()
            }
        }
    }

    // MARK: - ENCABEZADO
    var encabezado: some View {
        VStack(alignment: .leading, spacing: 8) {

            fila("Folio", reingreso.folio)

            fila(
                "Referencia / Nota",
                reingreso.referencia.isEmpty ? "—" : reingreso.referencia
            )
            
            fila(
                "Empresa",
                reingreso.empresa?.nombre ?? "—"
            )

            fila(
                "Cliente",
                reingreso.cliente?.nombreComercial ?? "—"
            )

            fila(
                "Fecha",
                formatoFecha(reingreso.fecha)
            )

            if reingreso.confirmado {
                estado("REINGRESO CONFIRMADO", .green)
            }

            if reingreso.cancelado {
                estado("REINGRESO CANCELADO", .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

    // MARK: - RESPONSABLES
    var responsables: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Responsables")
                .font(.headline)
                .foregroundStyle(.secondary)

            campoTexto(
                "Responsable",
                texto: $reingreso.responsable,
                enabled: modoEdicion && !bloqueada
            )

            campoTexto(
                "Recibe material",
                texto: $reingreso.recibeMaterial,
                enabled: modoEdicion && !bloqueada
            )
        }
        .cardWhite()
    }

    // MARK: - DETALLES
    var detalles: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Productos / Servicios")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(reingreso.detalles.indices, id: \.self) { index in
                let d = reingreso.detalles[index]
                VStack(alignment: .leading, spacing: 12) {

                    // TÍTULO: MODELO O SERVICIO + ELIMINAR
                    HStack {
                        Text(
                            d.esServicio
                            ? "Servicio: \(d.nombreServicio ?? "—")"
                            : "Modelo: \(d.modelo?.nombre ?? "—")"
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

                    // DESCRIPCIÓN (SOLO MODELO, IGUAL QUE SALIDA)
                    if !d.esServicio,
                       let modelo = d.modelo,
                       !modelo.descripcion.isEmpty {

                        Text(modelo.descripcion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // EXISTENCIA
                    Text(
                        "Existencia: \(existenciaDetalle(d)) pz"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    // CANTIDAD Y COSTO
                    HStack {
                        campoEntero(
                            "Cantidad",
                            value: Binding(
                                get: { reingreso.detalles[index].cantidad },
                                set: { reingreso.detalles[index].cantidad = $0 }
                            ),
                            enabled: modoEdicion && !bloqueada
                        )

                        campoCosto(
                            value: Binding(
                                get: { reingreso.detalles[index].costoUnitario },
                                set: { reingreso.detalles[index].costoUnitario = $0 }
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
                get: { reingreso.aplicaIVA },
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
        VStack(alignment: .leading, spacing: 8) {

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

    // MARK: - OBSERVACIONES (ANCHO COMPLETO)
    var observaciones: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Observaciones")
                .font(.headline)

            if modoEdicion && !bloqueada {
                TextEditor(text: $reingreso.observaciones)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)   // 👈 CLAVE
            } else {
                Text(
                    reingreso.observaciones.isEmpty
                    ? "—"
                    : reingreso.observaciones
                )
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)     // 👈 CLAVE
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)           // 👈 CLAVE
        .cardWhite()
    }

    // MARK: - FIRMAS
    var firmas: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("Firmas")
                .font(.headline)

            botonFirma(
                "✍️ Firma quien devuelve",
                data: reingreso.firmaDevuelve,
                action: { mostrarFirmaDevuelve = true }
            )

            Divider()

            botonFirma(
                "✍️ Firma quien recibe",
                data: reingreso.firmaRecibe,
                action: { mostrarFirmaRecibe = true }
            )
        }
        .cardWhite()
    }

    // MARK: - EXPORTAR
    var exportar: some View {
        VStack(spacing: 12) {

            // 📄 PDF
            Button {
                let empresa = reingreso.empresa

                let pdfData = ReingresoPDFService.generarPDF(
                    reingreso: reingreso,
                    empresa: empresa
                )

                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("Reingreso_\(reingreso.folio).pdf")

                try? pdfData.write(to: url)

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

            // 📊 EXCEL
            Button {
                let url = ReingresoExcelService.generarCSV(
                    reingreso: reingreso
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
                imprimir()
            } label: {
                boton("🖨 Imprimir", .blue)
            }
        }
        .cardWhite()
    }
    
    // MARK: - CONFIRMAR
    var confirmarReingreso: some View {
        Group {
            if !reingreso.confirmado && !reingreso.cancelado {
                Button {
                    mostrarConfirmacionConfirmar = true
                } label: {
                    boton("✅ Confirmar reingreso", .green)
                }
                .cardWhite()
            }
        }
    }

    // MARK: - CANCELAR
    var cancelarReingreso: some View {
        Group {
            if !reingreso.cancelado {
                Button(role: .destructive) {
                    solicitar(.cancelar)
                } label: {
                    boton("❌ Cancelar reingreso", .red)
                }
                .cardWhite()
            }
        }
    }

    // =====================================================
    // MARK: - MOVIMIENTOS (UI EXACTA)
    // =====================================================

    @ViewBuilder
    var movimientos: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Movimientos del reingreso")
                .font(.headline)

            if movimientosOrdenados.isEmpty {
                Text("Sin movimientos registrados")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
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

                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 👈 ESTA ES LA CLAVE
        .cardWhite()
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
            if let nuevoIVA = ivaPendiente {
                reingreso.aplicaIVA = nuevoIVA
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

            if reingreso.firmaDevuelve == nil {
                mensajeErrorConfirmacion = "Falta la firma de quien devuelve."
                mostrarErrorConfirmacion = true
                return
            }

            if reingreso.firmaRecibe == nil {
                mensajeErrorConfirmacion = "Falta la firma de quien recibe."
                mostrarErrorConfirmacion = true
                return
            }

            reingreso.confirmado = true
            modoEdicion = false

            registrarMovimiento(
                "Reingreso confirmado",
                "checkmark.circle.fill",
                "green"
            )

        case .cancelar:
            reingreso.cancelado = true

            registrarMovimiento(
                "Reingreso cancelado",
                "xmark.octagon.fill",
                "red"
            )

        case .none:
            break
        }

        try? context.save()
    }

    func eliminarDetalle(at index: Int) {
        reingreso.detalles.remove(at: index)
        try? context.save()
    }

    // MARK: - CÁLCULOS
    var subtotal: Double {
        reingreso.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
    }

    var iva: Double {
        reingreso.aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    // MARK: - INVENTARIO
    func existenciaDetalle(_ d: ReingresoDetalle) -> Int {

        let nombre: String

        if d.esServicio {
            guard let n = d.nombreServicio else { return 0 }
            nombre = n
        } else {
            guard let n = d.modelo?.nombre else { return 0 }
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

        if reingreso.responsable
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {

            mensajeErrorImpresion = "Debes capturar el nombre del responsable."
            return false
        }

        if reingreso.recibeMaterial
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty {

            mensajeErrorImpresion = "Debes capturar el nombre de quien recibe."
            return false
        }

        if reingreso.firmaDevuelve == nil {
            mensajeErrorImpresion = "Falta la firma de quien devuelve."
            return false
        }

        if reingreso.firmaRecibe == nil {
            mensajeErrorImpresion = "Falta la firma de quien recibe."
            return false
        }

        return true
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
            .foregroundStyle(c)
    }
    
    // MARK: - IMPRESIÓN
    func imprimir() {
        let empresa = reingreso.empresa

        let pdfData = ReingresoPDFService.generarPDF(
            reingreso: reingreso,
            empresa: empresa
        )

        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Reingreso \(reingreso.folio)"

        printController.printInfo = info
        printController.printingItem = pdfData
        printController.present(animated: true)
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

    func botonFirma(_ titulo: String, data: Data?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(titulo)
                Spacer()
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
    }

    func formatoMX(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }

    func formatoFecha(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year())
    }
    
    // MARK: - COLOR DESDE STRING
    func colorDesdeString(_ c: String) -> Color {
        switch c {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .primary
        }
    }

    // =====================================================
    // MARK: - MOVIMIENTOS (REGISTRO)
    // =====================================================
    func registrarMovimiento(
        _ titulo: String,
        _ icono: String,
        _ color: String
    ) {
        let mov = ReingresoMovimiento(
            titulo: titulo,
            usuario: "Administrador",
            icono: icono,
            color: color,
            reingreso: reingreso
        )

        reingreso.movimientos.append(mov)
        context.insert(mov)
        try? context.save()
    }
}
