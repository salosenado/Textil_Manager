//
//  CxPExcelService.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import Foundation

struct CxPExcelService {

    static func generarCSV(
        proveedor: String,
        recibos: [ReciboCompra]
    ) -> URL {

        var csv = "Folio,Fecha,Total,Pagado,Saldo\n"

        for recibo in recibos {

            let subtotal = recibo.orden.detalles.reduce(0) { $0 + $1.subtotal }
            let total = recibo.orden.aplicaIVA ? subtotal * 1.16 : subtotal
            let pagado = recibo.pagos.reduce(0) { $0 + $1.monto }
            let saldo = total - pagado

            csv += "\(recibo.orden.folio),\(recibo.fechaRecibo),\(total),\(pagado),\(saldo)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CxP_\(proveedor).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
