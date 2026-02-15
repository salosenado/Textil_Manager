//
//  DetalleCentroImpresionView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//
//
//  DetalleCentroImpresionView.swift
//  Textil
//
//
//  DetalleCentroImpresionView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct DetalleCentroImpresionView: View {

    let produccion: Produccion?
    let ordenCompra: OrdenCompra?

    @Query private var empresas: [Empresa]
    @Query private var modelosDB: [Modelo]
    @Query private var registrosImpresion: [RegistroImpresion]


    @State private var empresaSeleccionada: Empresa?
    @State private var responsable = ""
    @State private var proveedorOMaquilero = ""

    @State private var firmaResponsable: UIImage?
    @State private var firmaProveedor: UIImage?

    @State private var mostrarFirmaResponsable = false
    @State private var mostrarFirmaProveedor = false
    
    @State private var pdfURL: URL?
    @State private var mostrarPDF = false
    @State private var ordenBloqueada = false

    
    
    @Environment(\.modelContext) private var context



    // 🔎 ID único por registro
    // 🔎 ID único por registro
    var idReferencia: String {

        if let p = produccion {
            return "PROD-\(p.ordenMaquila ?? "")"
        }

        if let o = ordenCompra {
            return "OC-\(o.folio)"
        }

        return "SIN_REFERENCIA"
    }

    var yaImpreso: Bool {
        registrosImpresion.contains { $0.idReferencia == idReferencia }
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                if ordenBloqueada {

                    Text("🔒 Documento bloqueado por impresión")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }

                bloqueInformacionGeneral
                bloqueDetalle
                datosResponsables
                bloqueFirmas
                botonImprimir

                // 🔥 HISTORIAL
                let movimientos = registrosImpresion.filter { $0.idReferencia == idReferencia }

                if !movimientos.isEmpty {

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Historial de movimientos")
                            .font(.headline)

                        ForEach(movimientos, id: \.fecha) { registro in


                            Text("\(registro.tipo) - \(registro.fecha.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                }

                Color.clear.frame(height: 40)
            }
            .padding()
        }
        .navigationTitle("Preparar impresión")
        .navigationBarTitleDisplayMode(.inline)

        .sheet(isPresented: $mostrarFirmaResponsable) {
            if !ordenBloqueada {
                VistaFirma { firmaResponsable = $0 }
            }
        }
        .sheet(isPresented: $mostrarFirmaProveedor) {
            if !ordenBloqueada {
                VistaFirma { firmaProveedor = $0 }
            }
        }

        .onAppear {
            cargarDatos()
            ordenBloqueada = yaImpreso
        }

        .onChange(of: empresaSeleccionada) { _ in guardarDatosAutomatico() }
        .onChange(of: responsable) { _ in guardarDatosAutomatico() }
        .onChange(of: proveedorOMaquilero) { _ in guardarDatosAutomatico() }
        .onChange(of: firmaResponsable) { _ in guardarDatosAutomatico() }
        .onChange(of: firmaProveedor) { _ in guardarDatosAutomatico() }

        }
    }

