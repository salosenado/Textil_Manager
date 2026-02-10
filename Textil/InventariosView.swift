//
//  InventariosView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//
//
//
//  InventariosView.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//

import SwiftUI
import SwiftData

// 📦 SOLO PARA UI
struct InventarioItem: Identifiable {
    let id = UUID()
    let modelo: String
    let cantidad: Int
    let ultimaFechaRecibo: Date?
    let ultimaFechaVenta: Date?
}

struct InventariosView: View {

    @Environment(\.modelContext) private var context

    // 🔗 FUENTES REALES
    @Query private var recepcionesCompra: [ReciboCompraDetalle]
    @Query private var recibosProduccion: [ReciboProduccion]
    @Query private var ventas: [VentaClienteDetalle]
    @Query private var salidas: [SalidaInsumoDetalle]

    // 🔗 CATÁLOGO
    @Query private var catalogoModelos: [Modelo]
    
    @Query private var reingresosDetalle: [ReingresoDetalle]


    // 🔄 FORZAR REFRESH EN TABVIEW
    @State private var refreshID = UUID()

    // FILTROS
    @State private var textoBusqueda = ""
    @State private var filtroModelo = "Todos"

    // =====================================================
    // INVENTARIO CONSOLIDADO (MODELOS)
    // =====================================================
    var inventarioBase: [InventarioItem] {

        var nombres: Set<String> = []

        // MODELOS (histórico)
        nombres.formUnion(
            recepcionesCompra
                .filter { $0.fechaEliminacion == nil }
                .map { $0.modelo }
        )

        nombres.formUnion(
            recibosProduccion.flatMap {
                $0.detalles
                    .filter { $0.fechaEliminacion == nil }
                    .map { $0.modelo }
            }
        )

        nombres.formUnion(
            ventas
                .filter { $0.fechaEliminacion == nil }
                .map { $0.modeloNombre }
        )

        nombres.formUnion(
            salidas.compactMap { $0.modeloNombre }
        )

        // 🔵 SERVICIOS DESDE REINGRESOS
        nombres.formUnion(
            reingresosDetalle
                .filter { $0.esServicio }
                .compactMap { $0.nombreServicio }
        )

        // 🔄 CONSTRUCCIÓN FINAL
        return nombres.sorted().map { nombre in

            let resultadoBase = InventarioService
                .existenciaActual(
                    modeloNombre: nombre,
                    context: context
                )

            let sumaReingresosProducto = reingresosDetalle
                .filter {
                    !$0.esServicio &&
                    $0.modelo?.nombre == nombre
                }
                .map { $0.cantidad }
                .reduce(0, +)

            let sumaReingresosServicio = reingresosDetalle
                .filter {
                    $0.esServicio &&
                    $0.nombreServicio == nombre
                }
                .map { $0.cantidad }
                .reduce(0, +)

            return InventarioItem(
                modelo: nombre,
                cantidad: resultadoBase.cantidad +
                          sumaReingresosProducto +
                          sumaReingresosServicio,
                ultimaFechaRecibo: resultadoBase.ultimaFechaRecibo,
                ultimaFechaVenta: resultadoBase.ultimaFechaVenta
            )
        }
    }

    // =====================================================
    // FILTRADO
    // =====================================================
    var inventarioFiltrado: [InventarioItem] {
        inventarioBase.filter { item in
            if !textoBusqueda.isEmpty &&
                !item.modelo.lowercased().contains(textoBusqueda.lowercased()) {
                return false
            }
            if filtroModelo != "Todos" && item.modelo != filtroModelo {
                return false
            }
            return true
        }
    }

    var modelosDisponibles: [String] {
        ["Todos"] + inventarioBase.map { $0.modelo }.sorted()
    }

