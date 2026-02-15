//
//  CxPPDFService.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//

//
//  CxPPDFService.swift
//  Textil
//

import UIKit

struct CxPPDFService {

    static func generarPDF(
        proveedor: String,
        recibos: [ReciboCompra]
    ) -> Data {

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in

            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]

            let normalAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            let moneyFormatter = NumberFormatter()
            moneyFormatter.numberStyle = .currency
            moneyFormatter.currencySymbol = "MX$ "
            moneyFormatter.maximumFractionDigits = 2

            // 🔹 TÍTULO
            let titulo = "Estado de Cuenta - \(proveedor)"
            titulo.draw(at: CGPoint(x: 20, y: 20), withAttributes: titleAttributes)

            var y: CGFloat = 60

            for recibo in recibos {

                let subtotal = recibo.orden.detalles.reduce(0) {
                    $0 + $1.subtotal
                }

                let total = recibo.orden.aplicaIVA
                    ? subtotal * 1.16
                    : subtotal

                let pagado = recibo.pagos.reduce(0) {
                    $0 + $1.monto
                }

                let saldo = total - pagado

                let totalStr = moneyFormatter.string(from: NSNumber(value: total)) ?? "0"
                let pagadoStr = moneyFormatter.string(from: NSNumber(value: pagado)) ?? "0"
                let saldoStr = moneyFormatter.string(from: NSNumber(value: saldo)) ?? "0"

                let fechaStr = recibo.fechaRecibo.formatted(
                    date: .numeric,
                    time: .omitted
                )

                let texto = """
                \(recibo.orden.folio) | Fecha: \(fechaStr)
                Total: \(totalStr)
                Pagado: \(pagadoStr)
                Saldo: \(saldoStr)
                """

                texto.draw(
                    in: CGRect(x: 20, y: y, width: 560, height: 80),
                    withAttributes: normalAttributes
                )

                y += 80

                // 🔹 Salto de página automático
                if y > 720 {
                    context.beginPage()
                    y = 20
                }
            }
        }
    }
}