//////////////////////////////////////////////////////////
// MARK: - CARGAR DATOS
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    func cargarDatos() {

        guard let data = UserDefaults.standard.data(forKey: idReferencia),
              let registro = try? JSONDecoder().decode(RegistroLocal.self, from: data)
        else { return }

        empresaSeleccionada = empresas.first(where: { $0.nombre == registro.empresa })
        responsable = registro.responsable
        proveedorOMaquilero = registro.proveedor

        if let data1 = registro.firmaResponsable,
           let image1 = UIImage(data: data1),
           image1.size.width > 0 {
            firmaResponsable = image1
        } else {
            firmaResponsable = nil
        }

        if let data2 = registro.firmaProveedor,
           let image2 = UIImage(data: data2),
           image2.size.width > 0 {
            firmaProveedor = image2
        } else {
            firmaProveedor = nil
        }
    }

    func guardarDatosAutomatico() {

        let nuevo = RegistroLocal(
            empresa: empresaSeleccionada?.nombre ?? "",
            responsable: responsable,
            proveedor: proveedorOMaquilero,
            firmaResponsable: firmaResponsable?.pngData(),
            firmaProveedor: firmaProveedor?.pngData()
        )

        if let encoded = try? JSONEncoder().encode(nuevo) {
            UserDefaults.standard.set(encoded, forKey: idReferencia)
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - BLOQUE INFORMACIÓN GENERAL
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    var bloqueInformacionGeneral: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Información general")
                .font(.headline)

            if let p = produccion {

                Text("Tipo: Producción")
                Text("Orden maquila: \(p.ordenMaquila ?? "-")")
                Text("Maquilero: \(p.maquilero ?? proveedorOMaquilero)")
                Text("Cliente: \(p.detalle?.orden?.cliente ?? "-")")

                if let fechaEnvio = p.detalle?.orden?.fechaCreacion {
                    Text("Fecha envío: \(fechaEnvio.formatted(date: .abbreviated, time: .omitted))")
                }

                if let fechaEntrega = p.detalle?.orden?.fechaEntrega {
                    Text("Fecha entrega: \(fechaEntrega.formatted(date: .abbreviated, time: .omitted))")
                }
            }

            else if let orden = ordenCompra {
                
                
                let tipoTexto = orden.tipoCompra.lowercased() == "servicio"
                    ? "Servicio"
                    : "Compra"

                Text("Tipo: \(tipoTexto)")
                Text("Folio: \(orden.folio)")
                Text("Proveedor: \(orden.proveedor)")
                Text("Fecha orden: \(orden.fechaOrden.formatted(date: .abbreviated, time: .omitted))")
                Text("Fecha recibo: \(orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

//////////////////////////////////////////////////////////
// MARK: - BLOQUE DETALLE
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    var bloqueDetalle: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Detalle")
                .font(.headline)

            if let p = produccion {

                let cantidad = p.pzCortadas
                let modeloNombre = p.detalle?.modelo ?? "-"
                let descripcionModelo = modelosDB.first(where: { $0.nombre == modeloNombre })?.descripcion ?? "-"
                let costo = p.costoMaquila
                let subtotal = Double(p.pzCortadas) * costo

                VStack(alignment: .leading, spacing: 6) {
                    Text("Modelo: \(modeloNombre)")
                    Text("Descripción: \(descripcionModelo)")
                    Text("Cantidad: \(cantidad)")
                    Text("Costo unitario: \(formatoMX(costo))")
                    Text("Subtotal: \(formatoMX(subtotal))")
                }
            }



            else if let orden = ordenCompra {

                ForEach(orden.detalles) { d in

                    let descripcionModelo = modelosDB
                        .first(where: { $0.nombre == d.modelo })?
                        .descripcion ?? "-"

                    VStack(alignment: .leading, spacing: 6) {

                        Text("Modelo: \(d.modelo)")
                            .font(.subheadline)

                        Text("Descripción: \(descripcionModelo)")
                        Text("Cantidad: \(d.cantidad)")
                        Text("Costo unitario: \(formatoMX(d.costoUnitario))")
                        Text("Subtotal: \(formatoMX(Double(d.cantidad) * d.costoUnitario))")
                    }

                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

//////////////////////////////////////////////////////////
// MARK: - RESPONSABLES
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    var datosResponsables: some View {

        VStack(spacing: 18) {

            VStack(spacing: 0) {

                HStack {

                    Text("Empresa")
                    Spacer()

                    Picker("", selection: $empresaSeleccionada) {

                        Text("Seleccionar")
                            .tag(nil as Empresa?)

                        ForEach(empresas) { e in
                            Text(e.nombre)
                                .foregroundColor(.primary)
                                .tag(Optional(e))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary) // 👈 esto quita el azul
                    .disabled(ordenBloqueada)
                }

                Divider()
            }

            TextField("Nombre responsable", text: $responsable)
                .textFieldStyle(.roundedBorder)
                .disabled(ordenBloqueada)


            TextField(
                produccion != nil
                ? "Nombre maquilero"
                : "Proveedor / Dueño",
                text: $proveedorOMaquilero
            )
            .textFieldStyle(.roundedBorder)
            .disabled(ordenBloqueada)

        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

//////////////////////////////////////////////////////////
// MARK: - FIRMAS
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    var bloqueFirmas: some View {

        VStack(spacing: 16) {

            Button {
                if !ordenBloqueada {
                    mostrarFirmaResponsable = true
                }
            }

            label: {
                filaFirma("Firmar responsable", firmaResponsable)
            }
            .disabled(ordenBloqueada)


            Button {
                if !ordenBloqueada {
                    mostrarFirmaProveedor = true
                }
            
            } label: {
                filaFirma(
                    produccion != nil
                    ? "Firmar maquilero"
                    : "Firmar proveedor",
                    firmaProveedor
                )
            }
            .disabled(ordenBloqueada)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

//////////////////////////////////////////////////////////
// MARK: - BOTONES PDF E IMPRESIÓN
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    var puedeImprimir: Bool {
        empresaSeleccionada != nil &&
        !responsable.trimmingCharacters(in: .whitespaces).isEmpty &&
        !proveedorOMaquilero.trimmingCharacters(in: .whitespaces).isEmpty &&
        firmaResponsable != nil &&
        firmaProveedor != nil
    }

    var botonImprimir: some View {

        VStack(spacing: 12) {

            Button {

                guardarDatosAutomatico()

                let tipo = produccion != nil ? "Producción" : (ordenCompra?.tipoCompra ?? "")
                let folio = produccion?.ordenMaquila ?? ordenCompra?.folio ?? ""
                let clienteProveedor: String

                if let p = produccion {
                    clienteProveedor = p.maquilero ?? ""
                } else {
                    clienteProveedor = ordenCompra?.proveedor ?? ""
                }


                let fechaOrden = produccion?.detalle?.orden?.fechaCreacion
                    .formatted(date: .abbreviated, time: .omitted)
                    ?? ordenCompra?.fechaOrden
                        .formatted(date: .abbreviated, time: .omitted)
                    ?? ""

                let fechaEntrega = produccion?.detalle?.orden?.fechaEntrega
                    .formatted(date: .abbreviated, time: .omitted)
                    ?? ordenCompra?.fechaEntrega
                        .formatted(date: .abbreviated, time: .omitted)
                    ?? ""

                let modelos: [String] = {

                    if let p = produccion {

                        let modeloNombre = p.detalle?.modelo ?? "-"
                        let descripcionModelo = modelosDB
                            .first(where: { $0.nombre == modeloNombre })?
                            .descripcion ?? "-"

                        let cantidad = p.pzCortadas
                        let costo = p.costoMaquila
                        let subtotal = Double(cantidad) * costo

                        return [
                            """
                            Modelo: \(modeloNombre)
                            Descripción: \(descripcionModelo)
                            Cantidad: \(cantidad)
                            Costo unitario: \(formatoMX(costo))
                            Subtotal: \(formatoMX(subtotal))
                            """
                        ]
                    }

                    if let orden = ordenCompra {

                        return orden.detalles.map { detalle in
                            let descripcionModelo = modelosDB
                                .first(where: { $0.nombre == detalle.modelo })?
                                .descripcion ?? "-"

                            let subtotal = Double(detalle.cantidad) * detalle.costoUnitario

                            return """
                            Modelo: \(detalle.modelo)
                            Descripción: \(descripcionModelo)
                            Cantidad: \(detalle.cantidad)
                            Costo unitario: \(formatoMX(detalle.costoUnitario))
                            Subtotal: \(formatoMX(subtotal))
                            """
                        }
                    }

                    return []
                }()

                let esReimpresion = yaImpreso

                if let url = CentroImpresionPDF.generarPDF(
                    titulo: "Centro de Impresión",
                    empresa: empresaSeleccionada,
                    tipo: tipo,
                    folio: folio,
                    clienteProveedor: clienteProveedor,
                    fechaOrden: fechaOrden,
                    fechaEntrega: fechaEntrega,
                    modelos: modelos,
                    responsable: responsable,
                    proveedorFirma: proveedorOMaquilero,
                    firmaResponsable: firmaResponsable,
                    firmaProveedor: firmaProveedor
                ),
                FileManager.default.fileExists(atPath: url.path) {

                    pdfURL = url
                    mostrarPDF = true
                    ordenBloqueada = true   // ✅ AQUÍ SÍ VA

                    if esReimpresion {
                        registrarImpresion(tipo: "REIMPRESION")
                    } else {
                        registrarImpresion(tipo: "NUEVO")
                    }
                }

                } label: {
                    Text(yaImpreso ? "Ver PDF" : "Generar PDF")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(puedeImprimir || yaImpreso ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .disabled(!puedeImprimir && !yaImpreso)

                if let url = pdfURL {

                    Button {

                        registrarImpresion(tipo: "IMPRESO")

                        let printInfo = UIPrintInfo(dictionary: nil)
                        printInfo.outputType = .general
                        printInfo.jobName = "Centro de Impresión"

                        let controller = UIPrintInteractionController.shared
                        controller.printInfo = printInfo
                        controller.printingItem = url
                        controller.present(animated: true)

                    } label: {
                        Text("Imprimir Documento")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - FILA FIRMA
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    func filaFirma(_ titulo: String, _ imagen: UIImage?) -> some View {

        HStack {

            Text(titulo)
                .foregroundColor(.primary)

            Spacer()

            if let img = imagen,
               img.size.width > 0 {

                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 60)

            } else {

                Text("Sin firma")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(14)
    }

}
//////////////////////////////////////////////////////////
// MARK: - FORMATO MONEDA MX
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    func formatoMX(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "es_MX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: valor)) ?? "$0.00"
    }
}
//////////////////////////////////////////////////////////
// MARK: - REGISTRO IMPRESIÓN
//////////////////////////////////////////////////////////

extension DetalleCentroImpresionView {

    func registrarImpresion(tipo: String) {

        let usuarioActual = UIDevice.current.name

        let nuevoRegistro = RegistroImpresion(
            idReferencia: idReferencia,
            fecha: Date(),
            usuario: usuarioActual,
            tipo: tipo
        )

        context.insert(nuevoRegistro)

        do {
            try context.save()
            print("✅ REGISTRO GUARDADO ->", idReferencia, tipo)
        } catch {
            print("❌ ERROR GUARDANDO REGISTRO:", error.localizedDescription)
        }

        // DEBUG: ver cuántos registros existen ahora
        let total = registrosImpresion.filter { $0.idReferencia == idReferencia }.count
        print("📦 Total registros para esta orden:", total)
    }
    }
