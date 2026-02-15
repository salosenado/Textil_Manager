//
//  VentaClienteExcelService.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//


import Foundation

enum VentaClienteExcelService {

    static func generarCSV(venta: VentaCliente) -> URL {

        var csv = "Modelo,Cantidad,Unidad,Costo Unitario,Subtotal\n"

        for d in venta.detalles where d.fechaEliminacion == nil {
            let subtotal = Double(d.cantidad) * d.costoUnitario
            csv += "\(d.modeloNombre),\(d.cantidad),\(d.unidad),\(d.costoUnitario),\(subtotal)\n"
        }

        let subtotal = venta.detalles
            .filter { $0.fechaEliminacion == nil }
            .reduce(0) { $0 + Double($1.cantidad) * $1.costoUnitario }

        let iva = venta.aplicaIVA ? subtotal * 0.16 : 0
        let total = subtotal + iva

        csv += "\nSubtotal,,,\(subtotal)\n"
        csv += "IVA,,,\(iva)\n"
        csv += "TOTAL,,,\(total)\n"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Venta_\(venta.folio).csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
