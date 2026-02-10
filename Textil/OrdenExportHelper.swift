//
//  OrdenExportHelper.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//


import SwiftUI
import UIKit

struct OrdenExportHelper {

    // MARK: - EXPORTAR CSV (EXCEL)
    static func exportarCSV(orden: OrdenCliente) -> URL? {

        var csv = "Proveedor,Pedido,Fecha Pedido,Fecha Entrega,Modelo,Descripción,Cantidad,Precio Unitario,Subtotal\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for d in orden.detalles {
            let row = """
            \(orden.cliente),\
            \(orden.numeroPedidoCliente),\
            \(dateFormatter.string(from: orden.fechaCreacion)),\
            \(dateFormatter.string(from: orden.fechaEntrega)),\
            \(d.modelo),\
            \(d.articulo),\
            \(d.cantidad),\
            \(d.precioUnitario),\
            \(d.subtotal)
            \n
            """
            csv.append(row)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Orden_\(orden.numeroPedidoCliente).csv")

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error CSV:", error)
            return nil
        }
    }

    // MARK: - EXPORTAR PDF
    static func exportarPDF(orden: OrdenCliente) -> URL? {

        let format = UIGraphicsPDFRendererFormat()
        let page = CGRect(x: 0, y: 0, width: 612, height: 792) // Carta
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Orden_\(orden.numeroPedidoCliente).pdf")

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()

                var y: CGFloat = 20

                func draw(_ text: String, size: CGFloat = 12, bold: Bool = false) {
                    let font = bold
                        ? UIFont.boldSystemFont(ofSize: size)
                        : UIFont.systemFont(ofSize: size)

                    let attrs: [NSAttributedString.Key: Any] = [.font: font]
                    text.draw(at: CGPoint(x: 20, y: y), withAttributes: attrs)
                    y += size + 6
                }

                draw("ORDEN DE CLIENTE", size: 18, bold: true)
                y += 10

                draw("Proveedor: \(orden.cliente)")
                draw("Pedido: \(orden.numeroPedidoCliente)")
                draw("Fecha pedido: \(orden.fechaCreacion.formatted(date: .abbreviated, time: .omitted))")
                draw("Fecha entrega: \(orden.fechaEntrega.formatted(date: .abbreviated, time: .omitted))")

                y += 10
                draw("DETALLE", bold: true)
                y += 6

                for d in orden.detalles {
                    draw("Modelo: \(d.modelo)")
                    draw(d.articulo)
                    draw("Cantidad: \(d.cantidad)  Precio: \(d.precioUnitario)  Subtotal: \(d.subtotal)")
                    y += 6
                }

                y += 10
                draw("TOTAL: MX $ \(String(format: "%.2f", orden.total))", bold: true)
            }
            return url
        } catch {
            print("Error PDF:", error)
            return nil
        }
    }

    // MARK: - COMPARTIR / IMPRIMIR
    static func compartir(url: URL) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}
