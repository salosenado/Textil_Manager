//
//  DetalleCostoGeneralView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  DetalleCostoGeneralView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

struct DetalleCostoGeneralView: View {

    let costo: CostoGeneralEntity

    var body: some View {
        Form {

            // MARK: - IDENTIFICACIÓN
            Section("Identificación") {
                fila("Modelo", costo.modelo)
                fila("Departamento", costo.departamento?.nombre ?? "-")
                fila("Línea", costo.linea?.nombre ?? "-")
                fila("Talla", costo.tallas)
            }

            // MARK: - DESCRIPCIÓN
            if !costo.descripcion.isEmpty {
                Section("Descripción") {
                    Text(costo.descripcion)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - TELAS
            Section("Telas") {
                ForEach(costo.telas) { tela in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tela.nombre)
                            .font(.headline)

                        fila("Consumo", tela.consumo)
                        filaMoneda("Precio", tela.precioUnitario)
                        filaMoneda("Total", tela.total, bold: true)
                    }
                }
            }

            // MARK: - INSUMOS / PROCESOS
            Section("Insumos / Procesos") {
                ForEach(costo.insumos) { insumo in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insumo.nombre)
                            .font(.headline)

                        fila("Cantidad", insumo.cantidad)
                        filaMoneda("Costo", insumo.costoUnitario)
                        filaMoneda("Total", insumo.total, bold: true)
                    }
                }
            }

            // MARK: - TOTALES
            Section("Totales") {
                filaMoneda("Total Telas", costo.totalTelas)
                filaMoneda("Total Insumos", costo.totalInsumos)

                Divider()

                filaMoneda("TOTAL", costo.total, bold: true)
                filaMoneda(
                    "TOTAL CON GASTOS (15%)",
                    costo.totalConGastos,
                    bold: true,
                    color: .green
                )
            }
        }
        .navigationTitle("Detalle Costo")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers
    private func fila(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .foregroundStyle(.secondary)
        }
    }

    private func fila(_ titulo: String, _ valor: Double) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor, format: .number)
                .foregroundStyle(.secondary)
        }
    }

    private func filaMoneda(
        _ titulo: String,
        _ valor: Double,
        bold: Bool = false,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(titulo)
                .fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(valor, format: .currency(code: "MXN"))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(color)
        }
    }
}
