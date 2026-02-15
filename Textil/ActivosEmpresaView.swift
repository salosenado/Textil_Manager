//
//  ActivosEmpresaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/10/26.
//
import SwiftUI
import SwiftData

struct ActivosEmpresaView: View {

    @Environment(\.modelContext) private var context

    @Query private var empresas: [Empresa]
    @Query private var activos: [ActivoEmpresa]

    @State private var empresaSeleccionada: Empresa? = nil
    @State private var mostrarNuevo = false

    @State private var activoEliminar: ActivoEmpresa?
    @State private var activoVenta: ActivoEmpresa?

    // MARK: - FILTRO
    var activosFiltrados: [ActivoEmpresa] {
        if let empresaSeleccionada {
            return activos.filter {
                $0.empresa == empresaSeleccionada
            }
        } else {
            return activos   // 🔥 muestra todos si está en "Seleccionar"
        }
    }

    // MARK: - TOTALES COMPRA
    var totalesCompraPorAnio: [(anio: Int, total: Double)] {
        let grouped = Dictionary(grouping: activosFiltrados) {
            Calendar.current.component(.year, from: $0.fechaCompra)
        }

        return grouped
            .map { (anio: $0.key,
                    total: $0.value.reduce(0) { $0 + $1.costoTotal }) }
            .sorted { $0.anio < $1.anio }
    }

    // MARK: - TOTALES VENTA
    var totalesVentaPorAnio: [(anio: Int, total: Double)] {
        let vendidos = activosFiltrados.filter { $0.vendido }

        let grouped = Dictionary(grouping: vendidos) {
            Calendar.current.component(.year, from: $0.fechaVenta ?? Date())
        }

        return grouped
            .map { (anio: $0.key,
                    total: $0.value.reduce(0) { $0 + ($1.precioVenta ?? 0) }) }
            .sorted { $0.anio < $1.anio }
    }

    // MARK: - ACTIVOS ACTUALES
    var totalGeneral: Double {
        activosFiltrados
            .filter { !$0.vendido }
            .reduce(0) { $0 + $1.costoTotal }
    }

    var body: some View {

        NavigationStack {

            VStack(spacing: 12) {

                header

                List {

                    if activosFiltrados.isEmpty {
                        ContentUnavailableView("Sin activos",
                                               systemImage: "tray")
                    }

                    else {

                        ForEach(activosFiltrados) { activo in

                            VStack(alignment: .leading, spacing: 6) {

                                HStack {
                                    Text(activo.articulo)
                                        .font(.headline)

                                    Spacer()

                                    if activo.vendido {
                                        Text("VENDIDO")
                                            .foregroundStyle(.red)
                                            .bold()
                                    }
                                }

                                Text("Fecha compra: \(activo.fechaCompra.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)

                                Text("Total compra: MX$ \(String(format: "%.2f", activo.costoTotal))")
                                    .bold()

                                if activo.vendido {
                                    Text("Precio venta: MX$ \(String(format: "%.2f", activo.precioVenta ?? 0))")

                                    Text("Utilidad: MX$ \(String(format: "%.2f", activo.utilidad))")
                                        .foregroundStyle(activo.utilidad >= 0 ? .green : .red)
                                        .bold()
                                }
                            }
                            .swipeActions {

                                // ELIMINAR
                                Button(role: .destructive) {
                                    activoEliminar = activo
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }

                                // VENDER
                                if !activo.vendido {
                                    Button {
                                        activoVenta = activo
                                    } label: {
                                        Label("Vender", systemImage: "dollarsign.circle")
                                    }
                                    .tint(.green)
                                }
                            }
                        }

                        totalesSection
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Activos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if empresaSeleccionada == nil {
                            empresaSeleccionada = empresas.first
                        }
                        mostrarNuevo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(empresas.isEmpty)
                }
            }
            .sheet(isPresented: $mostrarNuevo) {
                NuevoActivoView()
            }
        }
        .sheet(item: $activoVenta) { activo in
            VentaActivoView(activo: activo)
        }
        .sheet(item: $activoEliminar) { activo in
            EliminarActivoView(activo: activo)
        }
    }

    // MARK: - HEADER
    var header: some View {
        HStack {
            Text("Empresa")
                .font(.headline)

            Spacer()

            Picker("Empresa", selection: $empresaSeleccionada) {
                Text("Seleccionar").tag(Empresa?.none)

                ForEach(empresas) { empresa in
                    Text(empresa.nombre)
                        .tag(Optional(empresa))
                }
            }
            .pickerStyle(.menu)

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - TOTALES
    var totalesSection: some View {
        Group {

            if !totalesCompraPorAnio.isEmpty {
                Section("Totales por año de compra") {
                    ForEach(totalesCompraPorAnio, id: \.anio) { item in
                        HStack {
                            Text(String(item.anio))
                            Spacer()
                            Text("MX$ \(String(format: "%.2f", item.total))")
                                .bold()
                        }
                    }
                }
            }

            if !totalesVentaPorAnio.isEmpty {
                Section("Totales por año de venta") {
                    ForEach(totalesVentaPorAnio, id: \.anio) { item in
                        HStack {
                            Text(String(item.anio))
                            Spacer()
                            Text("MX$ \(String(format: "%.2f", item.total))")
                                .foregroundStyle(.green)
                                .bold()
                        }
                    }
                }
            }

            if totalGeneral > 0 {
                Section {
                    HStack {
                        Text("Total activos actuales")
                            .font(.headline)
                        Spacer()
                        Text("MX$ \(String(format: "%.2f", totalGeneral))")
                            .foregroundStyle(.green)
                            .font(.headline)
                    }
                }
            }
        }
    }
}
