//
//  CosteosListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CosteosListView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct CosteosListView: View {

    // MARK: - Queries
    @Query(sort: \CostoGeneralEntity.fecha, order: .reverse)
    private var costosGenerales: [CostoGeneralEntity]

    @Query(sort: \CostoMezclillaEntity.fecha, order: .reverse)
    private var costosMezclilla: [CostoMezclillaEntity]

    // MARK: - Filtros
    @State private var searchText = ""
    @State private var tipoSeleccionado: TipoFiltro = .todos
    @State private var departamentoSeleccionado = "Todos"
    @State private var lineaSeleccionada = "Todas"

    // MARK: - Tipos
    enum TipoCosteo: String {
        case general = "General"
        case mezclilla = "Mezclilla"
    }

    enum TipoFiltro: String, CaseIterable, Identifiable {
        case todos = "Todos"
        case general = "General"
        case mezclilla = "Mezclilla"
        var id: String { rawValue }
    }

    struct ResumenModelo: Identifiable {
        let id = UUID()
        let modelo: String
        let ultimoMonto: Double
        let fecha: Date
        let tipos: Set<TipoCosteo>
    }

    // MARK: - Unificación (SIN CAMBIOS)
    private var resumenes: [ResumenModelo] {

        var dict: [String: ResumenModelo] = [:]

        for c in costosGenerales {
            let monto = c.totalConGastos
            if let e = dict[c.modelo] {
                dict[c.modelo] = ResumenModelo(
                    modelo: c.modelo,
                    ultimoMonto: c.fecha >= e.fecha ? monto : e.ultimoMonto,
                    fecha: max(e.fecha, c.fecha),
                    tipos: e.tipos.union([.general])
                )
            } else {
                dict[c.modelo] = ResumenModelo(
                    modelo: c.modelo,
                    ultimoMonto: monto,
                    fecha: c.fecha,
                    tipos: [.general]
                )
            }
        }

        for c in costosMezclilla {
            let monto = c.totalConGastos
            if let e = dict[c.modelo] {
                dict[c.modelo] = ResumenModelo(
                    modelo: c.modelo,
                    ultimoMonto: c.fecha >= e.fecha ? monto : e.ultimoMonto,
                    fecha: max(e.fecha, c.fecha),
                    tipos: e.tipos.union([.mezclilla])
                )
            } else {
                dict[c.modelo] = ResumenModelo(
                    modelo: c.modelo,
                    ultimoMonto: monto,
                    fecha: c.fecha,
                    tipos: [.mezclilla]
                )
            }
        }

        return dict.values.sorted { $0.modelo < $1.modelo }
    }

    // MARK: - Filtro aplicado (FUNCIONAL)
    private var resumenesFiltrados: [ResumenModelo] {
        resumenes.filter { r in
            let searchOK =
                searchText.isEmpty ||
                r.modelo.localizedCaseInsensitiveContains(searchText)

            let tipoOK =
                tipoSeleccionado == .todos ||
                (tipoSeleccionado == .general && r.tipos.contains(.general)) ||
                (tipoSeleccionado == .mezclilla && r.tipos.contains(.mezclilla))

            let deptoOK = departamentoSeleccionado == "Todos"
            let lineaOK = lineaSeleccionada == "Todas"

            return searchOK && tipoOK && deptoOK && lineaOK
        }
    }

    // MARK: - UI
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 🔍 BUSCADOR FLOTANTE
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)

                        TextField("Buscar modelo", text: $searchText)
                    }
                    .padding(14)
                    .background(Color(.systemBackground))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.horizontal)

                    // 🔽 FILTROS (igual a la imagen)
                    VStack(alignment: .leading, spacing: 8) {

                        Text("Filtros")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {

                            // TIPO
                            Menu {
                                Picker("", selection: $tipoSeleccionado) {
                                    ForEach(TipoFiltro.allCases) {
                                        Text($0.rawValue).tag($0)
                                    }
                                }
                            } label: {
                                FilaFiltro(
                                    titulo: "Tipo",
                                    valor: tipoSeleccionado.rawValue
                                )
                            }

                            Divider()

                            // DEPARTAMENTO
                            Menu {
                                Picker("", selection: $departamentoSeleccionado) {
                                    Text("Todos").tag("Todos")
                                }
                            } label: {
                                FilaFiltro(
                                    titulo: "Departamento",
                                    valor: departamentoSeleccionado
                                )
                            }

                            Divider()

                            // LÍNEA
                            Menu {
                                Picker("", selection: $lineaSeleccionada) {
                                    Text("Todas").tag("Todas")
                                }
                            } label: {
                                FilaFiltro(
                                    titulo: "Línea",
                                    valor: lineaSeleccionada
                                )
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    // 📋 TARJETAS (LAYOUT ORIGINAL)
                    ForEach(resumenesFiltrados) { r in
                        NavigationLink {
                            CosteoHistorialView(modelo: r.modelo)
                        } label: {

                            HStack(alignment: .top) {

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Modelo: \(r.modelo)")
                                        .font(.headline)

                                    Text(
                                        "Última fecha: \(r.fecha.formatted(.dateTime.day().month(.abbreviated).year()))"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    Text(
                                        r.tipos
                                            .map { $0.rawValue }
                                            .sorted()
                                            .joined(separator: " · ")
                                    )
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(
                                    r.ultimoMonto,
                                    format: .currency(code: "MXN")
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Costos")
        }
    }
}

//
// MARK: - Fila de filtro (visual)
//

struct FilaFiltro: View {

    let titulo: String
    let valor: String

    var body: some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .contentShape(Rectangle())
    }
}
