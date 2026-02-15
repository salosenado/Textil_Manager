//
//  DetalleOrdenCompraView.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//
//
//  DetalleOrdenCompraView.swift
//  Textil
//

import SwiftUI
import SwiftData
import PencilKit

struct DetalleOrdenCompraView: View {

    let orden: OrdenCompra

    @Query private var empresas: [Empresa]
    @Query private var recibos: [ReciboCompraDetalle]
    @Query private var pagos: [PagoRecibo]
    @Query private var modelos: [Modelo]

    @State private var empresaSeleccionada: Empresa?

    @State private var nombreResponsable = ""
    @State private var nombreProveedor = ""

    @State private var mostrarFirmaProveedor = false
    @State private var mostrarFirmaResponsable = false

    @State private var firmaProveedor: UIImage?
    @State private var firmaResponsable: UIImage?

    @State private var pdfURL: URL?
    @State private var mostrarShare = false



    var body: some View {

        let recibidosOrden = recibos.filter {
            $0.ordenCompra == orden && $0.fechaEliminacion == nil
        }

        let pagosOrden = pagos.filter {
            $0.recibo?.ordenCompra == orden && $0.fechaEliminacion == nil
        }

        ScrollView {
            VStack(spacing: 22) {

                tarjeta {
                    HStack {
                        Text("Empresa").font(.headline)
                        Spacer()
                        Picker("", selection: $empresaSeleccionada) {
                            Text("Seleccionar").tag(nil as Empresa?)
                            ForEach(empresas) {
                                Text($0.nombre).tag(Optional($0))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.primary)
                    }
                }

                tarjeta {
                    VStack(spacing: 14) {
                        titulo("Orden de compra cliente")
                        Divider()
                        fila("Compra", orden.folio)
                        Divider()
                        fila("Fecha orden", fecha(orden.fechaOrden))
                        Divider()
                        fila("Fecha entrega", fecha(orden.fechaEntrega))
                        Divider()
                        fila("Proveedor", orden.proveedor)
                        Divider()
                        fila("IVA", orden.aplicaIVA ? "Aplica" : "No aplica")
                    }
                }

                tarjeta {
                    VStack(alignment: .leading, spacing: 14) {
                        titulo("Modelos pedidos")
                        ForEach(orden.detalles) { d in

                            // Buscar modelo real en catálogo
                            let modeloCatalogo = modelos.first {
                                $0.codigo == d.modelo || $0.nombre == d.modelo
                            }

                            let descripcion = modeloCatalogo?.descripcion ?? ""

                            VStack(alignment: .leading, spacing: 8) {

                                Text("Modelo: \(d.modelo)\(descripcion.isEmpty ? "" : " – \(descripcion)")")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                fila("Cantidad", "\(d.cantidad)")
                                fila("Costo unitario", dinero(d.costoUnitario))
                                fila("Subtotal", dinero(d.subtotal), color: .green)
                            }

                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                        }
                    }
                }

                tarjeta {
                    VStack(spacing: 14) {
                        titulo("Recibido")
                        ForEach(recibidosOrden) { r in
                            VStack(spacing: 8) {
                                fila("Fecha", fecha(r.recibo?.fechaRecibo ?? Date()))
                                Divider()
                                fila("Cantidad recibida", "\(Int(r.monto))", color: .green)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                        }
                    }
                }

                tarjeta {
                    VStack(spacing: 14) {
                        titulo("Pagos")
                        ForEach(Array(pagosOrden.enumerated()), id: \.element.id) { index, p in
                            VStack {
                                HStack {
                                    Text("Pago \(index + 1)")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                HStack {
                                    Text(fecha(p.fechaPago))
                                    Spacer()
                                    Text(dinero(p.monto))
                                        .foregroundStyle(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(14)
                        }
                    }
                }

                tarjeta {
                    VStack(spacing: 14) {
                        titulo("Responsables")
                        TextField("Nombre responsable", text: $nombreResponsable)
                            .textFieldStyle(.roundedBorder)
                        TextField("Nombre proveedor / agente", text: $nombreProveedor)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                tarjeta {
                    VStack(spacing: 0) {
                        titulo("Firmas").padding(.bottom, 12)

                        Button { mostrarFirmaProveedor = true } label: {
                            filaFirma("Firmar proveedor", firmaProveedor)
                        }

                        Divider()

                        Button { mostrarFirmaResponsable = true } label: {
                            filaFirma("Firmar responsable", firmaResponsable)
                        }
                    }
                }

                tarjeta {
                    VStack(spacing: 0) {
                        titulo("Imprimir").padding(.bottom, 12)

                        Button { imprimir(.todo) } label: { filaAccion("Imprimir todo") }
                        Divider()
                        Button { imprimir(.orden) } label: { filaAccion("Imprimir orden") }
                        Divider()
                        Button { imprimir(.recibido) } label: { filaAccion("Imprimir recibido") }
                        Divider()
                        Button { imprimir(.pagos) } label: { filaAccion("Imprimir pagos") }
                    }
                }

                Color.clear.frame(height: 80)
            }
            .padding()
        }
        .navigationTitle("Detalle compra cliente")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))

        .sheet(isPresented: $mostrarFirmaProveedor) {
            VistaFirma { firmaProveedor = $0 }
        }
        .sheet(isPresented: $mostrarFirmaResponsable) {
            VistaFirma { firmaResponsable = $0 }
        }
        .sheet(isPresented: $mostrarShare) {
            if let url = pdfURL {
                ShareSheet(activityItems: [url])
            }
        }
    }   // ← ESTE CIERRA EL BODY


    // MARK: PDF

    enum Tipo { case todo, orden, recibido, pagos }

    func imprimir(_ tipo: Tipo) {

        let empresa = empresaSeleccionada ?? empresas.first

        guard let empresaFinal = empresa else {
            print("No hay empresa disponible")
            return
        }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 1000))

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 20

            y = dibujarEncabezado(empresaFinal, y)

            switch tipo {
            case .todo:
                y = dibujarOrden(y)
                y = dibujarRecibido(y)
                y = dibujarPagos(y)
            case .orden:
                y = dibujarOrden(y)
            case .recibido:
                y = dibujarRecibido(y)
            case .pagos:
                y = dibujarPagos(y)
            }

            y = dibujarFirmas(y)
            dibujarPie()
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Documento.pdf")

        try? data.write(to: tempURL)

        pdfURL = tempURL
        mostrarShare = true
    }


    // MARK: ENCABEZADO EMPRESA

    func dibujarEncabezado(_ empresa: Empresa, _ y: CGFloat) -> CGFloat {

        var currentY = y

        // LOGO
        if let logoData = empresa.logoData,
           let image = UIImage(data: logoData) {
            image.draw(in: CGRect(x: 430, y: currentY, width: 140, height: 70))
        }

        // NOMBRE EMPRESA
        (empresa.nombre as NSString).draw(
            at: CGPoint(x: 20, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 22)]
        )

        currentY += 28

        if !empresa.direccion.isEmpty {
            (empresa.direccion as NSString).draw(
                at: CGPoint(x: 20, y: currentY),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
            currentY += 18
        }

        if !empresa.telefono.isEmpty {
            ("Tel: \(empresa.telefono)" as NSString).draw(
                at: CGPoint(x: 20, y: currentY),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
            currentY += 18
        }

        // LINEA DIVISORIA
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 20, y: currentY + 10))
        path.addLine(to: CGPoint(x: 590, y: currentY + 10))
        path.lineWidth = 1
        UIColor.black.setStroke()
        path.stroke()

        return currentY + 25
    }


    // MARK: ORDEN

    func dibujarOrden(_ y: CGFloat) -> CGFloat {

        var currentY = y

        let titulo = "ORDEN DE COMPRA"
        let tituloSize = titulo.size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])

        (titulo as NSString).draw(
            at: CGPoint(x: (612 - tituloSize.width) / 2, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)]
        )

        currentY += 35

        let datos = [
            "Folio: \(orden.folio)",
            "Proveedor: \(orden.proveedor)",
            "Fecha orden: \(fecha(orden.fechaOrden))",
            "Fecha entrega: \(fecha(orden.fechaEntrega))"
        ]

        for dato in datos {
            (dato as NSString).draw(
                at: CGPoint(x: 20, y: currentY),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )
            currentY += 18
        }

        currentY += 20

        ("Detalle:" as NSString).draw(
            at: CGPoint(x: 20, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14)]
        )