    // =====================================================
    // BODY
    // =====================================================
    var body: some View {
        VStack(spacing: 0) {

            buscadorFlotante
            filtroModeloLinea

            List {
                ForEach(inventarioFiltrado) { item in
                    NavigationLink {
                        InventarioModeloMovimientosView(
                            modeloNombre: item.modelo
                        )
                    } label: {
                        tarjetaInventario(item)
                    }
                }

                if inventarioFiltrado.isEmpty {
                    ContentUnavailableView(
                        "Sin resultados",
                        systemImage: "tray",
                        description: Text("No hay inventario con el filtro actual.")
                    )
                }
            }
        }
        .id(refreshID)
        .onAppear {
            refreshID = UUID()
        }
        .onChange(of: salidas.count) { _ in
            // 🔥 cuando se registra una salida
            refreshID = UUID()
        }
        .navigationTitle("Inventarios")
    }

    // =====================================================
    // UI
    // =====================================================
    var buscadorFlotante: some View {
        TextField("Buscar modelo", text: $textoBusqueda)
            .textFieldStyle(.roundedBorder)
            .padding()
            .background(Color(.systemBackground))
    }

    var filtroModeloLinea: some View {
        VStack(spacing: 0) {

            HStack {
                Text("Modelo")
                Spacer()
                Picker("", selection: $filtroModelo) {
                    ForEach(modelosDisponibles, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()

            Divider()

            Button("Limpiar filtros", action: limpiarFiltros)
                .font(.caption.bold())
                .padding()

            Divider()
        }
        .background(Color(.systemBackground))
    }

    func limpiarFiltros() {
        textoBusqueda = ""
        filtroModelo = "Todos"
    }

    // =====================================================
    // TARJETA
    // =====================================================
    func tarjetaInventario(_ item: InventarioItem) -> some View {

        let estado = estadoMovimiento(
            ultimaFecha: max(
                item.ultimaFechaRecibo ?? .distantPast,
                item.ultimaFechaVenta ?? .distantPast
            )
        )

        return HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 6) {

                Text(
                    esServicio(item.modelo)
                    ? "Servicio: \(item.modelo)"
                    : "Modelo: \(item.modelo)"
                )
                .font(.headline)

                Text("Cantidad: \(item.cantidad)")
                    .font(.subheadline)

                Text("Descripción: \(descripcionModelo(item.modelo))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(
                    "Última fecha de recibo: " +
                    (item.ultimaFechaRecibo?
                        .formatted(date: .abbreviated, time: .omitted)
                     ?? "—")
                )
                .font(.caption)

                Text(
                    "Última fecha de venta: " +
                    (item.ultimaFechaVenta?
                        .formatted(date: .abbreviated, time: .omitted)
                     ?? "—")
                )
                .font(.caption)
            }

            Spacer()

            VStack(spacing: 6) {

                Circle()
                    .fill(estado.color)
                    .frame(width: 16, height: 16)

                Text(estado.texto)
                    .font(.caption.bold())
                    .foregroundColor(estado.color)

                Text("\(estado.dias) días")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // =====================================================
    // HELPERS
    // =====================================================
    func descripcionModelo(_ nombreModelo: String) -> String {
        catalogoModelos.first { $0.nombre == nombreModelo }?.descripcion ?? "—"
    }

    func esServicio(_ nombre: String) -> Bool {
        reingresosDetalle.contains {
            $0.esServicio && $0.nombreServicio == nombre
        }
    }
    
    func estadoMovimiento(ultimaFecha: Date?) -> (texto: String, color: Color, dias: Int) {

        guard let fecha = ultimaFecha else {
            return ("Sin movimiento", .red, 999)
        }

        let dias = Calendar.current.dateComponents(
            [.day],
            from: fecha,
            to: Date()
        ).day ?? 999

        if dias >= 120 {
            return ("Sin movimiento", .red, dias)
        }

        if dias >= 31 {
            return ("Poco movimiento", .yellow, dias)
        }

        return ("Activo", .green, dias)
    }
}

#Preview {
    NavigationStack {
        InventariosView()
    }
}
