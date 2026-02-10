//
//  OrdenCompraInsumosDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
import SwiftUI
import SwiftData

struct OrdenCompraInsumosDetalleView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var orden: OrdenCompra

    // 🔑 Recepciones reales (fuente de verdad)
    @Query private var recepciones: [ReciboCompraDetalle]

    @State private var modoEdicion = false
    @State private var mostrarPassword = false
    @State private var mostrarCancelar = false
    @State private var password = ""

    private let PASSWORD_ADMIN = "1234"

    // =====================================================
    // MARK: - BLOQUEO REAL
    // =====================================================

    /// La orden se bloquea si existe AL MENOS una recepción activa
    var estaRecibida: Bool {
        recepciones.contains {
            $0.ordenCompra == orden &&
            $0.fechaEliminacion == nil
        }
    }

    var bloqueada: Bool {
        estaRecibida || orden.cancelada
    }

    // =====================================================
    // MARK: - MOVIMIENTOS (DATA)
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

        // Orden creada
        items.append(
            Movimiento(
                titulo: "Orden creada",
                usuario: "Sistema",
                fecha: orden.fechaOrden,
                icono: "doc.text.fill",
                color: .blue
            )
        )

        // Recepciones
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
                    color: eliminado ? .red : .green
                )
            )
        }

        // Cancelación
        if orden.cancelada {
            items.append(
                Movimiento(
                    titulo: "Orden cancelada",
                    usuario: "Administrador",
                    fecha: Date(),
                    icono: "xmark.octagon.fill",
                    color: .red
                )
            )
        }

        return items.sorted { $0.fecha > $1.fecha }
    }

    // =====================================================
    // MARK: - BODY
    // =====================================================

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ESTADOS
                if estaRecibida {
                    banner("🔒 ORDEN BLOQUEADA POR RECEPCIÓN", .orange)
                }

                if orden.cancelada {
                    banner("❌ ORDEN CANCELADA", .red)
                }

                // HEADER
                bloqueGris {
                    fila("Orden", folioOrden)
                    fila("Proveedor", orden.proveedor)
                    fila("Plazo de pago", "\(orden.plazoDias ?? 0) días")
                    fila("Fecha", formatoFecha(orden.fechaOrden))
                    fila("Fecha entrega", formatoFecha(orden.fechaEntrega))
                }

                // OBSERVACIONES
                bloqueGris {
                    Text("Observaciones")
                        .font(.headline)

                    if modoEdicion && !bloqueada {
                        TextEditor(text: $orden.observaciones)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text(orden.observaciones.isEmpty ? "—" : orden.observaciones)
                            .foregroundStyle(.secondary)
                    }
                }

                // DETALLES
                ForEach($orden.detalles) { $d in
                    bloqueGris {

                        Text(d.modelo)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(d.articulo)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        HStack(spacing: 12) {
                            campoCantidad($d.cantidad)
                            campoCosto($d.costoUnitario)
                        }

                        HStack {
                            Spacer()
                            Text("MX $ \(String(format: "%.2f", d.subtotal))")
                                .font(.headline)
                        }
                    }
                }

                // IVA
                bloqueGris {
                    Toggle("Aplicar IVA (16%)", isOn: ivaBinding)
                        .disabled(bloqueada)
                }

                // RESUMEN
                bloqueGris {
                    filaMoneda("Subtotal", subtotal)
                    filaMoneda("IVA", iva)
                    filaMoneda("Total", total, bold: true)
                }

                // MOVIMIENTOS
                movimientosCard

                Color.clear.frame(height: 90)
            }
            .padding()
        }
        .navigationTitle("Compra Insumos")

        // TOOLBAR
        .toolbar {
            if !bloqueada {
                Button(modoEdicion ? "Cerrar" : "Editar") {
                    if modoEdicion {
                        modoEdicion = false
                    } else {
                        mostrarPassword = true
                    }
                }
            }
        }

        // BOTÓN CANCELAR FIJO (FINO)
        .safeAreaInset(edge: .bottom) {
            if !bloqueada {
                VStack(spacing: 0) {
                    Divider()

                    Button {
                        mostrarCancelar = true
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancelar orden")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
            }
        }

        // ALERTAS
        .alert("Contraseña", isPresented: $mostrarPassword) {
            SecureField("Contraseña", text: $password)
            Button("Aceptar") {
                if password == PASSWORD_ADMIN {
                    modoEdicion = true
                }
                password = ""
            }
            Button("Cancelar", role: .cancel) {
                password = ""
            }
        }

        .alert("Cancelar orden", isPresented: $mostrarCancelar) {
            SecureField("Contraseña", text: $password)
            Button("Confirmar", role: .destructive) {
                if password == PASSWORD_ADMIN {
                    orden.cancelada = true
                    try? context.save()
                    dismiss()
                }
                password = ""
            }
            Button("No", role: .cancel) {
                password = ""
            }
        }
    }

    // =====================================================
    // MARK: - MOVIMIENTOS (UI)
    // =====================================================

    @ViewBuilder
    var movimientosCard: some View {
        if !movimientos.isEmpty {
            bloqueGris {
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
            }
        }
    }

    // =====================================================
    // MARK: - CAMPOS
    // =====================================================

    func campoCantidad(_ b: Binding<Int>) -> some View {
        VStack(spacing: 6) {
            Text("Cantidad")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(b.wrappedValue)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }

    func campoCosto(_ b: Binding<Double>) -> some View {
        VStack(spacing: 6) {
            Text("Costo unitario")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(String(format: "%.2f", b.wrappedValue))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity)
    }

    // =====================================================
    // MARK: - IVA
    // =====================================================

    var ivaBinding: Binding<Bool> {
        Binding(
            get: { orden.aplicaIVA },
            set: { nuevo in
                if modoEdicion && !bloqueada {
                    orden.aplicaIVA = nuevo
                }
            }
        )
    }

    // =====================================================
    // MARK: - CÁLCULOS
    // =====================================================

    var subtotal: Double {
        orden.detalles.reduce(0) { $0 + $1.subtotal }
    }

    var iva: Double {
        orden.aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    var folioOrden: String {
        "OCI-\(String(format: "%03d", orden.numeroOC))"
    }

    // =====================================================
    // MARK: - HELPERS
    // =====================================================

    func bloqueGris(@ViewBuilder _ c: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) { c() }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).foregroundStyle(.secondary)
        }
    }

    func filaMoneda(_ t: String, _ v: Double, bold: Bool = false) -> some View {
        HStack {
            Text(t).fontWeight(bold ? .bold : .regular)
            Spacer()
            Text("MX $ \(String(format: "%.2f", v))")
                .fontWeight(bold ? .bold : .regular)
        }
    }

    func formatoFecha(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year())
    }

    func banner(_ texto: String, _ color: Color) -> some View {
        Text(texto)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
