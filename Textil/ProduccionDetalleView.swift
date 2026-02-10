//
//  ProduccionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//
//  ProduccionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//

import SwiftUI
import SwiftData

struct ProduccionDetalleView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var produccion: Produccion

    // CATÁLOGOS
    @Query private var modelos: [Modelo]

    @Query(filter: #Predicate<Maquilero> { $0.activo == true })
    private var maquileros: [Maquilero]

    // 🔹 RECIBOS (PARA BLOQUEO)
    @Query private var recepciones: [ReciboDetalle]

    // UI
    @State private var pzCortadasTexto: String = ""
    @State private var costoMaquilaTexto: String = ""
    @State private var aplicaIVA: Bool = false

    // 🔴 CANCELAR PRODUCCIÓN
    @State private var mostrarCancelarProduccion = false
    @State private var password = ""

    private let PASSWORD_ADMIN = "1234"

    // =====================================================
    // MARK: - BODY
    // =====================================================

    var body: some View {
        NavigationStack {
            Form {

                // 🔴 PRODUCCIÓN CANCELADA
                if ordenCancelada {
                    Text("⚠️ PRODUCCIÓN CANCELADA (solo lectura)")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }

                // 🟠 BLOQUEADA POR RECIBO
                if bloqueadaPorRecibo && !ordenCancelada {
                    Text("⚠️ BLOQUEADA POR RECIBO (solo lectura)")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }

                // MARK: - SOLICITUD
                Section("Solicitud") {

                    fila(
                        "No. venta",
                        produccion.detalle?.orden != nil
                        ? "Venta #\(produccion.detalle!.orden!.numeroVenta)"
                        : "—"
                    )

                    fila("Pedido cliente", produccion.detalle?.orden?.numeroPedidoCliente ?? "")
                    fila("Artículo", produccion.detalle?.articulo ?? "")
                    fila("Modelo", produccion.detalle?.modelo ?? "")
                    fila("Descripción", descripcionModelo)
                    fila("Cliente", produccion.detalle?.orden?.cliente ?? "")

                    fila(
                        "Fecha envío",
                        produccion.detalle?.orden?.fechaCreacion.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) ?? ""
                    )

                    fila(
                        "Fecha entrega",
                        produccion.detalle?.orden?.fechaEntrega.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ) ?? ""
                    )

                    fila("Cantidad solicitada", "\(produccion.detalle?.cantidad ?? 0)")
                }

                // 🧾 ORDEN DE MAQUILA
                if let om = produccion.ordenMaquila {
                    VStack(spacing: 6) {
                        Text("ORDEN DE MAQUILA")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)

                        Text(om)
                            .font(.title2.bold())
                            .foregroundStyle(.blue)

                        if let fecha = produccion.fechaOrdenMaquila {
                            Text(
                                fecha.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // MARK: - PRODUCCIÓN
                Section("Producción") {

                    Picker("Maquilero", selection: $produccion.maquilero) {
                        Text("Seleccionar").tag("")
                        ForEach(maquileros) { m in
                            Text(m.nombre).tag(m.nombre)
                        }
                    }
                    .disabled(vistaSoloLectura)

                    HStack {
                        Text("Pz cortadas")
                        Spacer()
                        TextField("0", text: $pzCortadasTexto)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .disabled(vistaSoloLectura)
                    }

                    HStack {
                        Text("Costo maquila")
                        Spacer()
                        Text("MX$")
                            .foregroundStyle(.secondary)

                        TextField("0.00", text: $costoMaquilaTexto)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .disabled(vistaSoloLectura)
                    }
                }

                Toggle("Aplicar IVA (16%)", isOn: $aplicaIVA)
                    .disabled(vistaSoloLectura)

                // MARK: - CÁLCULOS
                Section("Cálculos") {
                    fila("Pz pendientes", "\(pzPendientes)")
                    fila("Subtotal", formatoMX(subtotal))
                    fila("IVA", formatoMX(iva))
                    fila("Total", formatoMX(total))
                }

                // MARK: - MOVIMIENTOS
                movimientosCard
            }
            .navigationTitle("Producción")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {

                        produccion.pzCortadas = Int(pzCortadasTexto) ?? 0
                        produccion.costoMaquila = Double(costoMaquilaTexto) ?? 0

                        if let detalle = produccion.detalle {
                            detalle.produccion = produccion
                            detalle.orden?.aplicaIVA = aplicaIVA
                        }

                        generarOrdenMaquilaSiNecesaria()

                        try? context.save()
                        dismiss()
                    }
                    .disabled(vistaSoloLectura)
                }
            }

            // 🔴 BOTÓN GRANDE Y VISIBLE
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()

                    Button {
                        mostrarCancelarProduccion = true
                    } label: {
                        HStack {
                            Image(systemName: "xmark.octagon.fill")
                            Text("Cancelar producción")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
            }

            .onAppear {
                pzCortadasTexto = produccion.pzCortadas > 0
                    ? String(produccion.pzCortadas)
                    : ""

                costoMaquilaTexto = produccion.costoMaquila > 0
                    ? String(format: "%.2f", produccion.costoMaquila)
                    : ""

                aplicaIVA = produccion.detalle?.orden?.aplicaIVA ?? false
            }

            // 🔐 CONFIRMACIÓN
            .alert("Cancelar producción", isPresented: $mostrarCancelarProduccion) {

                SecureField("Contraseña", text: $password)

                Button("Confirmar", role: .destructive) {
                    guard password == PASSWORD_ADMIN else {
                        password = ""
                        return
                    }

                    // ❌ NO SE PUEDE CANCELAR SI YA HAY MOVIMIENTO
                    if produccion.pzCortadas > 0 || bloqueadaPorRecibo {
                        password = ""
                        return
                    }

                    produccion.cancelada = true
                    try? context.save()
                    dismiss()
                }

                Button("No", role: .cancel) {
                    password = ""
                }

            } message: {
                Text("Solo se puede cancelar antes de iniciar producción.")
            }
        }
    }

    // =====================================================
    // MARK: - BLOQUEOS
    // =====================================================

    var ordenCancelada: Bool {
        produccion.cancelada || (produccion.detalle?.orden?.cancelada ?? false)
    }

    var bloqueadaPorRecibo: Bool {
        guard let detalle = produccion.detalle else { return false }

        return recepciones.contains {
            $0.detalleOrden == detalle &&
            $0.fechaEliminacion == nil
        }
    }

    var vistaSoloLectura: Bool {
        ordenCancelada || bloqueadaPorRecibo
    }

    // =====================================================
    // MARK: - ORDEN DE MAQUILA
    // =====================================================

    func generarOrdenMaquilaSiNecesaria() {

        if vistaSoloLectura { return }
        if produccion.ordenMaquila != nil { return }

        guard
            !produccion.maquilero.isEmpty,
            let pz = Int(pzCortadasTexto), pz > 0,
            let costo = Double(costoMaquilaTexto), costo > 0
        else { return }

        let descriptor = FetchDescriptor<Produccion>(
            predicate: #Predicate { $0.ordenMaquila != nil }
        )

        let totalExistentes = (try? context.fetch(descriptor).count) ?? 0
        let consecutivo = totalExistentes + 1

        produccion.ordenMaquila = String(format: "OM-%05d", consecutivo)
        produccion.fechaOrdenMaquila = Date()
    }

    // =====================================================
    // MARK: - CÁLCULOS
    // =====================================================

    var pzPendientes: Int {
        let solicitadas = produccion.detalle?.cantidad ?? 0
        let cortadas = Int(pzCortadasTexto) ?? 0
        return max(solicitadas - cortadas, 0)
    }

    var subtotal: Double {
        Double(Int(pzCortadasTexto) ?? 0) * (Double(costoMaquilaTexto) ?? 0)
    }

    var iva: Double {
        aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    // =====================================================
    // MARK: - DESCRIPCIÓN MODELO
    // =====================================================

    var descripcionModelo: String {
        guard let nombre = produccion.detalle?.modelo else {
            return "Sin descripción"
        }

        return modelos.first(where: { $0.nombre == nombre })?.descripcion
            ?? "Sin descripción"
    }

    // =====================================================
    // MARK: - MOVIMIENTOS
    // =====================================================

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

        // Producción creada
        items.append(
            Movimiento(
                titulo: "Producción creada",
                usuario: "Sistema",
                fecha: produccion.fechaOrdenMaquila ?? Date(),
                icono: "hammer.fill",
                color: .blue
            )
        )

        // Orden de maquila
        if let om = produccion.ordenMaquila,
           let fecha = produccion.fechaOrdenMaquila {

            items.append(
                Movimiento(
                    titulo: "Orden de maquila generada (\(om))",
                    usuario: "Sistema",
                    fecha: fecha,
                    icono: "doc.text.fill",
                    color: .green
                )
            )
        }

        // Cancelación
        if produccion.cancelada {
            items.append(
                Movimiento(
                    titulo: "Producción cancelada",
                    usuario: "Administrador",
                    fecha: Date(),
                    icono: "xmark.octagon.fill",
                    color: .red
                )
            )
        }

        return items.sorted { $0.fecha > $1.fecha }
    }

    @ViewBuilder
    var movimientosCard: some View {
        Group {
            if !movimientos.isEmpty {
                VStack(alignment: .leading, spacing: 14) {

                    Text("Movimientos de la producción")
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
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    // =====================================================
    // MARK: - HELPERS
    // =====================================================

    func fila(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(.secondary)
        }
    }

    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