        currentY += 20

        for d in orden.detalles {

            let modeloCatalogo = modelos.first {
                $0.codigo == d.modelo || $0.nombre == d.modelo
            }

            let descripcion = modeloCatalogo?.descripcion ?? ""

            let linea = """
        Modelo: \(d.modelo)\(descripcion.isEmpty ? "" : " – \(descripcion)")
        Cantidad: \(d.cantidad) pz    Precio unitario: \(dinero(d.costoUnitario))    Subtotal: \(dinero(d.subtotal))
        """

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            let boundingRect = (linea as NSString).boundingRect(
                with: CGSize(width: 550, height: CGFloat.greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: attributes,
                context: nil
            )

            (linea as NSString).draw(
                in: CGRect(x: 30, y: currentY, width: 550, height: boundingRect.height),
                withAttributes: attributes
            )

            currentY += boundingRect.height + 12
        }

        return currentY + 20
    }


    // MARK: RECIBIDO

    func dibujarRecibido(_ y: CGFloat) -> CGFloat {

        var currentY = y

        ("RECIBIDO" as NSString).draw(
            at: CGPoint(x: 20, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)]
        )

        currentY += 25

        for r in recibos.filter({ $0.ordenCompra == orden && $0.fechaEliminacion == nil }) {

            let linea = "Fecha: \(fecha(r.recibo?.fechaRecibo ?? Date()))   Cantidad: \(Int(r.monto))"

            (linea as NSString).draw(
                at: CGPoint(x: 30, y: currentY),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )

            currentY += 18
        }

