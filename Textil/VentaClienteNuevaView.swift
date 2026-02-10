//
//  VentaClienteNuevaView.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
import SwiftUI
import SwiftData

struct VentaClienteNuevaView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - CATÁLOGOS
    @Query private var clientes: [Cliente]
    @Query private var agentes: [Agente]
    @Query private var articulos: [Articulo]
    @Query private var departamentos: [Departamento]
    @Query private var lineas: [Linea]
    @Query private var modelos: [Modelo]
    @Query(sort: \Talla.orden) private var tallas: [Talla]
    @Query private var unidades: [Unidad]
    @Query private var empresas: [Empresa]

    @Query private var reingresosDetalle: [ReingresoDetalle]

    // MARK: - INVENTARIO
    @Query private var recibosProduccion: [ReciboProduccion]
    @Query private var recepcionesCompra: [ReciboCompraDetalle]
    @Query private var ventas: [VentaClienteDetalle]

    // MARK: - SELECCIÓN GENERAL
    @State private var clienteID: PersistentIdentifier?
    @State private var agenteID: PersistentIdentifier?
    @State private var articuloID: PersistentIdentifier?
    @State private var departamentoID: PersistentIdentifier?
    @State private var lineaID: PersistentIdentifier?
    @State private var empresaID: PersistentIdentifier?


    // MARK: - ENCABEZADO
    let numeroVenta = "Venta #002"
    let fechaCaptura = Date()
    @State private var fechaEntrega = Date()
    @State private var numeroFactura = ""

    // MARK: - FORM MODELO ACTUAL
    @State private var modeloID: PersistentIdentifier?
    @State private var tallaID: PersistentIdentifier?
    @State private var unidadID: PersistentIdentifier?
    @State private var cantidadForm: Int?
    @State private var costoUnitarioForm: Double?
    @State private var inventarioDisponible: Int = 0
    
    @State private var mostrarAlertaInventario = false
    @State private var mensajeAlertaInventario = ""
    @State private var mostrarAlertaValidacion = false
    @State private var mensajeAlertaValidacion = ""
    
    @State private var mostrarConfirmacionVenta = false

    // MARK: - MODELOS AGREGADOS
    struct ModeloAgregado: Identifiable {
        let id = UUID()
        let modelo: Modelo
        let talla: Talla?
        let unidad: Unidad
        let cantidad: Int
        let costoUnitario: Double

        var total: Double {
            Double(cantidad) * costoUnitario
        }
    }

    @State private var modelosAgregados: [ModeloAgregado] = []

    // MARK: - OTROS
    @State private var aplicarIVA = false
    @State private var observaciones = ""

    // MARK: - RESOLVERS
    var cliente: Cliente? {
        clientes.first { $0.persistentModelID == clienteID }
    }

    var agente: Agente? {
        agentes.first { $0.persistentModelID == agenteID }
    }

    var modeloSeleccionado: Modelo? {
        modelos.first { $0.persistentModelID == modeloID }
    }

    var unidadSeleccionada: Unidad? {
        unidades.first { $0.persistentModelID == unidadID }
    }

    var tallaSeleccionada: Talla? {
        tallas.first { $0.persistentModelID == tallaID }
    }

    // MARK: - CÁLCULOS
    var subtotal: Double {
        modelosAgregados.reduce(0) { $0 + $1.total }
    }

    var iva: Double {
        aplicarIVA ? subtotal * 0.16 : 0
    }

    var total: Double {
        subtotal + iva
    }

    // MARK: - RESUMEN CONFIRMACIÓN
    var resumenVentaTexto: String {
        let piezasTotales = modelosAgregados.reduce(0) { $0 + $1.cantidad }
        let nombreEmpresa = empresas.first { $0.persistentModelID == empresaID }?.nombre ?? "—"
        let nombreCliente = cliente?.nombreComercial ?? "—"

        return """
        Empresa: \(nombreEmpresa)
        Cliente: \(nombreCliente)

        Piezas totales: \(piezasTotales)

        Subtotal: \(formatoMX(subtotal))
        IVA: \(formatoMX(iva))
        Total: \(formatoMX(total))

        ⚠️ Esta acción descontará inventario.
        """
    }
    
    // MARK: - BODY
    var body: some View {
        Form {

            // =========================
            // ENCABEZADO
            // =========================
            Section {
                fila("# de Venta", numeroVenta)
                fila("Fecha de captura", fechaCaptura.formatted(date: .abbreviated, time: .omitted))
                DatePicker("Fecha de entrega", selection: $fechaEntrega, displayedComponents: .date)
            }

            // =========================
            // EMPRESA / CLIENTE
            // =========================
            Section(header: Text("Empresa y cliente")) {

                Picker("Empresa", selection: $empresaID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(empresas) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Cliente", selection: $clienteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(clientes) {
                        Text($0.nombreComercial)
                            .tag(Optional($0.persistentModelID))
                    }
                }

                if let cliente {
                    Text("Plazo: \(cliente.plazoDias) días")
                        .infoBox()
                }

                Picker("Agente", selection: $agenteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(agentes) {
                        Text("\($0.nombre) \($0.apellido)")
                            .tag(Optional($0.persistentModelID))
                    }
                }

                TextField("Número de pedido / factura", text: $numeroFactura)
            }

            // =========================
            // PRODUCTO
            // =========================
            Section(header: Text("Producto")) {

                Picker("Artículo", selection: $articuloID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(articulos) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Departamento", selection: $departamentoID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(departamentos) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Línea", selection: $lineaID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(lineas) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }
            }

            // =========================
            // DETALLE (FORM ÚNICO)
            // =========================
            Section(header: Text("Detalle")) {

                Picker("Modelo", selection: $modeloID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(modelos) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }
                .onChange(of: modeloID) { _ in
                    recalcularInventario()
                }

                if let modeloSeleccionado {
                    Text(modeloSeleccionado.descripcion)
                        .infoBox()
                }

                Picker("Talla", selection: $tallaID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(tallas) {
                        Text($0.nombre)
                            .tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Unidad", selection: $unidadID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(unidades) {
                        Text("\($0.nombre) (\($0.abreviatura))")
                            .tag(Optional($0.persistentModelID))
                    }
                }

                HStack {
                    Text("Cantidad")
                    Spacer()
                    TextField("0", value: $cantidadForm, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }

                Text("Inventario disponible: \(inventarioDisponible) pz")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Text("Costo unitario")
                    Spacer()
                    Text("MX $").foregroundStyle(.secondary)
                    TextField("0.00", value: $costoUnitarioForm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }

                Button {
                    agregarModelo()
                } label: {
                    Label("Agregar modelo", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            // =========================
            // MODELOS AGREGADOS
            // =========================
            if !modelosAgregados.isEmpty {
                Section(header: Text("Modelos agregados")) {

                    ForEach(modelosAgregados) { item in
                        VStack(alignment: .leading, spacing: 6) {

                            HStack {
                                Text(item.modelo.nombre)
                                    .font(.headline)

                                Spacer()

                                Button(role: .destructive) {
                                    eliminarModelo(item)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }

                            if let talla = item.talla {
                                Text("Talla: \(talla.nombre)")
                            }

                            Text("Cantidad: \(item.cantidad)")
                            Text("Costo: \(item.costoUnitario, format: .currency(code: "MXN"))")
                            Text("Total: \(item.total, format: .currency(code: "MXN"))")
                        }
                    }
                }
            }

            // =========================
            // IVA / TOTALES
            // =========================
            Section {
                Toggle("Aplicar IVA (16%)", isOn: $aplicarIVA)
            }

            Section(header: Text("Totales")) {
                filaMoneda("Subtotal", subtotal)
                filaMoneda("IVA", iva)

                HStack {
                    Text("Total").bold()
                    Spacer()
                    Text(total, format: .currency(code: "MXN"))
                        .bold()
                        .foregroundColor(.green)
                }
            }
            // =========================
            // REGISTRAR
            // =========================
            Section {
                Button(
                    action: {
                        mostrarConfirmacionVenta = true
                    },
                    label: {
                        Text("Registrar venta")
                            .frame(maxWidth: .infinity)
                    }
                )
                .disabled(
                    empresaID == nil ||
                    clienteID == nil ||
                    modelosAgregados.isEmpty
                )
            }
        }
        .navigationTitle("Venta Cliente")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Inventario insuficiente",
               isPresented: $mostrarAlertaInventario) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(mensajeAlertaInventario)
        }
        .alert("Datos incompletos",
               isPresented: $mostrarAlertaValidacion) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(mensajeAlertaValidacion)
        }
        .alert("Confirmar venta",
               isPresented: $mostrarConfirmacionVenta) {
            Button("Cancelar", role: .cancel) { }
            Button("Confirmar", role: .destructive) {
                guardarVenta()
            }
        } message: {
            Text(resumenVentaTexto)
        }
    }
    
    // MARK: - LÓGICA
    func recalcularInventario() {
        guard let modeloSeleccionado else {
            inventarioDisponible = 0
            return
        }

        // 1️⃣ Base histórica (ventas, compras, salidas, etc.)
        let base = InventarioService
            .existenciaActual(
                modeloNombre: modeloSeleccionado.nombre,
                context: context
            )
            .cantidad

        // 2️⃣ Reingresos de PRODUCTO
        let reingresosProducto = reingresosDetalle
            .filter {
                !$0.esServicio &&
                $0.modelo?.nombre == modeloSeleccionado.nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 3️⃣ Reingresos de SERVICIO (si aplica al inventario general)
        let reingresosServicio = reingresosDetalle
            .filter {
                $0.esServicio &&
                $0.nombreServicio == modeloSeleccionado.nombre
            }
            .map { $0.cantidad }
            .reduce(0, +)

        // 4️⃣ Reservado en esta venta (UI)
        let reservado = modelosAgregados
            .filter { $0.modelo.nombre == modeloSeleccionado.nombre }
            .reduce(0) { $0 + $1.cantidad }

        // 5️⃣ Disponible final
        inventarioDisponible = max(
            base + reingresosProducto + reingresosServicio - reservado,
            0
        )
    }

    func agregarModelo() {

        guard let modeloSeleccionado,
              let unidadSeleccionada,
              let cantidad = cantidadForm,
              let costoUnitario = costoUnitarioForm
        else {
            mensajeAlertaValidacion = "Completa todos los campos del modelo."
            mostrarAlertaValidacion = true
            return
        }

        guard cantidad > 0 else {
            mensajeAlertaValidacion = "La cantidad debe ser mayor a cero."
            mostrarAlertaValidacion = true
            return
        }

        // 🔴 VALIDACIÓN DE INVENTARIO REAL
        if cantidad > inventarioDisponible {
            mensajeAlertaInventario =
            """
            Inventario insuficiente.

            Disponible: \(inventarioDisponible)
            Intentas vender: \(cantidad)
            """
            mostrarAlertaInventario = true
            return
        }

        modelosAgregados.append(
            ModeloAgregado(
                modelo: modeloSeleccionado,
                talla: tallaSeleccionada,
                unidad: unidadSeleccionada,
                cantidad: cantidad,
                costoUnitario: costoUnitario
            )
        )

        // LIMPIAR FORM
        modeloID = nil
        tallaID = nil
        unidadID = nil
        cantidadForm = nil
        costoUnitarioForm = nil
        inventarioDisponible = 0
    }

    func eliminarModelo(_ item: ModeloAgregado) {
        modelosAgregados.removeAll { $0.id == item.id }
    }

    func guardarVenta() {
        // =========================
        // VALIDACIONES
        // =========================
        guard empresaID != nil else {
            mostrarAlertaValidacion = true
            mensajeAlertaValidacion = "Selecciona una empresa."
            return
        }

        guard let cliente = cliente else {
            mostrarAlertaValidacion = true
            mensajeAlertaValidacion = "Selecciona un cliente."
            return
        }

        guard !modelosAgregados.isEmpty else {
            mostrarAlertaValidacion = true
            mensajeAlertaValidacion = "Agrega al menos un modelo."
            return
        }

        // =========================
        // CREAR VENTA
        // =========================
        let nombreEmpresa = empresas
            .first { $0.persistentModelID == empresaID }?
            .nombre ?? ""

        let venta = VentaCliente(
            folio: numeroVenta,
            fechaEntrega: fechaEntrega,
            cliente: cliente,
            agente: agente,
            numeroFactura: numeroFactura,
            aplicaIVA: aplicarIVA,
            observaciones: observaciones,
            empresa: nombreEmpresa
        )

        context.insert(venta)

        // =========================
        // CREAR DETALLES (DESCUENTO)
        // =========================
        for item in modelosAgregados {
            let detalle = VentaClienteDetalle(
                modeloNombre: item.modelo.nombre,
                cantidad: item.cantidad,
                costoUnitario: item.costoUnitario,
                unidad: item.unidad.nombre,
                venta: venta
            )
            context.insert(detalle)
        }

        // =========================
        // GUARDAR
        // =========================
        do {
            try context.save()
            dismiss()
        } catch {
            mostrarAlertaValidacion = true
            mensajeAlertaValidacion = "Error al guardar la venta."
        }
    }
    // MARK: - HELPERS
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
func formatoMX(_ valor: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "MXN"
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: valor)) ?? "MXN $0.00"
}
