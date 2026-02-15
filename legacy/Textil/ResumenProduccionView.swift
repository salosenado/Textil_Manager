//
//  ResumenProduccionView.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//
//
//  ResumenProduccionView.swift
//  Textil
//
//  Created by Salomon Senado on 2/6/26.
//

import SwiftUI
import SwiftData
import UIKit

enum EstadoProduccion: String, CaseIterable, Identifiable {
    case todos = "Todos"
    case activas = "Activas"
    case completas = "Completas"
    case canceladas = "Canceladas"
    var id: String { rawValue }
}

struct ResumenProduccionView: View {

    @Query var producciones: [Produccion]

    // MARK: - Filtros
    @State private var textoBusqueda = ""
    @State private var estadoSeleccionado: EstadoProduccion = .todos
    @State private var maquileroSeleccionado = "Todos"
    @State private var modeloSeleccionado = "Todos"
    @State private var mesSeleccionado = "Todos"
    @State private var anioSeleccionado = "Todos"

    @State private var desde: Date = {
        Calendar.current.date(from: DateComponents(
            year: Calendar.current.component(.year, from: Date()),
            month: 1,
            day: 1
        ))!
    }()

    @State private var hasta: Date = Date()

    // MARK: - Exportación
    @State private var mostrarShare = false
    @State private var itemsExportar: [Any] = []

