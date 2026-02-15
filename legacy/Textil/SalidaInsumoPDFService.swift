//
//  SalidaInsumoPDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
import UIKit
import SwiftData

enum SalidaInsumoPDFService {

    static func generarPDF(
        salida: SalidaInsumo,
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
            // DATOS DE LA SALIDA
            // =====================================================

            draw("SALIDA DE INSUMOS", size: 16, bold: true)
            draw("Folio: \(salida.folio)")
            draw("Cliente: \(salida.cliente?.nombreComercial ?? "—")")
            draw("Factura / Nota: \(salida.facturaNota.isEmpty ? "—" : salida.facturaNota)")
            draw("Fecha: \(salida.fecha.formatted())")

            y += 14

            // =====================================================
            // DETALLE DE INSUMOS
            // =====================================================

            draw("DETALLE DE INSUMOS", bold: true)

            for d in salida.detalles {

                let nombre = d.esServicio
                    ? (d.nombreServicio ?? "Servicio")
                    : (d.modeloNombre ?? "Insumo")

                draw(nombre, bold: true)
                draw("Cantidad: \(d.cantidad)")
                draw("Costo unitario: MX $ \(String(format: "%.2f", d.costoUnitario))")

                let subtotal = Double(d.cantidad) * d.costoUnitario
                draw("Subtotal: MX $ \(String(format: "%.2f", subtotal))")

                y += 6
            }

            y += 10

            // =====================================================
            // RESUMEN MONETARIO
            // =====================================================

            let subtotal = salida.detalles.reduce(0) {
                $0 + Double($1.cantidad) * $1.costoUnitario
            }

            let iva = salida.aplicaIVA ? subtotal * 0.16 : 0
            let total = subtotal + iva

            draw("RESUMEN MONETARIO", bold: true)
            draw("Subtotal: MX $ \(String(format: "%.2f", subtotal))")
            draw("IVA (16%): MX $ \(String(format: "%.2f", iva))")
            draw("TOTAL: MX $ \(String(format: "%.2f", total))", size: 14, bold: true)

            y += 20

            // =====================================================
            // FIRMAS
            // =====================================================

            draw("ENTREGA", bold: true)

            let firmaEntregaY = y

            if let data = salida.firmaEntrega,
               let img = UIImage(data: data) {
                img.draw(
                    in: CGRect(
                        x: margin,
                        y: firmaEntregaY,
                        width: 160,
                        height: 70
                    )
                )
            }

            // Texto claramente debajo de la firma
            y = firmaEntregaY + 90

            let nombreEntrega =
                salida.responsable.isEmpty
                ? "—"
                : salida.responsable

            draw("Nombre: \(nombreEntrega)")

            y += 40

            draw("RECIBE", bold: true)

            let firmaRecibeY = y

            if let data = salida.firmaRecibe,
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

            let nombreRecibe =
                salida.recibeMaterial.isEmpty
                ? "—"
                : salida.recibeMaterial

            draw("Nombre: \(nombreRecibe)")

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
