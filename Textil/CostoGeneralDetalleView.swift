//
//  CostoGeneralDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI
import UIKit

struct CostoGeneralDetalleView: View {

    let costo: CostoGeneralEntity

    @State private var mostrarShare = false
    @State private var itemsShare: [Any] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                encabezado
                seccionTelas
                seccionInsumos
                seccionTotales
                seccionAcciones
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle del Costo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $mostrarShare) {
            ActivityView(items: itemsShare) // ← usa el que YA EXISTE
        }
    }

    // MARK: - ENCABEZADO
    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(costo.modelo)
                .font(.title2)
                .fontWeight(.bold)

            if !costo.descripcion.isEmpty {
                Text(costo.descripcion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(
                "Fecha captura: \(costo.fecha.formatted(.dateTime.day().month(.abbreviated).year()))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    // MARK: - TELAS
    private var seccionTelas: some View {
        Group {
            if !costo.telas.isEmpty {
                tarjeta("Telas") {
                    ForEach(costo.telas) { tela in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(tela.nombre).fontWeight(.medium)
                            fila("Consumo", tela.consumo)
                            filaMoneda("Precio", tela.precioUnitario)
                            filaMoneda("Total", tela.total, bold: true)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    // MARK: - INSUMOS
    private var seccionInsumos: some View {
        Group {
            if !costo.insumos.isEmpty {
                tarjeta("Insumos / Procesos") {
                    ForEach(costo.insumos) { insumo in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(insumo.nombre).fontWeight(.medium)
                            fila("Cantidad", insumo.cantidad)
                            filaMoneda("Costo", insumo.costoUnitario)
                            filaMoneda("Total", insumo.total, bold: true)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    // MARK: - TOTALES
    private var seccionTotales: some View {
        tarjeta("Totales") {
            filaMoneda("Total", costo.total, bold: true)
            filaMoneda(
                "Total con gastos (15%)",
                costo.totalConGastos,
                bold: true,
                color: .green
            )
        }
    }

    // MARK: - ACCIONES
    private var seccionAcciones: some View {
        VStack(spacing: 12) {

            boton("Exportar PDF", "doc.richtext", .red) {
                exportarPDF()
            }

            boton("Exportar Excel", "tablecells", .green) {
                exportarExcel()
            }

            boton("Imprimir", "printer", .blue) {
                imprimir()
            }
        }
        .padding(.top)
    }

    // MARK: - HELPERS UI
    private func tarjeta<Content: View>(
        _ titulo: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titulo).font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private func fila(_ titulo: String, _ valor: Double) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(String(format: "%.2f", valor))
                .foregroundStyle(.secondary)
        }
    }

    private func filaMoneda(
        _ titulo: String,
        _ valor: Double,
        bold: Bool = false,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(titulo)
                .fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(valor, format: .currency(code: "MXN"))
                .fontWeight(bold ? .bold : .regular)
                .foregroundStyle(color)
        }
    }

    private func boton(
        _ titulo: String,
        _ icono: String,
        _ color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icono)
                Text(titulo).fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - FUNCIONALIDAD REAL (SIN AMBIGÜEDADES)

    /// PDF REAL (UIGraphicsPDFRenderer)
    private func exportarPDF() {
        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("CostoGeneral.pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))

        try? renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            let host = UIHostingController(
                rootView: ScrollView {
                    VStack {
                        encabezado
                        seccionTelas
                        seccionInsumos
                        seccionTotales
                    }
                    .padding()
                }
            )
            host.view.frame = ctx.pdfContextBounds
            host.view.drawHierarchy(in: ctx.pdfContextBounds, afterScreenUpdates: true)
        }

        itemsShare = [url]
        mostrarShare = true
    }

    /// EXCEL REAL (CSV compatible con Excel)
    private func exportarExcel() {
        var csv = "Concepto,Valor\n"

        costo.telas.forEach { csv += "\($0.nombre),\($0.total)\n" }
        costo.insumos.forEach { csv += "\($0.nombre),\($0.total)\n" }
        csv += "TOTAL,\(costo.totalConGastos)\n"

        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("CostoGeneral.xlsx")

        try? csv.data(using: .utf8)?.write(to: url)

        itemsShare = [url]
        mostrarShare = true
    }

    /// IMPRIMIR REAL (AirPrint)
    private func imprimir() {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Costo General"

        controller.printInfo = info

        let view = UIHostingController(
            rootView: ScrollView {
                VStack {
                    encabezado
                    seccionTelas
                    seccionInsumos
                    seccionTotales
                }
                .padding()
            }
        ).view!

        controller.printFormatter = view.viewPrintFormatter()
        controller.present(animated: true)
    }
}
