//
//  NuevoMovimientoBancoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//

import SwiftUI
import SwiftData

struct NuevoMovimientoBancoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var empresas: [Empresa]
    @Query private var clientes: [Cliente]
    @Query private var proveedores: [Proveedor]

    var movimientoEditar: MovimientoBanco?

    @State private var tipo: MovimientoBanco.Tipo = .ingreso
    @State private var fecha = Date()
    @State private var monto = ""
    @State private var empresaSeleccionada: Empresa?
    @State private var clienteSeleccionado: Cliente?
    @State private var proveedorSeleccionado: Proveedor?
    @State private var descripcion = ""

    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.groupingSeparator = ","
        return f
    }()

    var montoDouble: Double {
        Double(monto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var body: some View {

        NavigationStack {
            Form {

                Picker("Tipo", selection: $tipo) {
                    Text("Ingreso").tag(MovimientoBanco.Tipo.ingreso)
                    Text("Egreso").tag(MovimientoBanco.Tipo.egreso)
                }
                .pickerStyle(.segmented)

                DatePicker("Fecha", selection: $fecha, displayedComponents: .date)

                HStack {
                    Text("MX$")
                    TextField("0.00", text: $monto)
                        .keyboardType(.decimalPad)
                        .onChange(of: monto) { _, newValue in
                            formatInput(newValue)
                        }
                }

                Picker("Empresa", selection: $empresaSeleccionada) {
                    Text("Seleccionar").tag(Empresa?.none)
                    ForEach(empresas) { empresa in
                        Text(empresa.nombre)
                            .tag(Optional(empresa))
                    }
                }

                if tipo == .ingreso {
                    Picker("Cliente", selection: $clienteSeleccionado) {
                        Text("Seleccionar").tag(Cliente?.none)
                        ForEach(clientes) { cliente in
                            Text(cliente.nombreComercial)
                                .tag(Optional(cliente))
                        }
                    }
                } else {
                    Picker("Proveedor", selection: $proveedorSeleccionado) {
                        Text("Seleccionar").tag(Proveedor?.none)
                        ForEach(proveedores) { proveedor in
                            Text(proveedor.nombre)
                                .tag(Optional(proveedor))
                        }
                    }
                }

                TextField("Descripción", text: $descripcion)
            }
            .navigationTitle("Movimiento Banco")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardar()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }

    private func formatInput(_ value: String) {
        let limpio = value
            .replacingOccurrences(of: ",", with: "")
            .filter { "0123456789.".contains($0) }

        if let number = Double(limpio) {
            monto = formatter.string(from: NSNumber(value: number)) ?? ""
        } else {
            monto = ""
        }
    }

    private func guardar() {

        if let movimientoEditar {
            movimientoEditar.tipo = tipo
            movimientoEditar.fecha = fecha
            movimientoEditar.monto = montoDouble
            movimientoEditar.empresa = empresaSeleccionada
            movimientoEditar.cliente = clienteSeleccionado
            movimientoEditar.proveedor = proveedorSeleccionado
            movimientoEditar.descripcion = descripcion
        } else {
            let nuevo = MovimientoBanco(
                tipo: tipo,
                fecha: fecha,
                monto: montoDouble,
                empresa: empresaSeleccionada,
                cliente: clienteSeleccionado,
                proveedor: proveedorSeleccionado,
                descripcion: descripcion
            )
            context.insert(nuevo)
        }

        dismiss()
    }
}
