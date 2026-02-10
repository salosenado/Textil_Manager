//
//  ReingresoNuevoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
//
//  ReingresoNuevoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//

import SwiftUI
import SwiftData

struct ReingresoNuevoView: View {

    // MARK: - ENV
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - CATÁLOGOS
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

    // MARK: - ENCABEZADO
    @State private var folio = "REING-001"
    let fechaCaptura = Date()

    // MARK: - RESPONSABLES
    @State private var responsable = ""
    @State private var recibe = ""
    @State private var referencia = ""
    @State private var observaciones = ""

    // MARK: - GENERALES
    @State private var empresaID: PersistentIdentifier?
    @State private var clienteID: PersistentIdentifier?
    @State private var agenteID: PersistentIdentifier?

    // MARK: - TIPO
    @State private var esServicio = false

    // MARK: - SELECCIÓN
    @State private var servicioID: PersistentIdentifier?
    @State private var articuloID: PersistentIdentifier?
    @State private var departamentoID: PersistentIdentifier?
    @State private var lineaID: PersistentIdentifier?
    @State private var modeloID: PersistentIdentifier?
    @State private var tallaID: PersistentIdentifier?
    @State private var unidadID: PersistentIdentifier?

    // MARK: - DETALLE
    @State private var cantidad: Int?
    @State private var costoUnitario: Double?

    // MARK: - ITEMS
    @State private var items: [ItemReingreso] = []
    @State private var mostrarConfirmacion = false

    // MARK: - TOTALES
    @State private var aplicaIVA = false
    let tasaIVA = 0.16

    var subtotal: Double {
        items.reduce(0) { $0 + $1.total }
    }

    var iva: Double {
        aplicaIVA ? subtotal * tasaIVA : 0
    }

    var totalGeneral: Double {
        subtotal + iva
    }

    // MARK: - RESOLVERS
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

    // MARK: - BODY
    var body: some View {
        Form {

            // ENCABEZADO
            Section {
                fila("Folio", folio)
                fila("Fecha", fechaCaptura.formatted(date: .abbreviated, time: .omitted))
            }

            // RESPONSABLES
            Section("Responsables") {
                TextField("Responsable", text: $responsable)
                TextField("Recibe", text: $recibe)
            }

            // EMPRESA / CLIENTE / AGENTE
            Section("Empresa / Cliente") {
                Picker("Empresa", selection: $empresaID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(empresas) {
                        Text($0.nombre).tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Cliente", selection: $clienteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(clientes) {
                        Text($0.nombreComercial).tag(Optional($0.persistentModelID))
                    }
                }

                Picker("Agente", selection: $agenteID) {
                    Text("Seleccionar").tag(PersistentIdentifier?.none)
                    ForEach(agentes) {
                        Text($0.nombre).tag(Optional($0.persistentModelID))
                    }
                }

                TextField("Referencia / Nota", text: $referencia)
            }

            // TIPO
            Section {
                Toggle("Es servicio", isOn: $esServicio)
                    .onChange(of: esServicio) {
                        limpiarFormulario()
                    }
            }

            // SERVICIO
            if esServicio {
                Section("Servicio") {
                    Picker("Servicio", selection: $servicioID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(servicios) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }
                    detalleCantidadCosto
                }
            }

            // PRODUCTO
            if !esServicio {
                Section("Producto") {
                    Picker("Artículo", selection: $articuloID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(articulos) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }

                    Picker("Departamento", selection: $departamentoID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(departamentos) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }

                    Picker("Línea", selection: $lineaID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(lineas) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }
                }

                Section("Detalle") {
                    Picker("Modelo", selection: $modeloID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(modelos) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }

                    Picker("Talla", selection: $tallaID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(tallas) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }

                    Picker("Unidad", selection: $unidadID) {
                        Text("Seleccionar").tag(PersistentIdentifier?.none)
                        ForEach(unidades) {
                            Text($0.nombre).tag(Optional($0.persistentModelID))
                        }
                    }

                    detalleCantidadCosto
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
                    (esServicio ? servicioID == nil : modeloID == nil)
                )
            }

            // ITEMS
            Section("Agregados") {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.esServicio
                                 ? "Servicio: \(item.nombre)"
                                 : "Modelo: \(item.nombre)")
                                .font(.headline)

                            Text("Cantidad: \(item.cantidad)")
                                .font(.caption)
                        }
                        Spacer()
                        Button {
                            eliminarItem(item)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            // IVA
            Section {
                Toggle("Aplicar IVA (16%)", isOn: $aplicaIVA)
                    .disabled(items.isEmpty)
            }

            // TOTALES
            Section("Totales") {
                fila("Subtotal", formatoMoneda(subtotal))
                fila("IVA", formatoMoneda(iva))
                fila("Total", formatoMoneda(totalGeneral))
            }

            // ADVERTENCIA
            Section {
                Label("Este movimiento afectará el inventario",
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.footnote)
            }

            // GUARDAR
            Section {
                Button("Registrar reingreso") {
                    mostrarConfirmacion = true
                }
                .frame(maxWidth: .infinity)
                .disabled(items.isEmpty || responsable.isEmpty || recibe.isEmpty || agenteID == nil)
            }
        }
        .navigationTitle("Nuevo Reingreso")
        .alert("Confirmar reingreso", isPresented: $mostrarConfirmacion) {
            Button("Cancelar", role: .cancel) {}
            Button("Confirmar", role: .destructive) {
                guardar()
            }
        }
    }

