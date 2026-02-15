//
//  AltaCostoGeneralView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//
//  AltaCostoGeneralView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

struct AltaCostoGeneralView: View {

    // MARK: - Entorno
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Catálogos
    @Query private var departamentos: [Departamento]
    @Query private var lineas: [Linea]
    @Query private var articulos: [Articulo]
    @Query private var modelos: [Modelo]
    @Query private var tallasCatalogo: [Talla]
    @Query private var telasCatalogo: [Tela]

    // MARK: - Selección
    @State private var departamento: Departamento?
    @State private var linea: Linea?
    @State private var articulo: Articulo?
    @State private var modelo: Modelo?
    @State private var talla: Talla?

    // MARK: - Observaciones
    @State private var observaciones: String = ""

    // MARK: - Dinámicos
    @State private var telas: [CostoGeneralTela] = []
    @State private var insumos: [CostoGeneralInsumo] = []

    // MARK: - Insumos fijos
    private let insumosExcel: [String] = [
        "ESTAMPADO", "BORDADO", "MAQUILA", "BROCHE", "ELÁSTICO",
        "GANCHO", "BOTÓN", "CIERRE", "TALLERO",
        "ETIQ. TELA", "AHORC", "LINO", "MOÑO"
    ]

    // MARK: - UI
    var body: some View {
        Form {

            // MARK: - IDENTIFICACIÓN
            Section("Identificación") {

                Picker("Departamento", selection: $departamento) {
                    Text("Seleccionar").tag(Departamento?.none)
                    ForEach(departamentos) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Línea", selection: $linea) {
                    Text("Seleccionar").tag(Linea?.none)
                    ForEach(lineas) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Artículo", selection: $articulo) {
                    Text("Seleccionar").tag(Articulo?.none)
                    ForEach(articulos) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Modelo", selection: $modelo) {
                    Text("Seleccionar").tag(Modelo?.none)
                    ForEach(modelos) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                // 👇 DESCRIPCIÓN DEL MODELO (RECUADRO GRIS)
                if let descripcion = modelo?.descripcion, !descripcion.isEmpty {
                    Text(descripcion)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Picker("Talla", selection: $talla) {
                    Text("Seleccionar").tag(Talla?.none)
                    ForEach(tallasCatalogo) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }
            }

            // MARK: - OBSERVACIONES
            Section("Observaciones") {
                TextEditor(text: $observaciones)
                    .frame(minHeight: 80)
                    .padding(6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // MARK: - TELAS
            Section("Telas") {

                ForEach(telas) { telaCosto in
                    VStack(alignment: .leading, spacing: 8) {

                        Picker(
                            "Tela",
                            selection: Binding<Tela?>(
                                get: {
                                    telasCatalogo.first { $0.nombre == telaCosto.nombre }
                                },
                                set: { nuevaTela in
                                    telaCosto.nombre = nuevaTela?.nombre ?? ""
                                }
                            )
                        ) {
                            Text("Seleccionar").tag(Tela?.none)
                            ForEach(telasCatalogo) {
                                Text($0.nombre).tag(Optional($0))
                            }
                        }

                        campoNumero("Consumo", bindingTela(telaCosto).consumo)
                        campoMoneda("Precio", bindingTela(telaCosto).precioUnitario)
                        filaResultado("Total", telaCosto.total)
                    }
                }
                .onDelete(perform: eliminarTela)

                Button("➕ Agregar Tela") {
                    telas.append(
                        CostoGeneralTela(
                            nombre: "",
                            consumo: 0,
                            precioUnitario: 0
                        )
                    )
                }
            }

            // MARK: - INSUMOS
            Section("Insumos / Procesos") {

                ForEach(insumos) { insumo in
                    VStack(alignment: .leading, spacing: 8) {

                        Picker("Insumo", selection: bindingInsumo(insumo).nombre) {
                            ForEach(insumosExcel, id: \.self) {
                                Text($0)
                            }
                        }

                        campoNumero("Cantidad", bindingInsumo(insumo).cantidad)
                        campoMoneda("Costo", bindingInsumo(insumo).costoUnitario)
                        filaResultado("Total", insumo.total)
                    }
                }
                .onDelete(perform: eliminarInsumo)

                Button("➕ Agregar Insumo") {
                    insumos.append(
                        CostoGeneralInsumo(
                            nombre: insumosExcel.first ?? "",
                            cantidad: 0,
                            costoUnitario: 0
                        )
                    )
                }
            }

            // MARK: - TOTALES
            Section("Totales") {
                filaResultado("Total Telas", totalTelas)
                filaResultado("Total Insumos", totalInsumos)
                Divider()
                filaResultado("Total", total, bold: true)
                filaResultado(
                    "Total con gastos (15%)",
                    totalConGastos,
                    bold: true,
                    color: .green
                )
            }

            // MARK: - GUARDAR
            Button("Guardar Costo General") {
                guardar()
            }
            .disabled(modelo == nil)
        }
        .navigationTitle("Nuevo Costo General")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Cálculos
    private var totalTelas: Double {
        telas.reduce(0) { $0 + $1.total }
    }

    private var totalInsumos: Double {
        insumos.reduce(0) { $0 + $1.total }
    }

    private var total: Double {
        totalTelas + totalInsumos
    }

    private var totalConGastos: Double {
        total * 1.15
    }

    // MARK: - Guardar
    private func guardar() {
        guard let modelo else { return }

        let costo = CostoGeneralEntity(
            departamento: departamento,
            linea: linea,
            modelo: modelo.nombre,
            tallas: talla?.nombre ?? "",
            descripcion: observaciones.isEmpty ? modelo.descripcion : observaciones
        )

        // 🔴 RELACIONAR CORRECTAMENTE
        telas.forEach {
            $0.costoGeneral = costo
            context.insert($0)
        }

        insumos.forEach {
            $0.costoGeneral = costo
            context.insert($0)
        }

        costo.telas = telas
        costo.insumos = insumos

        context.insert(costo)
        try? context.save()
        dismiss()
    }

    // MARK: - Helpers
    private func eliminarTela(at offsets: IndexSet) {
        telas.remove(atOffsets: offsets)
    }

    private func eliminarInsumo(at offsets: IndexSet) {
        insumos.remove(atOffsets: offsets)
    }

    private func bindingTela(_ tela: CostoGeneralTela) -> Binding<CostoGeneralTela> {
        let index = telas.firstIndex { $0.id == tela.id }!
        return $telas[index]
    }

    private func bindingInsumo(_ insumo: CostoGeneralInsumo) -> Binding<CostoGeneralInsumo> {
        let index = insumos.firstIndex { $0.id == insumo.id }!
        return $insumos[index]
    }

    private func campoNumero(_ titulo: String, _ valor: Binding<Double>) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            TextField(
                "",
                text: Binding(
                    get: { valor.wrappedValue == 0 ? "" : String(valor.wrappedValue) },
                    set: { valor.wrappedValue = Double($0) ?? 0 }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 90)
        }
    }

    private func campoMoneda(_ titulo: String, _ valor: Binding<Double>) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text("$")
            TextField(
                "",
                text: Binding(
                    get: { valor.wrappedValue == 0 ? "" : String(valor.wrappedValue) },
                    set: { valor.wrappedValue = Double($0) ?? 0 }
                )
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 90)
        }
    }

    private func filaResultado(
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
