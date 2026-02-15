//
//  SalidaInsumoExcelService.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//


//
//  SalidaInsumoExcelService.swift
//  Textil
//

import Foundation

struct SalidaInsumoExcelService {

    static func generarCSV(salida: SalidaInsumo) -> URL {

        var csv = "Salida de insumos\n\n"
        csv += "Folio,\(salida.folio)\n"
        csv += "Factura/Nota,\(salida.facturaNota)\n"
        csv += "Fecha,\(formatoFecha(salida.fecha))\n\n"

        csv += "Insumo, Cantidad, Costo Unitario, Subtotal\n"

        for d in salida.detalles {
            let nombre = d.esServicio
            ? (d.nombreServicio ?? "Servicio")
            : (d.modeloNombre ?? "Modelo")

            let subtotal = Double(d.cantidad) * d.costoUnitario

            csv += "\(nombre),\(d.cantidad),\(d.costoUnitario),\(subtotal)\n"
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Salida_\(salida.folio).csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func formatoFecha(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
