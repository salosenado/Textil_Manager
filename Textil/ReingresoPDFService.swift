//
//  ReingresoPDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ReingresoPDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ReingresoPDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import UIKit
import SwiftData

enum ReingresoPDFService {

    static func generarPDF(
        reingreso: Reingreso,
        empresa: Empresa?
    ) -> Data {

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()

            let margin: CGFloat = 40
            var y: CGFloat = margin

            func draw(
                _ text: String,
                x: CGFloat = margin,
                size: CGFloat = 12,
                bold: Bool = false
            ) {
                let font = bold
                    ? UIFont.boldSystemFont(ofSize: size)
                    : UIFont.systemFont(ofSize: size)

                text.draw(
                    at: CGPoint(x: x, y: y),
                    withAttributes: [.font: font]
                )
                y += size + 6
            }

            // =====================================================
            // ENCABEZADO (LOGO + EMPRESA)
            // =====================================================

            if let data = empresa?.logoData,
               let img = UIImage(data: data) {

                img.draw(
                    in: CGRect(x: margin, y: y, width: 100, height: 50)
                )
            }

            y += 60

            draw(empresa?.nombre ?? "Empresa", size: 18, bold: true)
            draw("RFC: \(empresa?.rfc ?? "—")")
            draw("Dirección: \(empresa?.direccion ?? "—")")
            draw("Teléfono: \(empresa?.telefono ?? "—")")

            y += 10

            // =====================================================
            // DATOS DEL REINGRESO
            // =====================================================

            draw("REINGRESO DE INVENTARIO", size: 16, bold: true)
            draw("Folio: \(reingreso.folio)")
            draw("Cliente: \(reingreso.cliente?.nombreComercial ?? "—")")
            draw("Referencia / Nota: \(reingreso.referencia.isEmpty ? "—" : reingreso.referencia)")
            draw("Fecha: \(reingreso.fecha.formatted())")

            y += 14

            // =====================================================
            // DETALLE DE PRODUCTOS / SERVICIOS
            // =====================================================

            draw("DETALLE DE PRODUCTOS / SERVICIOS", bold: true)

            for d in reingreso.detalles {

                let nombre = d.esServicio
                    ? (d.nombreServicio ?? "Servicio")
                    : (d.modelo?.nombre ?? "Producto")

                draw(nombre, bold: true)

                // DESCRIPCIÓN SOLO MODELO
                if !d.esServicio,
                   let desc = d.modelo?.descripcion,
                   !desc.isEmpty {
                    draw(desc, size: 11)
                }

                draw("Cantidad: \(d.cantidad)")
                draw("Costo unitario: MX $ \(String(format: "%.2f", d.costoUnitario))")

                let subtotalDetalle = Double(d.cantidad) * d.costoUnitario
                draw("Subtotal: MX $ \(String(format: "%.2f", subtotalDetalle))")

                y += 6
            }

            y += 10

            // =====================================================
            // RESUMEN MONETARIO
            // =====================================================

            let subtotal = reingreso.detalles.reduce(0) {
                $0 + Double($1.cantidad) * $1.costoUnitario
            }

            let iva = reingreso.aplicaIVA ? subtotal * 0.16 : 0
            let total = subtotal + iva

            draw("RESUMEN MONETARIO", bold: true)
            draw("Subtotal: MX $ \(String(format: "%.2f", subtotal))")
            draw("IVA (16%): MX $ \(String(format: "%.2f", iva))")
            draw("TOTAL: MX $ \(String(format: "%.2f", total))", size: 14, bold: true)

            y += 20

            // =====================================================
            // FIRMAS
            // =====================================================

            draw("DEVUELVE", bold: true)

            let firmaDevuelveY = y

            if let data = reingreso.firmaDevuelve,
               let img = UIImage(data: data) {

                img.draw(
                    in: CGRect(
                        x: margin,
                        y: firmaDevuelveY,
                        width: 160,
                        height: 70
                    )
                )
            }

            y = firmaDevuelveY + 90
            draw("Nombre: \(reingreso.responsable.isEmpty ? "—" : reingreso.responsable)")

            y += 40

            draw("RECIBE", bold: true)

            let firmaRecibeY = y

            if let data = reingreso.firmaRecibe,
               let img = UIImage(data: data) {

                img.draw(
                    in: CGRect(
                        x: margin,
                        y: firmaRecibeY,
                        width: 160,
                        height: 70
                    )
                )
            }

            y = firmaRecibeY + 90
            draw("Nombre: \(reingreso.recibeMaterial.isEmpty ? "—" : reingreso.recibeMaterial)")

            // =====================================================
            // PIE DE PÁGINA
            // =====================================================

            let footerText =
                "Documento generado el \(Date().formatted()) | Sistema Textil"

            footerText.draw(
                at: CGPoint(x: margin, y: pageRect.height - 40),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.gray
                ]
            )
        }
    }
}
