//
//  AltaCompraClienteView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//


import SwiftUI
import SwiftData

struct AltaCompraClienteView: View {

        @Environment(\.modelContext) private var context
        @Environment(\.dismiss) private var dismiss

        // CATÁLOGOS
        @Query private var proveedores: [Proveedor]
        @Query private var articulos: [Articulo]
        @Query private var modelos: [Modelo]

        // HEADER
        @State private var numeroOC: Int = 0
        @State private var fechaEntrega: Date = Date()

        @State private var proveedor: Proveedor?

        // DETALLE ACTUAL
        @State private var articulo: Articulo?
        @State private var modelo: Modelo?
        @State private var cantidadTexto = ""
        @State private var costoTexto = ""

        // LISTA
        @State private var detalles: [OrdenCompraDetalle] = []

        @State private var aplicaIVA = false
        @State private var observaciones = ""

        var body: some View {
            Form {

                // HEADER
                Section {
                    fila("Orden de compra", "OC00-\(numeroOC)")
                    fila(
                        "Fecha orden",
                        Date().formatted(.dateTime.day().month().year())
                    )
                    DatePicker(
                        "Fecha entrega",
                        selection: $fechaEntrega,
                        displayedComponents: .date
                    )
                }

                // PROVEEDOR
                Section("Proveedor") {
                    Picker("Proveedor", selection: $proveedor) {
                        Text("Seleccionar").tag(Proveedor?.none)
                        ForEach(proveedores.filter { $0.activo }) {
                            Text($0.nombre).tag(Optional($0))
                        }
                    }

                    if let plazo = proveedor?.plazoPagoDias {
                        Text("Plazo: \(plazo) días")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }

                // DETALLE
                Section("Detalle") {
                    Picker("Artículo", selection: $articulo) {
                        Text("Seleccionar").tag(Articulo?.none)
                        ForEach(articulos.filter { $0.activo }) {
                            Text($0.nombre).tag(Optional($0))
                        }
                    }

                    Picker("Modelo", selection: $modelo) {
                        Text("Seleccionar").tag(Modelo?.none)
                        ForEach(modelos) {
                            Text($0.nombre).tag(Optional($0))
                        }
                    }

                    if let descripcion = modelo?.descripcion, !descripcion.isEmpty {
                        Text(descripcion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    campoNumero("Cantidad", $cantidadTexto)

                    HStack {
                        Text("Costo unitario")
                        Spacer()
                        Text("MX $")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $costoTexto)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }

                    Button("Agregar modelo") {
                        agregarModelo()
                    }
                    .disabled(!detalleValido)
                }

                // MODELOS AGREGADOS
                if !detalles.isEmpty {
                    Section("Modelos agregados") {
                        ForEach(detalles.indices, id: \.self) { i in
                            let d = detalles[i]
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(d.modelo)
                                        .fontWeight(.semibold)
                                    Text(d.articulo)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(formato(d.subtotal))
                                    .fontWeight(.semibold)
                            }
                        }
                        .onDelete { detalles.remove(atOffsets: $0) }
                    }
                }

                Toggle("Aplicar IVA (16%)", isOn: $aplicaIVA)

                // TOTALES
                Section("Totales") {
                    filaMoneda("Subtotal", subtotal)
                    filaMoneda("IVA", iva)
                    filaMoneda("Total", total, bold: true)
                }

                // OBSERVACIONES
                Section("Observaciones") {
                    TextEditor(text: $observaciones)
                        .frame(minHeight: 80)
                }

                Button("Guardar orden de compra") {
                    guardar()
                }
                .disabled(detalles.isEmpty || proveedor == nil)
            }
            .navigationTitle("Nueva OC")
            .onAppear {
                calcularConsecutivo()
            }
        }

        // MARK: - Lógica

        var subtotal: Double {
            detalles.reduce(0) { $0 + $1.subtotal }
        }

        var iva: Double {
            aplicaIVA ? subtotal * 0.16 : 0
        }

        var total: Double {
            subtotal + iva
        }

        var detalleValido: Bool {
            articulo != nil &&
            modelo != nil &&
            (Int(cantidadTexto) ?? 0) > 0 &&
            (Double(costoTexto) ?? 0) > 0
        }

    func agregarModelo() {
        let d = OrdenCompraDetalle(
            articulo: articulo!.nombre,
            modelo: modelo!.nombre,
            cantidad: Int(cantidadTexto)!,
            costoUnitario: Double(costoTexto)!
        )

        d.modeloCatalogo = modelo   // 🔑 ESTA ES LA LÍNEA QUE FALTABA

        detalles.append(d)
        cantidadTexto = ""
        costoTexto = ""
    }

        func guardar() {
            guard let proveedor else { return }

            let oc = OrdenCompra(
                numeroOC: numeroOC,
                proveedor: proveedor.nombre,
                plazoDias: proveedor.plazoPagoDias,
                fechaOrden: Date(),
                fechaEntrega: fechaEntrega,
                aplicaIVA: aplicaIVA,
                tipoCompra: "cliente",   // 🔴 ESTA ES LA CLAVE
                observaciones: observaciones
            )

            detalles.forEach {
                $0.orden = oc
                context.insert($0)
            }

            oc.detalles = detalles
            context.insert(oc)

            do {
                try context.save()
                dismiss()
            } catch {
                print("❌ Error guardando OC:", error)
            }
        }

        func calcularConsecutivo() {
            var fd = FetchDescriptor<OrdenCompra>(
                sortBy: [SortDescriptor(\.numeroOC, order: .reverse)]
            )
            fd.fetchLimit = 1
            numeroOC = ((try? context.fetch(fd))?.first?.numeroOC ?? 0) + 1
        }

        // MARK: - UI helpers

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

        func formato(_ v: Double) -> String {
            "MX $ " + String(format: "%.2f", v)
        }

        func campoNumero(
            _ t: String,
            _ b: Binding<String>
        ) -> some View {
            HStack {
                Text(t)
                Spacer()
                TextField("0", text: b)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        }
    }
