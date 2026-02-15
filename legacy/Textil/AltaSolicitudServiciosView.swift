//
//  AltaSolicitudServiciosView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
import SwiftUI
import SwiftData

struct AltaSolicitudServiciosView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // CATÁLOGOS
    @Query private var proveedores: [Proveedor]
    @Query private var servicios: [Servicio]

    // HEADER
    @State private var numeroOC: Int = 0
    @State private var fechaEntrega: Date = Date()

    @State private var proveedor: Proveedor?

    // DETALLE ACTUAL
    @State private var servicio: Servicio?
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
                fila("Solicitud de servicio", "SS00-\(numeroOC)")
                fila(
                    "Fecha solicitud",
                    Date().formatted(.dateTime.day().month(.abbreviated).year())
                )
                DatePicker(
                    "Fecha servicio",
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
            Section("Detalle del servicio") {
                Picker("Servicio", selection: $servicio) {
                    Text("Seleccionar").tag(Servicio?.none)
                    ForEach(servicios.filter { $0.activo }) {
                        Text($0.nombre).tag(Optional($0))
                    }
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

                Button("Agregar servicio") {
                    agregarServicio()
                }
                .disabled(!detalleValido)
            }

            // SERVICIOS AGREGADOS
            if !detalles.isEmpty {
                Section("Servicios agregados") {
                    ForEach(detalles.indices, id: \.self) { i in
                        let d = detalles[i]
                        HStack {
                            Text(d.modelo)
                                .fontWeight(.semibold)
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

            Button("Guardar solicitud") {
                guardar()
            }
            .disabled(detalles.isEmpty || proveedor == nil)
        }
        .navigationTitle("Solicitud de Servicios")
        .onAppear {
            calcularConsecutivo()
        }
    }

    // MARK: - LÓGICA

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
        servicio != nil &&
        (Int(cantidadTexto) ?? 0) > 0 &&
        (Double(costoTexto) ?? 0) > 0
    }

    func agregarServicio() {
        let d = OrdenCompraDetalle(
            articulo: "SERVICIO",
            modelo: servicio!.nombre,
            cantidad: Int(cantidadTexto)!,
            costoUnitario: Double(costoTexto)!
        )
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
            tipoCompra: "servicio",
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
            print("❌ Error guardando solicitud de servicio:", error)
        }
    }

    func calcularConsecutivo() {
        var fd = FetchDescriptor<OrdenCompra>(
            sortBy: [SortDescriptor(\.numeroOC, order: .reverse)]
        )
        fd.fetchLimit = 1
        numeroOC = ((try? context.fetch(fd))?.first?.numeroOC ?? 0) + 1
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