    // MARK: - SUBVISTA
    var detalleCantidadCosto: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cantidad")
                Spacer()
                TextField("0", value: $cantidad, format: .number)
                    .keyboardType(.numberPad)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Costo unitario")
                Spacer()
                Text("MX$")
                TextField("0.00", value: $costoUnitario, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
            }

            Divider()

            HStack {
                Text("Total modelo").font(.headline)
                Spacer()
                Text(formatoMoneda(Double(cantidad ?? 0) * (costoUnitario ?? 0)))
                    .font(.headline)
            }
        }
    }

    // MARK: - ACCIONES
    func agregarItem() {
        guard let cantidad, let costoUnitario else { return }

        let nombre = esServicio
            ? servicioSeleccionado?.nombre
            : modeloSeleccionado?.nombre

        guard let nombre else { return }

        items.append(
            ItemReingreso(
                esServicio: esServicio,
                nombre: nombre,
                talla: tallaSeleccionada?.nombre,
                unidad: unidadSeleccionada?.nombre,
                cantidad: cantidad,
                costoUnitario: costoUnitario
            )
        )

        limpiarFormulario()
    }

    func eliminarItem(_ item: ItemReingreso) {
        items.removeAll { $0.id == item.id }
    }

    func guardar() {

        // 1️⃣ CREAR REINGRESO
        let reingreso = Reingreso(
            fecha: fechaCaptura,
            folio: folio,
            referencia: referencia,
            responsable: responsable,
            recibeMaterial: recibe,
            observaciones: observaciones,
            empresa: empresas.first { $0.persistentModelID == empresaID },
            cliente: clientes.first { $0.persistentModelID == clienteID }
        )

        context.insert(reingreso)

        // 2️⃣ DETALLES + INVENTARIO
        for item in items {

            let modelo = item.esServicio
                ? nil
                : modelos.first(where: { $0.nombre == item.nombre })

            let detalle = ReingresoDetalle(
                esServicio: item.esServicio,
                modelo: modelo,
                nombreServicio: item.esServicio ? item.nombre : nil,
                cantidad: item.cantidad,
                costoUnitario: item.costoUnitario
            )

            detalle.reingreso = reingreso
            context.insert(detalle)

            // 🔥 SUMA A INVENTARIO (SOLO PRODUCTO)
            if let modelo = detalle.modelo {
                modelo.existencia += item.cantidad
                context.insert(modelo)
            }
        }

        // 3️⃣ MOVIMIENTO INICIAL (CLAVE PARA QUE SE VEAN)
        let movimiento = ReingresoMovimiento(
            titulo: "Reingreso registrado",
            usuario: "Sistema",
            icono: "tray.and.arrow.down.fill",
            color: "green",
            reingreso: reingreso
        )

        reingreso.movimientos.append(movimiento)
        context.insert(movimiento)

        // 4️⃣ GUARDAR TODO
        do {
            try context.save()
        } catch {
            print("❌ Error guardando reingreso:", error)
        }

        // 5️⃣ CERRAR VISTA
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
    }

    func fila(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(valor).foregroundStyle(.secondary)
        }
    }
}
