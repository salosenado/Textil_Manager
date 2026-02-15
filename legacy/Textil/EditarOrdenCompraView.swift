//
//  EditarOrdenCompraView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftUI
import SwiftData

struct EditarOrdenCompraView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var orden: OrdenCompra

    // CATÁLOGOS
    @Query private var proveedores: [Proveedor]

    var body: some View {
        Form {

            // HEADER
            Section {
                fila("Orden", etiquetaOrden)
                fila(
                    "Fecha creación",
                    orden.fechaOrden.formatted(.dateTime.day().month(.abbreviated).year())
                )

                DatePicker(
                    "Fecha entrega",
                    selection: $orden.fechaEntrega,
                    displayedComponents: .date
                )
            }

            // PROVEEDOR
            Section("Proveedor") {
                Picker("Proveedor", selection: proveedorBinding) {
                    ForEach(proveedores.filter { $0.activo }) {
                        Text($0.nombre).tag($0.nombre)
                    }
                }

                if let plazo = orden.plazoDias {
                    cuadroGris("Plazo: \(plazo) días")
                }
            }

            // DETALLE (EDITABLE)
            Section("Detalle") {
                ForEach($orden.detalles) { $d in

                    VStack(alignment: .leading, spacing: 8) {

                        Text(d.modelo)
                            .fontWeight(.semibold)

                        HStack {
                            Text("Cantidad")
                            Spacer()
                            TextField(
                                "0",
                                value: $d.cantidad,
                                format: .number
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        }

                        HStack {
                            Text("Costo unitario")
                            Spacer()
                            Text("MX $")
                                .foregroundStyle(.secondary)
                            TextField(
                                "0.00",
                                value: $d.costoUnitario,
                                format: .number
                            )
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                        }

                        HStack {
                            Spacer()
                            Text(formato(d.subtotal))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(8)
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        context.delete(orden.detalles[i])
                    }
                    orden.detalles.remove(atOffsets: indexSet)
                }
            }

            Toggle("Aplicar IVA (16%)", isOn: $orden.aplicaIVA)

            // TOTALES
            Section("Totales") {
                filaMoneda("Subtotal", subtotal)
                filaMoneda("IVA", iva)
                filaMoneda("Total", total, bold: true)
            }

            // OBSERVACIONES
            Section("Observaciones") {
                TextEditor(text: $orden.observaciones)
                    .frame(minHeight: 80)
            }

            Button("Guardar cambios") {
                guardar()
            }
        }
        .navigationTitle("Editar orden")
    }

    // MARK: - COMPUTADOS

    var etiquetaOrden: String {
        switch orden.tipoCompra {
        case "servicio":
            return "SS-\(orden.numeroOC)"
        default:
            return "OC-\(orden.numeroOC)"
        }
    }

    var subtotal: Double {
        orden.detalles.reduce(0) { $0 + $1.subtotal }
    }

    var iva: Double {
        orden.aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    var proveedorBinding: Binding<String> {
        Binding(
            get: { orden.proveedor },
            set: { nuevo in
                orden.proveedor = nuevo
                if let p = proveedores.first(where: { $0.nombre == nuevo }) {
                    orden.plazoDias = p.plazoPagoDias
                }
            }
        )
    }

    // MARK: - ACCIONES

    func guardar() {
        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Error guardando edición:", error)
        }
    }

    // MARK: - UI HELPERS

    func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).foregroundStyle(.secondary)
        }
    }

    func filaMoneda(
        _ t: String,
        _ v: Double,
        bold: Bool = false
    ) -> some View {
        HStack {
            Text(t).fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(formato(v))
                .fontWeight(bold ? .bold : .regular)
        }
    }

    func cuadroGris(_ texto: String) -> some View {
        Text(texto)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func formato(_ v: Double) -> String {
        "MX $ " + String(format: "%.2f", v)
    }
}
