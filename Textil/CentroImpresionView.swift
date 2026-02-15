//
//  CentroImpresionView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//
//
//  CentroImpresionView.swift
//  Textil
//
//
//  CentroImpresionView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CentroImpresionView: View {

    // =========================
    // DATA
    // =========================

    @Query(sort: \Produccion.fechaOrdenMaquila, order: .reverse)
    private var producciones: [Produccion]

    
    @Query(sort: \OrdenCompra.fechaOrden, order: .reverse)
    private var ordenesCompra: [OrdenCompra]

    // =========================
    // FILTROS
    // =========================

    @State private var buscarTexto = ""
    @State private var proveedorFiltro = "Todos"
    @State private var maquileroFiltro = "Todos"

    @State private var fechaDesde =
        Calendar.current.date(from: DateComponents(year: 2020)) ?? Date()

    @State private var fechaHasta = Date()

    // =========================
    // OPCIONES DINÁMICAS
    // =========================

    var proveedoresDisponibles: [String] {
        let lista = Set(ordenesCompra.map { $0.proveedor })
        return ["Todos"] + lista.sorted()
    }

    var maquilerosDisponibles: [String] {
        let lista = Set(producciones.map { $0.maquilero }.filter { !$0.isEmpty })
        return ["Todos"] + lista.sorted()
    }

    // =========================
    // BODY
    // =========================

    var body: some View {

        ScrollView {

            VStack(spacing: 28) {

                filtrosView

                // PRODUCCIÓN
                Text("Órdenes de Producción")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(produccionesFiltradas) { p in
                    NavigationLink {
                        DetalleCentroImpresionView(produccion: p, ordenCompra: nil)
                    } label: {
                        tarjetaProduccion(p)
                    }
                    .buttonStyle(.plain)
                }

                // COMPRAS
                Text("Órdenes de Compra")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(ordenesFiltradas) { orden in
                    NavigationLink {
                        DetalleCentroImpresionView(produccion: nil, ordenCompra: orden)
                    } label: {
                        tarjetaCompra(orden)
                    }
                    .buttonStyle(.plain)
                }

                Color.clear.frame(height: 60)
            }
            .padding()
        }
        .navigationTitle("Centro Impresión")
    }
}

//////////////////////////////////////////////////////////
// MARK: - FILTROS UI
//////////////////////////////////////////////////////////

extension CentroImpresionView {

    var filtrosView: some View {

        VStack(spacing: 14) {

            TextField("Buscar folio, cliente, modelo...", text: $buscarTexto)
                .textFieldStyle(.roundedBorder)

            VStack(spacing: 0) {

                filtroLinea("Proveedor", $proveedorFiltro, proveedoresDisponibles)
                filtroLinea("Maquilero", $maquileroFiltro, maquilerosDisponibles)

                HStack {
                    Text("Desde")
                    Spacer()
                    DatePicker("", selection: $fechaDesde, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding(.vertical, 6)

                Divider()

                HStack {
                    Text("Hasta")
                    Spacer()
                    DatePicker("", selection: $fechaHasta, displayedComponents: .date)
                        .labelsHidden()
                }
                .padding(.vertical, 6)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(22)
        }
    }

    func filtroLinea(
        _ titulo: String,
        _ seleccion: Binding<String>,
        _ opciones: [String]
    ) -> some View {

        VStack(spacing: 0) {

            HStack {
                Text(titulo)
                Spacer()

                Picker("", selection: seleccion) {
                    ForEach(opciones, id: \.self) {
                        Text($0)
                            .foregroundColor(.primary)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
            .padding(.vertical, 6)

            Divider()
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - FILTRADO
//////////////////////////////////////////////////////////

extension CentroImpresionView {

    var produccionesFiltradas: [Produccion] {

        producciones.filter { p in

            guard !p.cancelada else { return false }

            if maquileroFiltro != "Todos",
               p.maquilero != maquileroFiltro {
                return false
            }

            if let fecha = p.fechaOrdenMaquila {
                if fecha < fechaDesde || fecha > fechaHasta {
                    return false
                }
            }

            if !buscarTexto.isEmpty {
                let texto = buscarTexto.lowercased()

                return
                    (p.detalle?.orden?.cliente.lowercased().contains(texto) ?? false) ||
                    (p.detalle?.modelo.lowercased().contains(texto) ?? false) ||
                    (p.ordenMaquila?.lowercased().contains(texto) ?? false)
            }

            return true
        }
    }
    
    struct RegistroLocalPreview: Codable {
        var empresa: String
        var responsable: String
        var proveedor: String
        var firmaResponsable: Data?
        var firmaProveedor: Data?
    }

    var ordenesFiltradas: [OrdenCompra] {

        ordenesCompra.filter { orden in

            guard !orden.cancelada else { return false }

            if proveedorFiltro != "Todos",
               orden.proveedor != proveedorFiltro {
                return false
            }

            if orden.fechaOrden < fechaDesde ||
               orden.fechaOrden > fechaHasta {
                return false
            }

            if !buscarTexto.isEmpty {

                let texto = buscarTexto.lowercased()

                return
                    orden.folio.lowercased().contains(texto) ||
                    orden.proveedor.lowercased().contains(texto) ||
                    orden.detalles.contains {
                        $0.modelo.lowercased().contains(texto)
                    }
            }

            return true
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - TARJETAS
//////////////////////////////////////////////////////////

extension CentroImpresionView {

    // PRODUCCIÓN
    func tarjetaProduccion(_ p: Produccion) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("PRODUCCIÓN")
                .font(.caption.bold())
                .foregroundStyle(.blue)

            Text("Orden maquila: \(p.ordenMaquila ?? "Sin generar")")
                .font(.headline)

            Text("Cliente: \(p.detalle?.orden?.cliente ?? "-")")
            Text("Modelo: \(p.detalle?.modelo ?? "-")")
            Text("Maquilero: \(p.maquilero.isEmpty ? "-" : p.maquilero)")
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 🔥 FORZAMOS IZQUIERDA
        .padding()
        .background(Color.blue.opacity(0.08))
        .cornerRadius(24)
    }

    // COMPRA
    func tarjetaCompra(_ orden: OrdenCompra) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(tipoTexto(orden))
                .font(.caption.bold())
                .foregroundStyle(colorTipo(orden))

            Text("Folio: \(orden.folio)")
                .font(.headline)

            Text("Proveedor: \(orden.proveedor)")
            Text("Fecha: \(orden.fechaOrden.formatted(.dateTime.day().month(.abbreviated).year()))")

            Text("Modelos:")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(orden.detalles.prefix(3)) { d in
                Text("- \(d.modelo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 🔥 FORZAMOS IZQUIERDA
        .padding()
        .background(colorTipo(orden).opacity(0.08))
        .cornerRadius(24)
    }


    func tipoTexto(_ orden: OrdenCompra) -> String {
        switch orden.tipoCompra.lowercased() {
        case "insumo": return "COMPRA INSUMO"
        case "servicio": return "COMPRA SERVICIO"
        case "cliente": return "COMPRA CLIENTE"
        default: return "COMPRA"
        }
    }

    func colorTipo(_ orden: OrdenCompra) -> Color {
        switch orden.tipoCompra.lowercased() {
        case "insumo": return .blue
        case "servicio": return .orange
        case "cliente": return .purple
        default: return .gray
        }
    }
}