    private let umbralCompleta: Double = 0.95

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - FILTROS
                Section("Filtros") {

                    TextField("Buscar OM, maquilero o modelo", text: $textoBusqueda)

                    Picker("Estado", selection: $estadoSeleccionado) {
                        ForEach(EstadoProduccion.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }

                    Picker("Maquilero", selection: $maquileroSeleccionado) {
                        ForEach(listaMaquileros, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    Picker("Modelo", selection: $modeloSeleccionado) {
                        ForEach(listaModelos, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    Picker("Mes", selection: $mesSeleccionado) {
                        Text("Todos").tag("Todos")
                        ForEach(Calendar.current.monthSymbols, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    Picker("Año", selection: $anioSeleccionado) {
                        Text("Todos").tag("Todos")
                        ForEach(listaAnios, id: \.self) {
                            Text($0).tag($0)
                        }
                    }

                    DatePicker("Desde", selection: $desde, displayedComponents: .date)
                    DatePicker("Hasta", selection: $hasta, displayedComponents: .date)

                    Button(role: .destructive) {
                        limpiarFiltros()
                    } label: {
                        Text("Borrar filtros")
                    }
                }

                // MARK: - EXPORTAR
                Section("Exportar resumen por maquilero") {
                    HStack {
                        exportButton("PDF", .red) {
                            exportarPDF()
                        }
                        exportButton("Excel", .green) {
                            exportarExcelCSV()
                        }
                        exportButton("Imprimir", .blue) {
                            imprimirResumen()
                        }
                    }
                }

                // MARK: - RESUMEN
                Section("Resumen por maquilero") {
                    ForEach(resumenPorMaquilero) { resumen in
                        ResumenMaquileroCard(resumen: resumen)
                    }
                }

                Section("Órdenes de maquila") {
                    ForEach(produccionesFiltradas) { produccion in
                        NavigationLink {
                            ResumenProduccionDetalleView(produccion: produccion)
                        } label: {
                            ProduccionRow(produccion: produccion)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Producción")
            .sheet(isPresented: $mostrarShare) {
                ShareSheet(activityItems: itemsExportar)
            }
        }
    }

    // MARK: - ÓRDENES FILTRADAS
    private var produccionesFiltradas: [Produccion] {
        producciones.filter { prod in

            if !textoBusqueda.isEmpty {
                let t = textoBusqueda.lowercased()
                if !prod.maquilero.lowercased().contains(t),
                   !(prod.ordenMaquila?.lowercased().contains(t) ?? false) {
                    return false
                }
            }

            if let fecha = prod.fechaOrdenMaquila {
                if fecha < desde || fecha > hasta { return false }

                if mesSeleccionado != "Todos" {
                    let mesProd = Calendar.current.monthSymbols[
                        Calendar.current.component(.month, from: fecha) - 1
                    ]
                    if mesProd != mesSeleccionado { return false }
                }

                if anioSeleccionado != "Todos" {
                    let anioProd = String(Calendar.current.component(.year, from: fecha))
                    if anioProd != anioSeleccionado { return false }
                }
            }

            if maquileroSeleccionado != "Todos",
               prod.maquilero != maquileroSeleccionado {
                return false
            }

            if modeloSeleccionado != "Todos" {
                let modelos = prod.recibos.flatMap { $0.detalles.map { $0.modelo } }
                if !modelos.contains(modeloSeleccionado) {
                    return false
                }
            }

            let pedidas = prod.pzCortadas
            let recibidas = prod.recibos
                .filter { !$0.cancelado }
                .flatMap { $0.detalles }
                .reduce(0) { $0 + $1.pzPrimera + $1.pzSaldo }

            let porcentaje = pedidas > 0 ? Double(recibidas) / Double(pedidas) : 0

            switch estadoSeleccionado {
            case .activas:
                return !prod.cancelada && porcentaje < umbralCompleta
            case .completas:
                return !prod.cancelada && porcentaje >= umbralCompleta
            case .canceladas:
                return prod.cancelada
            case .todos:
                return true
            }
        }
    }

    // MARK: - RESUMEN (SIN %)
    private var resumenPorMaquilero: [ResumenMaquilero] {

        let base = maquileroSeleccionado == "Todos"
            ? producciones
            : producciones.filter { $0.maquilero == maquileroSeleccionado }

        let agrupadas = Dictionary(grouping: base) { $0.maquilero }
        var resultado: [ResumenMaquilero] = []

        for (maquilero, items) in agrupadas {

            var pzPedidas = 0
            var pzRecibidas = 0
            var pagado = 0.0
            var ordenesCerradas = 0

            for prod in items where !prod.cancelada {

                pzPedidas += prod.pzCortadas

                var recibidasOrden = 0

                for recibo in prod.recibos where !recibo.cancelado {

                    for d in recibo.detalles where d.fechaEliminacion == nil {
                        recibidasOrden += d.pzPrimera + d.pzSaldo
                    }

                    for p in recibo.pagos where p.fechaEliminacion == nil {
                        pagado += p.monto
                    }
                }

                pzRecibidas += recibidasOrden

                if Double(recibidasOrden) / Double(max(prod.pzCortadas, 1)) >= umbralCompleta {
                    ordenesCerradas += 1
                }
            }

            let costoRecibido = Double(pzRecibidas) * (items.first?.costoMaquila ?? 0)

            resultado.append(
                ResumenMaquilero(
                    maquilero: maquilero,
                    ordenesPedidas: items.count,
                    ordenesEntregadas: ordenesCerradas,
                    pzPedidas: pzPedidas,
                    pzRecibidas: pzRecibidas,
                    pagado: pagado,
                    pendiente: max(costoRecibido - pagado, 0)
                )
            )
        }

        return resultado
    }

    // MARK: - EXPORT BOTÓN
    private func exportButton(
        _ title: String,
        _ color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func exportarPDF() {

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = renderer.pdfData { context in
            context.beginPage()

            let ctx = context.cgContext
            var y: CGFloat = margin

            let titleFont = UIFont.boldSystemFont(ofSize: 22)
            let subtitleFont = UIFont.systemFont(ofSize: 12)
            let headerFont = UIFont.boldSystemFont(ofSize: 11)
            let rowFont = UIFont.systemFont(ofSize: 11)
            let footerFont = UIFont.systemFont(ofSize: 9)

            func drawText(
                _ text: String,
                x: CGFloat,
                y: CGFloat,
                width: CGFloat,
                font: UIFont,
                align: NSTextAlignment = .left,
                color: UIColor = .black
            ) {
                let style = NSMutableParagraphStyle()
                style.alignment = align

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: style,
                    .foregroundColor: color
                ]

                text.draw(in: CGRect(x: x, y: y, width: width, height: 20), withAttributes: attrs)
            }

            // MARK: - HEADER
            ctx.setFillColor(UIColor.systemGray6.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: pageWidth, height: 100))

            drawText(
                "TEXTIL MANAGER",
                x: margin,
                y: 30,
                width: pageWidth - margin * 2,
                font: titleFont
            )

            drawText(
                "Resumen de Producción por Maquilero",
                x: margin,
                y: 60,
                width: pageWidth - margin * 2,
                font: subtitleFont
            )

            drawText(
                "Periodo: \(desde.formatted(date: .numeric, time: .omitted)) – \(hasta.formatted(date: .numeric, time: .omitted))",
                x: margin,
                y: 60,
                width: pageWidth - margin * 2,
                font: subtitleFont,
                align: .right
            )

            y = 120

            // MARK: - TABLE HEADER
            let cols: [CGFloat] = [
                margin,     // Maquilero
                260,        // Órdenes
                320,        // Pedidas
                400,        // Recibidas
                480,        // Pagado
                540         // Pendiente
            ]

            ctx.setFillColor(UIColor.systemGray5.cgColor)
            ctx.fill(CGRect(x: margin, y: y - 4, width: pageWidth - margin * 2, height: 22))

            drawText("Maquilero", x: cols[0], y: y, width: 200, font: headerFont)
            drawText("Órdenes", x: cols[1], y: y, width: 50, font: headerFont, align: .right)
            drawText("Pedidas", x: cols[2], y: y, width: 60, font: headerFont, align: .right)
            drawText("Recibidas", x: cols[3], y: y, width: 60, font: headerFont, align: .right)
            drawText("Pagado", x: cols[4], y: y, width: 60, font: headerFont, align: .right)
            drawText("Pendiente", x: cols[5], y: y, width: 60, font: headerFont, align: .right)

            y += 26

            // MARK: - ROWS
            var zebra = false

            for r in resumenPorMaquilero {

                if zebra {
                    ctx.setFillColor(UIColor.systemGray6.cgColor)
                    ctx.fill(CGRect(x: margin, y: y - 4, width: pageWidth - margin * 2, height: 22))
                }

                drawText(r.maquilero, x: cols[0], y: y, width: 200, font: rowFont)
                drawText("\(r.ordenesPedidas)", x: cols[1], y: y, width: 50, font: rowFont, align: .right)
                drawText("\(r.pzPedidas)", x: cols[2], y: y, width: 60, font: rowFont, align: .right)
                drawText("\(r.pzRecibidas)", x: cols[3], y: y, width: 60, font: rowFont, align: .right)
                drawText(r.pagado.formatted(.currency(code: "MXN")), x: cols[4], y: y, width: 60, font: rowFont, align: .right)
                drawText(r.pendiente.formatted(.currency(code: "MXN")), x: cols[5], y: y, width: 60, font: rowFont, align: .right)

                zebra.toggle()
                y += 22
            }

            // MARK: - FOOTER
            let footerY = pageHeight - 50

            ctx.setStrokeColor(UIColor.systemGray3.cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: CGPoint(x: margin, y: footerY))
            ctx.addLine(to: CGPoint(x: pageWidth - margin, y: footerY))
            ctx.strokePath()

            drawText(
                "Generado por Textil Manager · \(Date().formatted(date: .numeric, time: .shortened))",
                x: margin,
                y: footerY + 8,
                width: pageWidth - margin * 2,
                font: footerFont,
                color: .darkGray
            )

            drawText(
                "Página 1 de 1",
                x: margin,
                y: footerY + 8,
                width: pageWidth - margin * 2,
                font: footerFont,
                align: .right,
                color: .darkGray
            )
        }

        itemsExportar = [data]
        mostrarShare = true
    }

    // MARK: - EXPORT EXCEL (CSV)
    private func exportarExcelCSV() {
        var csv = "Maquilero,Ordenes,Pzas Pedidas,Pzas Recibidas,Pagado,Pendiente\n"

        for r in resumenPorMaquilero {
            csv += "\(r.maquilero),\(r.ordenesPedidas),\(r.pzPedidas),\(r.pzRecibidas),\(r.pagado),\(r.pendiente)\n"
        }

        itemsExportar = [csv.data(using: .utf8)!]
        mostrarShare = true
    }

    // MARK: - IMPRIMIR
    private func imprimirResumen() {
        let controller = UIPrintInteractionController.shared

        let formatter = UIMarkupTextPrintFormatter(markupText:
            resumenPorMaquilero.map {
                """
                <b>\($0.maquilero)</b><br>
                Órdenes: \($0.ordenesPedidas)<br>
                Pzas Pedidas: \($0.pzPedidas)<br>
                Pzas Recibidas: \($0.pzRecibidas)<br>
                Pagado: \($0.pagado)<br>
                Pendiente: \($0.pendiente)<br><br>
                """
            }.joined()
        )

        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    // MARK: - LIMPIAR FILTROS
    private func limpiarFiltros() {
        textoBusqueda = ""
        estadoSeleccionado = .todos
        maquileroSeleccionado = "Todos"
        modeloSeleccionado = "Todos"
        mesSeleccionado = "Todos"
        anioSeleccionado = "Todos"

        desde = Calendar.current.date(from: DateComponents(
            year: Calendar.current.component(.year, from: Date()),
            month: 1,
            day: 1
        ))!

        hasta = Date()
    }

    // MARK: - PICKERS DATA
    private var listaMaquileros: [String] {
        ["Todos"] + Array(Set(producciones.map { $0.maquilero })).sorted()
    }

    private var listaModelos: [String] {
        ["Todos"] + Array(
            Set(producciones.flatMap {
                $0.recibos.flatMap { $0.detalles.map { $0.modelo } }
            })
        ).sorted()
    }

    private var listaAnios: [String] {
        ["Todos"] + Array(
            Set(producciones.compactMap {
                $0.fechaOrdenMaquila.map {
                    String(Calendar.current.component(.year, from: $0))
                }
            })
        ).sorted()
    }
}
