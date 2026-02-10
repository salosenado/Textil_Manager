//
//  VentaClientePDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
import UIKit
import SwiftData

enum VentaClientePDFService {

    static func generarPDF(
        venta: VentaCliente,
        empresa: Empresa?
    ) -> Data {

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()

            let margin: CGFloat = 40
            let pageWidth = pageRect.width
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
                    in: CGRect(
                        x: margin,
                        y: y,
                        width: 100,
                        height: 50
                    )
                )
            }

            y += 60

            draw(empresa?.nombre ?? venta.empresa, size: 18, bold: true)
            draw("RFC: \(empresa?.rfc ?? "—")")
            draw("Dirección: \(empresa?.direccion ?? "—")")
            draw("Teléfono: \(empresa?.telefono ?? "—")")

            y += 10

            // =====================================================
            // DATOS DE LA VENTA
            // =====================================================

            draw("VENTA A CLIENTE", size: 16, bold: true)
            draw("Folio: \(venta.folio)")
            draw("Cliente: \(venta.cliente.nombreComercial)")
            draw("Agente: \(venta.agente?.nombre ?? "") \(venta.agente?.apellido ?? "")")
            draw("Factura: \(venta.numeroFactura)")
            draw("Fecha venta: \(venta.fechaVenta.formatted())")
            draw("Fecha entrega: \(venta.fechaEntrega.formatted())")

            if venta.cancelada {
                y += 4
                draw("ESTADO: CANCELADA", bold: true)
            }

            y += 14

            // =====================================================
            // DETALLE DE MODELOS
            // =====================================================

            draw("DETALLE DE MODELOS", bold: true)

            for d in venta.detalles where d.fechaEliminacion == nil {

                draw("Modelo: \(d.modeloNombre)", bold: true)
                draw("Cantidad: \(d.cantidad) \(d.unidad)")
                draw("Precio unitario: MX $ \(String(format: "%.2f", d.costoUnitario))")

                let subtotalModelo = Double(d.cantidad) * d.costoUnitario
                draw("Subtotal modelo: MX $ \(String(format: "%.2f", subtotalModelo))")

                y += 6
            }

            y += 10

            // =====================================================
            // RESUMEN MONETARIO
            // =====================================================

            let subtotal = venta.detalles
                .filter { $0.fechaEliminacion == nil }
                .reduce(0) { $0 + Double($1.cantidad) * $1.costoUnitario }

            let iva = venta.aplicaIVA ? subtotal * 0.16 : 0
            let total = subtotal + iva

            draw("RESUMEN MONETARIO", bold: true)
            draw("Subtotal: MX $ \(String(format: "%.2f", subtotal))")
            draw("IVA (16%): MX $ \(String(format: "%.2f", iva))")
            draw("TOTAL: MX $ \(String(format: "%.2f", total))", size: 14, bold: true)

            y += 20

            // =====================================================
            // FIRMAS
            // =====================================================

            draw("RESPONSABLE DE LA VENTA", bold: true)

            if let data = venta.firmaResponsable,
               let img = UIImage(data: data) {
                img.draw(
                    in: CGRect(x: margin, y: y, width: 160, height: 70)
                )
            }

            y += 76
            draw("Nombre: \(venta.nombreResponsableVenta)")

            y += 14

            draw("AGENTE DE VENTAS", bold: true)

            if let data = venta.firmaAgente,
               let img = UIImage(data: data) {
                img.draw(
                    in: CGRect(x: margin, y: y, width: 160, height: 70)
                )
            }

            y += 76
            draw("Nombre: \(venta.nombreAgenteVenta)")

            y += 30

            // =====================================================
            // PIE DE PÁGINA
            // =====================================================

            let footerY = pageRect.height - 40
            let footerText =
                "Documento generado el \(Date().formatted()) | Sistema Textil"

            footerText.draw(
                at: CGPoint(x: margin, y: footerY),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.gray
                ]
            )
        }
    }
}
