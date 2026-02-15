//
//  ReingresoExcelService.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//


//
//  ReingresoExcelService.swift
//  Textil
//

import Foundation

enum ReingresoExcelService {

    static func generarCSV(reingreso: Reingreso) -> URL {

        var csv = "Tipo,Nombre,Cantidad,Costo Unitario,Subtotal\n"

        for d in reingreso.detalles {
            let tipo = d.esServicio ? "Servicio" : "Modelo"
            let nombre = d.esServicio
                ? d.nombreServicio ?? ""
                : d.modelo?.nombre ?? ""

            let subtotal = Double(d.cantidad) * d.costoUnitario

            csv += "\(tipo),\(nombre),\(d.cantidad),\(d.costoUnitario),\(subtotal)\n"
        }

        let subtotal = reingreso.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }

        let iva = reingreso.aplicaIVA ? subtotal * 0.16 : 0
        let total = subtotal + iva

        csv += "\nSubtotal,,,\(subtotal)\n"
        csv += "IVA,,,\(iva)\n"
        csv += "TOTAL,,,\(total)\n"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Reingreso_\(reingreso.folio).csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)

        return url
    }
}
