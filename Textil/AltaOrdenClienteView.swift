//
//  AltaOrdenClienteView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//
import SwiftUI
import SwiftData

struct AltaOrdenClienteView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let ordenExistente: OrdenCliente?

    // MARK: - CATÁLOGOS
    @Query private var clientes: [Cliente]
    @Query private var agentes: [Agente]
    @Query private var departamentos: [Departamento]
    @Query private var articulos: [Articulo]
    @Query private var lineas: [Linea]
    @Query private var modelos: [Modelo]
    @Query private var colores: [ColorModelo]
    @Query private var tallas: [Talla]
    @Query private var unidades: [Unidad]

    // MARK: - HEADER
    @State private var numeroVenta: Int = 0
    @State private var fechaEntrega: Date = Date()

    // MARK: - SELECCIÓN
    @State private var agente: Agente?
    @State private var cliente: Cliente?
    @State private var pedidoCliente: String = ""

    @State private var articulo: Articulo?
    @State private var departamento: Departamento?
    @State private var linea: Linea?
    @State private var modelo: Modelo?
    @State private var color: ColorModelo?
    @State private var talla: Talla?
    @State private var unidad: Unidad?

    // MARK: - DETALLE ACTUAL
    @State private var cantidadTexto: String = ""
    @State private var costoUnitarioTexto: String = ""

    // MARK: - PRODUCTOS
    @State private var detalles: [OrdenClienteDetalle] = []

    @State private var aplicaIVA: Bool = false
    @State private var observaciones: String = ""

    var body: some View {
        Form {

            // HEADER
            Section {
                filaSimple("# de Venta", "Venta #\(numeroVenta)")
                filaSimple(
                    "Fecha de captura",
                    (ordenExistente?.fechaCreacion ?? Date())
                        .formatted(.dateTime.day().month(.abbreviated).year())
                )
                DatePicker("Fecha de entrega", selection: $fechaEntrega, displayedComponents: .date)
            }

            // AGENTE
            Section("Agente") {
                Picker("Agente", selection: $agente) {
                    Text("Seleccionar").tag(Agente?.none)
                    ForEach(agentes.filter { $0.activo }) {
                        Text("\($0.nombre) \($0.apellido)").tag(Optional($0))
                    }
                }
            }

            // CLIENTE
            Section("Cliente") {
                Picker("Cliente", selection: $cliente) {
                    Text("Seleccionar").tag(Cliente?.none)
                    ForEach(clientes.filter { $0.activo }) {
                        Text($0.nombreComercial).tag(Optional($0))
                    }
                }

                if let plazo = cliente?.plazoDias {
                    Text("Plazo: \(plazo) días")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                TextField("Número de pedido", text: $pedidoCliente)
            }

            // PRODUCTO
            Section("Producto") {
                Picker("Artículo", selection: $articulo) {
                    Text("Seleccionar").tag(Articulo?.none)
                    ForEach(articulos.filter { $0.activo }) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Departamento", selection: $departamento) {
                    Text("Seleccionar").tag(Departamento?.none)
                    ForEach(departamentos.filter { $0.activo }) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Línea", selection: $linea) {
                    Text("Seleccionar").tag(Linea?.none)
                    ForEach(lineas.filter { $0.activo }) {
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
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Picker("Color", selection: $color) {
                    Text("Seleccionar").tag(ColorModelo?.none)
                    ForEach(colores.filter { $0.activo }) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                Picker("Talla", selection: $talla) {
                    Text("Seleccionar").tag(Talla?.none)
                    ForEach(tallas.sorted { $0.orden < $1.orden }) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }
            }

            // DETALLE
            Section("Detalle") {
                Picker("Unidad", selection: $unidad) {
                    Text("Seleccionar").tag(Unidad?.none)
                    ForEach(unidades) {
                        Text($0.nombre).tag(Optional($0))
                    }
                }

                HStack {
                    Text("Cantidad")
                    Spacer()
                    TextField("0", text: $cantidadTexto)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }

                HStack {
                    Text("Costo unitario")
                    Spacer()
                    Text("MX $")
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $costoUnitarioTexto)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                HStack {
                    Text("Total modelo")
                    Spacer()
                    Text(formatoMX(totalModelo))
                        .fontWeight(.semibold)
                }

                Button("Agregar producto") {
                    agregarProducto()
                }
                .disabled(!productoValido)
            }

            // MODELOS AGREGADOS
            if !detalles.isEmpty {
                Section("Modelos agregados") {
                    ForEach(detalles.indices, id: \.self) { index in
                        let d = detalles[index]

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(d.modelo).fontWeight(.semibold)
                                Spacer()
                                Text(formatoMX(d.subtotal)).fontWeight(.semibold)
                            }

                            Text("\(d.articulo) · \(d.linea)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Color: \(d.color) · Talla: \(d.talla)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            HStack {
                                Text("Cantidad: \(d.cantidad) \(d.unidad)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(role: .destructive) {
                                    detalles.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            Toggle("Aplicar IVA (16%)", isOn: $aplicaIVA)

            Section("Totales") {
                filaMoneda("Subtotal", subtotal)
                filaMoneda("IVA", iva)
                filaMoneda("Total", total, bold: true, color: .green)
            }

            Section("Observaciones") {
                TextEditor(text: $observaciones)
                    .frame(minHeight: 80)
            }

            Button("Registrar venta") {
                guardarOrden()
            }
            .disabled(detalles.isEmpty)
        }
        .navigationTitle("Nueva venta")
        .onAppear {
            var descriptor = FetchDescriptor<OrdenCliente>(
                sortBy: [SortDescriptor(\.numeroVenta, order: .reverse)]
            )
            descriptor.fetchLimit = 1

            let ultimo = (try? context.fetch(descriptor))?.first?.numeroVenta ?? 0
            numeroVenta = ordenExistente?.numeroVenta ?? ultimo + 1
        }
    }

    // MARK: - LÓGICA

    var cantidad: Int { Int(cantidadTexto) ?? 0 }
    var costoUnitario: Double { Double(costoUnitarioTexto) ?? 0 }
    var totalModelo: Double { Double(cantidad) * costoUnitario }

    var subtotal: Double { detalles.reduce(0) { $0 + $1.subtotal } }
    var iva: Double { aplicaIVA ? subtotal * 0.16 : 0 }
    var total: Double { subtotal + iva }

    var productoValido: Bool {
        cliente != nil &&
        agente != nil &&
        modelo != nil &&
        unidad != nil &&
        cantidad > 0 &&
        costoUnitario > 0
    }

    func agregarProducto() {
        guard
            let articulo,
            let linea,
            let modelo,
            let color,
            let talla,
            let unidad
        else { return }

        let detalle = OrdenClienteDetalle(
            articulo: articulo.nombre,
            linea: linea.nombre,
            modelo: modelo.nombre,
            color: color.nombre,
            talla: talla.nombre,
            unidad: unidad.nombre,
            cantidad: cantidad,
            precioUnitario: costoUnitario,
            modeloCatalogo: modelo
        )

        detalles.append(detalle)
        cantidadTexto = ""
        costoUnitarioTexto = ""
    }

    func guardarOrden() {

        guard let cliente else { return }

        // 1️⃣ Crear la orden (SIN detalles)
        let orden = OrdenCliente(
            numeroVenta: numeroVenta,
            cliente: cliente.nombreComercial,
            numeroPedidoCliente: pedidoCliente,
            fechaCreacion: Date(),
            fechaEntrega: fechaEntrega,
            aplicaIVA: aplicaIVA,
            agente: agente
        )

        // 2️⃣ Insertar la orden primero
        context.insert(orden)

        // 3️⃣ Relacionar y guardar cada detalle
        for d in detalles {
            d.orden = orden          // 🔑 relación correcta
            orden.detalles.append(d)
            context.insert(d)
        }

        // 4️⃣ Guardar todo
        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Error guardando orden:", error)
        }
    }

    // MARK: - UI HELPERS

    func filaSimple(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor).foregroundStyle(.secondary)
        }
    }

    func filaMoneda(
        _ titulo: String,
        _ valor: Double,
        bold: Bool = false,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(titulo).fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(formatoMX(valor))
                .foregroundStyle(color)
                .fontWeight(bold ? .bold : .regular)
        }
    }

    func formatoMX(_ valor: Double) -> String {
        "MX $ " + String(format: "%.2f", valor)
    }
}
