//
//  SalidaInsumoNuevaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//
//
import SwiftUI
import SwiftData

// =========================
// ITEM AGREGADO
// =========================
struct ItemSalida: Identifiable {
    let id = UUID()
    let esServicio: Bool
    let nombre: String
    let talla: String?
    let unidad: String?
    let cantidad: Int
    let costoUnitario: Double

    var total: Double {
        Double(cantidad) * costoUnitario
    }
}

struct SalidaInsumoNuevaView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // =========================
    // CATÁLOGOS
    // =========================
    @Query private var empresas: [Empresa]
    @Query private var clientes: [Cliente]
    @Query private var agentes: [Agente]

    @Query private var articulos: [Articulo]
    @Query private var departamentos: [Departamento]
    @Query private var lineas: [Linea]
    @Query private var modelos: [Modelo]
    @Query(sort: \Talla.orden) private var tallas: [Talla]
    @Query private var unidades: [Unidad]
    @Query private var servicios: [Servicio]

    // INVENTARIO (MODELOS)
    @Query private var recibosProduccion: [ReciboProduccion]
    @Query private var recepcionesCompra: [ReciboCompraDetalle]
    @Query private var ventas: [VentaClienteDetalle]

    @Query private var reingresosDetalle: [ReingresoDetalle]
    
    // =========================
    // ENCABEZADO
    // =========================
    @State private var folio = "Venta #001"
    let fechaCaptura = Date()
    @State private var fechaEntrega = Date()

    // =========================
    // GENERALES
    // =========================
    @State private var empresaID: PersistentIdentifier?
    @State private var clienteID: PersistentIdentifier?
    @State private var agenteID: PersistentIdentifier?
    @State private var numeroDocumento = ""

    // =========================
    // TIPO
    // =========================
    @State private var esServicio = false

    // =========================
    // SELECCIÓN
    // =========================
    @State private var servicioID: PersistentIdentifier?
    @State private var articuloID: PersistentIdentifier?
    @State private var departamentoID: PersistentIdentifier?
    @State private var lineaID: PersistentIdentifier?
    @State private var modeloID: PersistentIdentifier?
    @State private var tallaID: PersistentIdentifier?
    @State private var unidadID: PersistentIdentifier?

    // DETALLE
    @State private var cantidad: Int?
    @State private var costoUnitario: Double?

    // INVENTARIO
    @State private var inventarioDisponible = 0

    // AGREGADOS
    @State private var items: [ItemSalida] = []

    // IVA
    @State private var aplicaIVA = false
    
    @State private var mostrarConfirmacion = false

    // =========================
    // RESOLVERS
    // =========================
    var modeloSeleccionado: Modelo? {
        modelos.first { $0.persistentModelID == modeloID }
    }

    var servicioSeleccionado: Servicio? {
        servicios.first { $0.persistentModelID == servicioID }
    }

    var tallaSeleccionada: Talla? {
        tallas.first { $0.persistentModelID == tallaID }
    }

    var unidadSeleccionada: Unidad? {
        unidades.first { $0.persistentModelID == unidadID }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.total }
    }

    var iva: Double {
        aplicaIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }
    
    var empresaSeleccionada: Empresa? {
        empresas.first { $0.persistentModelID == empresaID }
    }

    var clienteSeleccionado: Cliente? {
        clientes.first { $0.persistentModelID == clienteID }
    }

    var agenteSeleccionado: Agente? {
        agentes.first { $0.persistentModelID == agenteID }
    }


    // =========================
    // BODY
    // =========================
    var body: some View {
        Form {

            // ENCABEZADO
            Section {
                fila("Folio", folio)
                fila("Fecha captura", fechaCaptura.formatted(date: .abbreviated, time: .omitted))
                DatePicker("Fecha entrega", selection: $fechaEntrega, displayedComponents: .date)
            }

            // GENERALES
            Section(header: Text("Empresa y cliente")) {
                Picker("Empresa", selection: $empresaID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(empresas) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                }

                Picker("Cliente", selection: $clienteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(clientes) { Text($0.nombreComercial).tag(Optional($0.persistentModelID)) }
                }

                Picker("Agente", selection: $agenteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(agentes) {
                        Text("\($0.nombre) \($0.apellido)")
                            .tag(Optional($0.persistentModelID))
                    }
                }

                TextField("Nota / Factura", text: $numeroDocumento)
            }

            // TIPO
            Section {
                Toggle("Es servicio", isOn: $esServicio)
                    .onChange(of: esServicio) { _ in limpiarFormulario() }
            }

            // =========================
            // SERVICIO
            // =========================
            if esServicio {
                Section(header: Text("Servicio")) {

                    Picker("Servicio", selection: $servicioID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(servicios) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }
                    .onChange(of: servicioID) { _ in
                        recalcularInventarioServicio(servicioSeleccionado?.nombre)
                    }

                    detalleView
                }
            }

            // =========================
            // MODELO
            // =========================
            if !esServicio {

                Section(header: Text("Producto")) {

                    Picker("Artículo", selection: $articuloID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(articulos) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }

                    Picker("Departamento", selection: $departamentoID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(departamentos) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }

                    Picker("Línea", selection: $lineaID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(lineas) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }

                    Picker("Modelo", selection: $modeloID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(modelos) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }
                    .onChange(of: modeloID) { _ in
                        recalcularInventarioModelo(modeloSeleccionado?.nombre)
                    }

                    Picker("Talla", selection: $tallaID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(tallas) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }

                    Picker("Unidad", selection: $unidadID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(unidades) { Text($0.nombre).tag(Optional($0.persistentModelID)) }
                    }
                }

                Section(header: Text("Detalle")) {
                    detalleView
                }
            }

            // AGREGAR
            Section {
                Button {
                    agregarItem()
                } label: {
                    Label("Agregar", systemImage: "plus.circle.fill")
                }
                .disabled(
                    cantidad == nil ||
                    costoUnitario == nil ||
                    (cantidad ?? 0) > inventarioDisponible
                )
            }

            // AGREGADOS
            if !items.isEmpty {
                Section(header: Text("Agregados")) {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.esServicio ? "Servicio: \(item.nombre)" : "Modelo: \(item.nombre)")
                                    .font(.headline)
                                Text("Cantidad: \(item.cantidad)")
                                    .font(.caption)
                                Text("Total: \(item.total, format: .currency(code: "MXN"))")
                                    .font(.subheadline.bold())
                            }

                            Spacer()

                            Button {
                                eliminarItem(item)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // IVA
            Section {
                Toggle("Aplicar IVA", isOn: $aplicaIVA)
            }

            // TOTALES
            Section(header: Text("Totales")) {
                filaMoneda("Subtotal", subtotal)
                filaMoneda("IVA", iva)
                filaMoneda("Total", total)
            }

            // GUARDAR
            Section {
                Button("Registrar salida") {
                    mostrarConfirmacion = true
                }
                .frame(maxWidth: .infinity)
                .disabled(items.isEmpty)

            }
        }
        .navigationTitle("Salida de Insumo")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Confirmar salida", isPresented: $mostrarConfirmacion) {
            Button("Cancelar", role: .cancel) { }
            Button("Confirmar salida", role: .destructive) {
                guardar()
            }
        } message: {
            Text("¿Deseas confirmar esta salida de insumos?")
        }
    } // 👈 ESTA LLAVE CIERRA var body

    // =========================
    // SUBVISTAS
    // =========================
    var detalleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            campoCantidad
            inventarioView
            campoCosto
        }
    }

    var inventarioView: some View {
        Text("Inventario disponible: \(inventarioDisponible)")
            .font(.caption)
            .foregroundStyle(inventarioDisponible > 0 ? .green : .red)
    }

    // =========================
    // ACCIONES
    // =========================
    func agregarItem() {

        guard
            let cantidad,
            cantidad > 0,
            let costoUnitario,
            costoUnitario > 0
        else {
            return
        }

        if esServicio {

            guard let servicio = servicioSeleccionado else { return }

            items.append(
                ItemSalida(
                    esServicio: true,
                    nombre: servicio.nombre,
                    talla: nil,
                    unidad: unidadSeleccionada?.nombre,
                    cantidad: cantidad,
                    costoUnitario: costoUnitario
                )
            )

        } else {

            guard let modelo = modeloSeleccionado else { return }

            items.append(
                ItemSalida(
                    esServicio: false,
                    nombre: modelo.nombre,
                    talla: tallaSeleccionada?.nombre,
                    unidad: unidadSeleccionada?.nombre,
                    cantidad: cantidad,
                    costoUnitario: costoUnitario
                )
            )
        }

        limpiarFormulario()
    }

    func eliminarItem(_ item: ItemSalida) {
        items.removeAll { $0.id == item.id }
    }

    func guardar() {

        let salida = SalidaInsumo(
            fecha: fechaCaptura,
            fechaEntrega: fechaEntrega,
            folio: folio,
            facturaNota: numeroDocumento,     // 👈 AQUÍ VIVE LA FACTURA
            responsable: "",
            recibeMaterial: "",
            observaciones: "",                // 👈 OBSERVACIONES LIMPIAS
            empresa: empresas.first { $0.persistentModelID == empresaID },
            cliente: clientes.first { $0.persistentModelID == clienteID },
            agente: agentes.first { $0.persistentModelID == agenteID }
        )

        context.insert(salida)

        for item in items {
            let detalle = SalidaInsumoDetalle(
                esServicio: item.esServicio,
                modeloNombre: item.nombre,
                nombreServicio: item.esServicio ? item.nombre : nil,
                cantidad: item.cantidad,
                costoUnitario: item.costoUnitario
            )
            detalle.salida = salida
            context.insert(detalle)
        }

        let movimiento = SalidaInsumoMovimiento(
            titulo: "Salida registrada",
            usuario: "Sistema",
            icono: "arrow.up.square.fill",
            color: "blue",
            salida: salida
        )

        salida.movimientos.append(movimiento)
        context.insert(movimiento)

        try? context.save()
        dismiss()
    }

    func limpiarFormulario() {
        servicioID = nil
        articuloID = nil
        departamentoID = nil
        lineaID = nil
        modeloID = nil
        tallaID = nil
        unidadID = nil
        cantidad = nil
        costoUnitario = nil
        inventarioDisponible = 0
    }

    // =========================
    // INVENTARIO
    // =========================
    func recalcularInventarioModelo(_ nombre: String?) {
        guard let nombre else {
            inventarioDisponible = 0
            return
        }

        // 1️⃣ Base histórica
        let base = InventarioService
            .existenciaActual(
                modeloNombre: nombre,
                context: context
            )
            .cantidad

        // 2️⃣ Reingresos de PRODUCTO
        let reingresosProducto = reingresosDetalle
            .filter {
                !$0.esServicio &&
                $0.modelo?.nombre == nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 3️⃣ Reingresos de SERVICIO (si aplica al inventario)
        let reingresosServicio = reingresosDetalle
            .filter {
                $0.esServicio &&
                $0.nombreServicio == nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 4️⃣ Reservado en esta salida (UI)
        let reservado = items
            .filter { !$0.esServicio && $0.nombre == nombre }
            .reduce(0) { $0 + $1.cantidad }

        inventarioDisponible = max(
            base + reingresosProducto + reingresosServicio - reservado,
            0
        )
    }

    func recalcularInventarioServicio(_ nombre: String?) {
        guard let nombre else {
            inventarioDisponible = 0
            return
        }

        // 1️⃣ Base histórica
        let base = InventarioService
            .existenciaActual(
                modeloNombre: nombre,
                context: context
            )
            .cantidad

        // 2️⃣ Reingresos de SERVICIO
        let reingresosServicio = reingresosDetalle
            .filter {
                $0.esServicio &&
                $0.nombreServicio == nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 3️⃣ Reservado en esta salida (UI)
        let reservado = items
            .filter { $0.esServicio && $0.nombre == nombre }
            .reduce(0) { $0 + $1.cantidad }

        inventarioDisponible = max(
            base + reingresosServicio - reservado,
            0
        )
    }

    // =========================
    // UI HELPERS
    // =========================
    var campoCantidad: some View {
        HStack {
            Text("Cantidad")
            Spacer()
            TextField("0", value: $cantidad, format: .number)
                .keyboardType(.numberPad)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
        }
    }

    var campoCosto: some View {
        HStack {
            Text("Costo unitario")
            Spacer()
            Text("MX$")
            TextField("0.00", value: $costoUnitario, format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 120)
                .multilineTextAlignment(.trailing)
        }
    }

    func fila(_ t: String, _ v: String) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v).foregroundStyle(.secondary)
        }
    }

    func filaMoneda(_ t: String, _ v: Double) -> some View {
        HStack {
            Text(t)
            Spacer()
            Text(v, format: .currency(code: "MXN"))
        }
    }
}
