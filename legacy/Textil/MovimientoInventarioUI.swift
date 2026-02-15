//
//  MovimientoInventarioUI.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  MovimientoInventarioUI.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  MovimientoInventarioUI.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import SwiftUI
import SwiftData

// =====================================================
// MARK: - MODELO UI
// =====================================================
struct MovimientoInventarioUI: Identifiable {
    let id = UUID()
    let tipo: String
    let origen: String
    let usuario: String
    let fecha: Date
    let cantidad: Int
}

// =====================================================
// MARK: - VIEW
// =====================================================
struct InventarioModeloMovimientosView: View {

    let modeloNombre: String

    // 🔄 FORZAR REFRESH
    @State private var refreshID = UUID()

    // 🔗 FUENTES REALES
    @Query private var compras: [ReciboCompraDetalle]
    @Query private var producciones: [ReciboProduccion]
    @Query private var ventas: [VentaClienteDetalle]
    @Query private var salidas: [SalidaInsumoDetalle]
    @Query private var reingresosDetalle: [ReingresoDetalle]

    // =====================================================
    // MARK: - BODY
    // =====================================================
    var body: some View {
        List {

            // =============================
            // 📥 INGRESOS
            // =============================
            Section("📥 Ingresos") {
                ForEach(ingresos) { mov in
                    fila(mov, color: .green)
                }

                if ingresos.isEmpty {
                    Text("Sin ingresos")
                        .foregroundStyle(.secondary)
                }
            }

            // =============================
            // 📤 EGRESOS
            // =============================
            Section("📤 Egresos") {
                ForEach(egresos) { mov in
                    fila(mov, color: .red)
                }

                if egresos.isEmpty {
                    Text("Sin egresos")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .id(refreshID)
        .onChange(
            of: reingresosDetalle.map {
                "\($0.id)-\($0.reingreso?.confirmado ?? false)-\($0.reingreso?.cancelado ?? false)"
            }
        ) { _ in
            refreshID = UUID()
        }
        .navigationTitle(modeloNombre)
        .navigationBarTitleDisplayMode(.inline)
    }

    // =====================================================
    // MARK: - INGRESOS
    // =====================================================
    var ingresos: [MovimientoInventarioUI] {

        var items: [MovimientoInventarioUI] = []

        // 🟢 COMPRAS
        items += compras
            .filter { $0.modelo == modeloNombre && $0.fechaEliminacion == nil }
            .map {
                MovimientoInventarioUI(
                    tipo: "Compra",
                    origen: "Recibo de compra",
                    usuario: "Sistema",
                    fecha: $0.recibo?.fechaRecibo ?? .distantPast,
                    cantidad: Int($0.monto)
                )
            }

        // 🟢 PRODUCCIÓN
        items += producciones.flatMap { recibo in
            recibo.detalles
                .filter { $0.modelo == modeloNombre && $0.fechaEliminacion == nil }
                .map {
                    MovimientoInventarioUI(
                        tipo: "Producción",
                        origen: "Producción",
                        usuario: "Producción",
                        fecha: recibo.fechaRecibo,
                        cantidad: $0.pzPrimera + $0.pzSaldo
                    )
                }
        }

        // 🟢 REINGRESOS (MODELOS Y SERVICIOS, SOLO CONFIRMADOS)
        items += reingresosDetalle
            .filter {
                $0.reingreso?.confirmado == true &&
                $0.reingreso?.cancelado == false &&
                (
                    (!$0.esServicio && $0.modelo?.nombre == modeloNombre) ||
                    ($0.esServicio && $0.nombreServicio == modeloNombre)
                )
            }
            .map {
                MovimientoInventarioUI(
                    tipo: "Reingreso",
                    origen: $0.esServicio ? "Reingreso (Servicio)" : "Reingreso (Producto)",
                    usuario: "Sistema",
                    fecha: $0.reingreso?.fecha ?? .distantPast,
                    cantidad: $0.cantidad
                )
            }

        return items.sorted { $0.fecha > $1.fecha }
    }

    // =====================================================
    // MARK: - EGRESOS
    // =====================================================
    var egresos: [MovimientoInventarioUI] {

        var items: [MovimientoInventarioUI] = []

        // 🔴 VENTAS
        items += ventas
            .filter { $0.modeloNombre == modeloNombre && $0.fechaEliminacion == nil }
            .map {
                MovimientoInventarioUI(
                    tipo: "Venta",
                    origen: "Venta cliente",
                    usuario: "Sistema",
                    fecha: $0.venta?.fechaVenta ?? .distantPast,
                    cantidad: $0.cantidad
                )
            }

        // 🔴 SALIDAS
        items += salidas
            .filter { $0.modeloNombre == modeloNombre }
            .map {
                MovimientoInventarioUI(
                    tipo: "Salida",
                    origen: "Salida de insumo",
                    usuario: "Sistema",
                    fecha: $0.salida?.fecha ?? .distantPast,
                    cantidad: $0.cantidad
                )
            }

        return items.sorted { $0.fecha > $1.fecha }
    }

    // =====================================================
    // MARK: - UI ROW
    // =====================================================
    func fila(_ mov: MovimientoInventarioUI, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {

            HStack {
                Text(mov.tipo)
                    .font(.headline)
                    .foregroundStyle(color)

                Spacer()

                Text("\(mov.cantidad)")
                    .font(.headline)
                    .foregroundStyle(color)
            }

            Text(mov.origen)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Usuario: \(mov.usuario)")
                .font(.caption2)
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
        .padding(.vertical, 4)
    }
}

// =====================================================
// MARK: - PREVIEW
// =====================================================
#Preview {
    NavigationStack {
        InventarioModeloMovimientosView(modeloNombre: "MODELO PRUEBA")
    }
}
