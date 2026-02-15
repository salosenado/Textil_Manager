//
//  AltaCostoMezclillaView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  AltaCostoMezclillaView.swift
//  Textil
//
//
//  AltaCostoMezclillaView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct AltaCostoMezclillaView: View {

    // MARK: - Entorno
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Catálogos REALES (SwiftData)
    @Query private var departamentos: [Departamento]
    @Query private var lineas: [Linea]
    @Query private var articulos: [Articulo]
    @Query private var modelosCatalogo: [Modelo]
    @Query private var tallas: [Talla]
    @Query private var telasCatalogo: [Tela]

    // MARK: - Selección (Strings)
    @State private var departamento = ""
    @State private var linea = ""
    @State private var articulo = ""
    @State private var modelo = ""
    @State private var talla = ""
    @State private var tela = ""

    // MARK: - Texto
    @State private var lavado = ""
    @State private var observaciones = ""

    // MARK: - Costos
    @State private var costoTela = ""
    @State private var consumoTela = ""
    @State private var costoPoquetin = ""
    @State private var consumoPoquetin = ""

    @State private var maquila = ""
    @State private var lavanderia = ""
    @State private var cierre = ""
    @State private var boton = ""
    @State private var remaches = ""
    @State private var etiquetas = ""
    @State private var flete = ""

    // MARK: - Helpers
    private func num(_ v: String) -> Double {
        Double(v.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var descripcionModelo: String {
        modelosCatalogo.first { $0.nombre == modelo }?.descripcion ?? ""
    }

    private var totalTela: Double {
        num(costoTela) * num(consumoTela)
    }

    private var totalPoquetin: Double {
        num(costoPoquetin) * num(consumoPoquetin)
    }

    private var totalProcesos: Double {
        num(maquila)
        + num(lavanderia)
        + num(cierre)
        + num(boton)
        + num(remaches)
        + num(etiquetas)
        + num(flete)
    }

    private var total: Double {
        totalTela + totalPoquetin + totalProcesos
    }

    private var totalConGastos: Double {
        total * 1.15
    }

    private var puedeGuardar: Bool {
        !departamento.isEmpty &&
        !linea.isEmpty &&
        !articulo.isEmpty &&
        !modelo.isEmpty &&
        !talla.isEmpty &&
        !tela.isEmpty
    }

    // MARK: - UI
    var body: some View {
        Form {

            // IDENTIFICACIÓN
            Section("Identificación") {

                Picker("Departamento", selection: $departamento) {
                    Text("Seleccionar").tag("")
                    ForEach(departamentos) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                Picker("Línea", selection: $linea) {
                    Text("Seleccionar").tag("")
                    ForEach(lineas) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                Picker("Artículo", selection: $articulo) {
                    Text("Seleccionar").tag("")
                    ForEach(articulos) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                Picker("Modelo", selection: $modelo) {
                    Text("Seleccionar").tag("")
                    ForEach(modelosCatalogo) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                if !descripcionModelo.isEmpty {
                    Text(descripcionModelo)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }

                Picker("Talla", selection: $talla) {
                    Text("Seleccionar").tag("")
                    ForEach(tallas) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                TextField("Lavado", text: $lavado)

                TextEditor(text: $observaciones)
                    .frame(height: 80)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }

            // TELA
            Section("Tela") {
                Picker("Tipo de tela", selection: $tela) {
                    Text("Seleccionar").tag("")
                    ForEach(telasCatalogo) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                campo("Costo Tela", $costoTela)
                campo("Consumo Tela", $consumoTela)
                fila("Total Tela", totalTela, bold: true)
            }

            // POQUETÍN
            Section("Poquetín") {
                campo("Costo Poquetín", $costoPoquetin)
                campo("Consumo Poquetín", $consumoPoquetin)
                fila("Total Poquetín", totalPoquetin, bold: true)
            }

            // PROCESOS
            Section("Procesos y Habilitación") {
                campo("Maquila", $maquila)
                campo("Lavandería", $lavanderia)
                campo("Cierre", $cierre)
                campo("Botón", $boton)
                campo("Remaches", $remaches)
                campo("Etiquetas", $etiquetas)
                campo("Flete y cajas", $flete)
            }

            // TOTALES
            Section("Totales") {
                fila("Tela", totalTela)
                fila("Poquetín", totalPoquetin)
                fila("Procesos", totalProcesos)
                fila("TOTAL", total, bold: true)
                fila("TOTAL CON GASTOS (15%)", totalConGastos, color: .green, bold: true)
            }

            Button("Guardar Costo Mezclilla") {
                guardar()
            }
            .disabled(!puedeGuardar)
        }
        .navigationTitle("Nuevo Costo Mezclilla")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Guardar
    private func guardar() {
        let costo = CostoMezclillaEntity(
            modelo: modelo,
            tela: tela,
            fecha: .now,
            costoTela: num(costoTela),
            consumoTela: num(consumoTela),
            costoPoquetin: num(costoPoquetin),
            consumoPoquetin: num(consumoPoquetin),
            maquila: num(maquila),
            lavanderia: num(lavanderia),
            cierre: num(cierre),
            boton: num(boton),
            remaches: num(remaches),
            etiquetas: num(etiquetas),
            fleteYCajas: num(flete)
        )


        context.insert(costo)
        try? context.save()
        dismiss()
    }

    // MARK: - UI Helpers
    private func campo(_ title: String, _ value: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("0.00", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }

    private func fila(
        _ title: String,
        _ value: Double,
        color: Color = .secondary,
        bold: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(value, format: .currency(code: "MXN"))
                .foregroundStyle(color)
                .fontWeight(bold ? .bold : .regular)
        }
    }
}
