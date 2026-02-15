//
//  CuentasPorCobrarExportManager.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//


import Foundation
import UIKit

struct CuentasPorCobrarExportManager {

    static func textoReporte(_ reporte: CuentasPorCobrarReporte) -> String {

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return """
        RESUMEN CUENTAS POR COBRAR
        Generado: \(formatter.string(from: reporte.fechaGeneracion))

        Vigente: MX$ \(reporte.vigente.formatoMoneda)
        Semana actual: MX$ \(reporte.semanaActual.formatoMoneda)
        Próxima semana: MX$ \(reporte.semanaSiguiente.formatoMoneda)

        1-30 días: MX$ \(reporte.dias30.formatoMoneda)
        31-60 días: MX$ \(reporte.dias60.formatoMoneda)
        61-90 días: MX$ \(reporte.dias90.formatoMoneda)
        +90 días: MX$ \(reporte.mas90.formatoMoneda)

        ----------------------------------
        TOTAL GENERAL: MX$ \(reporte.totalGeneral.formatoMoneda)
        """
    }

    static func exportarPDF(_ reporte: CuentasPorCobrarReporte) -> URL? {

        let texto = textoReporte(reporte)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        let data = renderer.pdfData { context in
            context.beginPage()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]

            texto.draw(in: CGRect(x: 40, y: 40, width: 532, height: 712), withAttributes: attributes)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Resumen_CxC.pdf")

        try? data.write(to: url)

        return url
    }

    static func exportarExcel(_ reporte: CuentasPorCobrarReporte) -> URL? {

        let csv = """
        Concepto,Monto
        Vigente,\(reporte.vigente)
        Semana actual,\(reporte.semanaActual)
        Próxima semana,\(reporte.semanaSiguiente)
        1-30 días,\(reporte.dias30)
        31-60 días,\(reporte.dias60)
        61-90 días,\(reporte.dias90)
        +90 días,\(reporte.mas90)
        TOTAL,\(reporte.totalGeneral)
        """

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Resumen_CxC.csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)

        return url
    }

    static func imprimir(_ reporte: CuentasPorCobrarReporte) {

        guard let url = exportarPDF(reporte),
              let data = try? Data(contentsOf: url) else { return }

        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "Cuentas por Cobrar"
        printController.printInfo = printInfo
        printController.printingItem = data

        printController.present(animated: true)
    }
}
