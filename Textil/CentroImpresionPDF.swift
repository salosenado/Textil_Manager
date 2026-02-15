//
//  CentroImpresionPDF.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//
//
//  CentroImpresionPDF.swift
//  Textil
//

import UIKit

struct CentroImpresionPDF {

    static func generarPDF(
        titulo: String,
        empresa: Empresa?,
        tipo: String,
        folio: String,
        clienteProveedor: String,
        fechaOrden: String,
        fechaEntrega: String,
        modelos: [String],
        responsable: String,
        proveedorFirma: String,
        firmaResponsable: UIImage?,
        firmaProveedor: UIImage?
    ) -> URL? {

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            let margin: CGFloat = 40
            var y: CGFloat = 40
            let contentWidth = pageRect.width - (margin * 2)

            let tituloAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]

            let normalAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            let boldAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 13)
            ]

            // 🔷 LOGO
            if let logoData = empresa?.logoData,
               let logo = UIImage(data: logoData) {

                logo.draw(in: CGRect(x: margin, y: y, width: 80, height: 80))
            }

            // 🔷 DATOS EMPRESA
            var empresaY = y

            if let empresa = empresa {

                empresa.nombre.draw(
                    at: CGPoint(x: margin + 100, y: empresaY),
                    withAttributes: tituloAttr
                )

                empresaY += 22

                empresa.direccion.draw(
                    at: CGPoint(x: margin + 100, y: empresaY),
                    withAttributes: normalAttr
                )

                empresaY += 18

                empresa.telefono.draw(
                    at: CGPoint(x: margin + 100, y: empresaY),
                    withAttributes: normalAttr
                )

                empresaY += 18

                empresa.rfc.draw(
                    at: CGPoint(x: margin + 100, y: empresaY),
                    withAttributes: normalAttr
                )
            }

            y += 110

            // Línea divisoria
            context.cgContext.move(to: CGPoint(x: margin, y: y))
            context.cgContext.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
            context.cgContext.strokePath()

            y += 25

            // 🔷 TÍTULO DOCUMENTO
            titulo.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: tituloAttr
            )

            y += 30

            // 🔷 INFORMACIÓN GENERAL
            drawLine("Tipo:", tipo, margin, &y, boldAttr, normalAttr)
            drawLine("Folio:", folio, margin, &y, boldAttr, normalAttr)

            let etiquetaTercero: String

            if tipo == "Producción" {
                etiquetaTercero = "Maquilero:"
            } else if tipo == "Servicio" {
                etiquetaTercero = "Proveedor:"
            } else {
                etiquetaTercero = "Proveedor:"
            }


            drawLine(etiquetaTercero, clienteProveedor, margin, &y, boldAttr, normalAttr)

            drawLine("Fecha Orden:", fechaOrden, margin, &y, boldAttr, normalAttr)
            drawLine("Fecha Entrega:", fechaEntrega, margin, &y, boldAttr, normalAttr)


            y += 20

            // 🔷 DETALLE
            "DETALLE".draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttr)
            y += 20

            for modelo in modelos {

                let textRect = CGRect(
                    x: margin,
                    y: y,
                    width: contentWidth,
                    height: 200   // 👈 más espacio
                )

                modelo.draw(
                    with: textRect,
                    options: .usesLineFragmentOrigin,
                    attributes: normalAttr,
                    context: nil
                )

                y += 120   // 👈 aumentar salto

                if y > 720 {
                    context.beginPage()
                    y = 40
                }
            }

            y += 30

            // 🔷 FIRMAS

            drawLine("Responsable:", responsable, margin, &y, boldAttr, normalAttr)
            y += 40

            if let firma1 = firmaResponsable {
                firma1.draw(in: CGRect(x: margin, y: y, width: 180, height: 70))
            }

            y += 100

            y += 40

            if let firma2 = firmaProveedor {
                firma2.draw(in: CGRect(x: margin, y: y, width: 180, height: 70))
            }

            y += 80

            let footer = "Documento generado el \(Date().formatted(date: .long, time: .omitted))"

            footer.draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: normalAttr
            )
        }

        let url = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("CentroImpresionCompleto.pdf")

        try? data.write(to: url)

        return url
    }

    private static func drawLine(
        _ label: String,
        _ value: String,
        _ margin: CGFloat,
        _ y: inout CGFloat,
        _ boldAttr: [NSAttributedString.Key: Any],
        _ normalAttr: [NSAttributedString.Key: Any]
    ) {

        label.draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttr)

        let labelWidth = label.size(withAttributes: boldAttr).width

        value.draw(
            at: CGPoint(x: margin + labelWidth + 5, y: y),
            withAttributes: normalAttr
        )

        y += 18
    }
}