        return currentY + 20
    }


    // MARK: PAGOS

    func dibujarPagos(_ y: CGFloat) -> CGFloat {

        var currentY = y

        ("PAGOS" as NSString).draw(
            at: CGPoint(x: 20, y: currentY),
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)]
        )

        currentY += 25

        for (index, p) in pagos
            .filter({ $0.recibo?.ordenCompra == orden && $0.fechaEliminacion == nil })
            .enumerated() {

            let linea = "Pago \(index + 1)   \(fecha(p.fechaPago))   \(dinero(p.monto))"

            (linea as NSString).draw(
                at: CGPoint(x: 30, y: currentY),
                withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
            )

            currentY += 18
        }

        return currentY + 20
    }


    // MARK: FIRMAS

    func dibujarFirmas(_ y: CGFloat) -> CGFloat {

        var currentY = y + 60

        // LINEAS
        let path1 = UIBezierPath()
        path1.move(to: CGPoint(x: 50, y: currentY))
        path1.addLine(to: CGPoint(x: 250, y: currentY))
        path1.stroke()

        let path2 = UIBezierPath()
        path2.move(to: CGPoint(x: 350, y: currentY))
        path2.addLine(to: CGPoint(x: 550, y: currentY))
        path2.stroke()

        // DIBUJAR IMÁGENES DE FIRMA
        if let firmaR = firmaResponsable {
            firmaR.draw(in: CGRect(x: 70, y: currentY - 50, width: 160, height: 50))
        }

        if let firmaP = firmaProveedor {
            firmaP.draw(in: CGRect(x: 370, y: currentY - 50, width: 160, height: 50))
        }

        currentY += 10

        // NOMBRES CON ETIQUETA
        let textoResponsable = "Responsable: \(nombreResponsable)"
        let textoProveedor = "Proveedor / Agente: \(nombreProveedor)"

        (textoResponsable as NSString).draw(
            at: CGPoint(x: 50, y: currentY),
            withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
        )

        (textoProveedor as NSString).draw(
            at: CGPoint(x: 350, y: currentY),
            withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
        )

        return currentY + 40
    }


    // MARK: PIE

    func dibujarPie() {

        let texto = "Documento generado por Sistema Textil"
        let size = texto.size(withAttributes: [.font: UIFont.systemFont(ofSize: 10)])

        (texto as NSString).draw(
            at: CGPoint(x: (612 - size.width) / 2, y: 960),
            withAttributes: [.font: UIFont.systemFont(ofSize: 10)]
        )
    }

    // MARK: UI Helpers

    func tarjeta<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack { content() }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.06), radius: 10)
    }

    func titulo(_ t: String) -> some View {
        Text(t).font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func fila(_ t: String, _ v: String, color: Color = .secondary) -> some View {
        HStack { Text(t); Spacer(); Text(v).foregroundStyle(color) }
    }

    func filaFirma(_ texto: String, _ imagen: UIImage?) -> some View {
        HStack {
            Text(texto).foregroundColor(.blue)
            Spacer()
            if let img = imagen {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(width: 80, height: 40)
            }
        }.padding(.vertical, 14)
    }

    func filaAccion(_ texto: String) -> some View {
        HStack { Text(texto).foregroundColor(.blue); Spacer() }
            .padding(.vertical, 14)
    }

    func fecha(_ f: Date) -> String {
        f.formatted(.dateTime.day().month(.abbreviated).year())
    }

    func dinero(_ v: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        return formatter.string(from: NSNumber(value: v)) ?? "$0.00"
    }
}

// MARK: Firma

struct VistaFirma: View {
    var onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PKCanvasView()

    var body: some View {
        NavigationStack {
            CanvasRepresentable(canvas: $canvas)
                .navigationTitle("Firmar")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Guardar") {
                            let img = canvas.drawing.image(from: canvas.bounds, scale: 1)
                            onSave(img)
                            dismiss()
                        }
                    }
                }
        }
    }
}

struct CanvasRepresentable: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        return canvas
    }
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
