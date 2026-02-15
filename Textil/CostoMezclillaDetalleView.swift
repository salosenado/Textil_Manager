//
//  CostoMezclillaDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CostoMezclillaDetalleView.swift
//  Textil
//

import SwiftUI
import UIKit

struct CostoMezclillaDetalleView: View {

    let costo: CostoMezclillaEntity

    // MARK: - UI State
    @State private var mostrarShare = false
    @State private var itemsShare: [Any] = []

    // MARK: - Cálculos
    private var totalTela: Double { costo.costoTela * costo.consumoTela }
    private var totalPoquetin: Double { costo.costoPoquetin * costo.consumoPoquetin }
    private var totalProcesos: Double {
        costo.maquila + costo.lavanderia + costo.cierre + costo.boton +
        costo.remaches + costo.etiquetas + costo.fleteYCajas
    }
    private var total: Double { totalTela + totalPoquetin + totalProcesos }
    private var totalConGastos: Double { total * 1.15 }

    // MARK: - UI
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                encabezado
                seccionTela
                seccionPoquetin
                seccionProcesos
                seccionTotales
                seccionAcciones
            }
            .padding()
        }
        .navigationTitle("Detalle del Costo")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $mostrarShare) {
            ActivityView(items: itemsShare)
        }
    }

    // MARK: - Encabezado
    private var encabezado: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(costo.modelo).font(.title2).fontWeight(.bold)
            Text("Tela: \(costo.tela)").foregroundStyle(.secondary)
            Text("Fecha: \(costo.fecha.formatted(.dateTime.day().month(.abbreviated).year()))")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Secciones
    private var seccionTela: some View {
        tarjeta("Tela") {
            fila("Costo", costo.costoTela)
            fila("Consumo", costo.consumoTela, numero: true)
            Divider()
            fila("Total Tela", totalTela, bold: true)
        }
    }

    private var seccionPoquetin: some View {
        tarjeta("Poquetín") {
            fila("Costo", costo.costoPoquetin)
            fila("Consumo", costo.consumoPoquetin, numero: true)
            Divider()
            fila("Total Poquetín", totalPoquetin, bold: true)
        }
    }

    private var seccionProcesos: some View {
        tarjeta("Procesos y Habilitación") {
            fila("Maquila", costo.maquila)
            fila("Lavandería", costo.lavanderia)
            fila("Cierre", costo.cierre)
            fila("Botón", costo.boton)
            fila("Remaches", costo.remaches)
            fila("Etiquetas", costo.etiquetas)
            fila("Flete y cajas", costo.fleteYCajas)
            Divider()
            fila("Total Procesos", totalProcesos, bold: true)
        }
    }

    private var seccionTotales: some View {
        tarjeta("Totales") {
            fila("Tela", totalTela)
            fila("Poquetín", totalPoquetin)
            fila("Procesos", totalProcesos)
            Divider()
            fila("TOTAL", total, bold: true)
            fila("TOTAL CON GASTOS (15%)", totalConGastos, color: .green, bold: true)
        }
    }

    // MARK: - Acciones
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

    // MARK: - Helpers UI
    private func tarjeta<Content: View>(_ titulo: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titulo).font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4)
    }

    private func fila(_ titulo: String, _ valor: Double, numero: Bool = false, color: Color = .primary, bold: Bool = false) -> some View {
        HStack {
            Text(titulo).fontWeight(bold ? .bold : .regular)
            Spacer()
            Text(numero ? valor.formatted(.number) : valor.formatted(.currency(code: "MXN")))
                .foregroundStyle(color)
                .fontWeight(bold ? .bold : .regular)
        }
    }

    private func boton(_ titulo: String, _ icono: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icono)
                Text(titulo).fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Acciones FUNCIONALES

    private func exportarPDF() {
        let renderer = ImageRenderer(content: ScrollView { VStack { encabezado; seccionTela; seccionPoquetin; seccionProcesos; seccionTotales }.padding() })
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CostoMezclilla.pdf")

        renderer.render { size, render in
            var box = CGRect(origin: .zero, size: size)
            let pdf = CGContext(url as CFURL, mediaBox: &box, nil)!
            pdf.beginPDFPage(nil)
            render(pdf)
            pdf.endPDFPage()
            pdf.closePDF()
        }

        itemsShare = [url]
        mostrarShare = true
    }

    private func exportarExcel() {
        let csv = """
        Concepto,Valor
        Costo Tela,\(costo.costoTela)
        Consumo Tela,\(costo.consumoTela)
        Total Tela,\(totalTela)
        Costo Poquetín,\(costo.costoPoquetin)
        Consumo Poquetín,\(costo.consumoPoquetin)
        Total Poquetín,\(totalPoquetin)
        Maquila,\(costo.maquila)
        Lavandería,\(costo.lavanderia)
        Cierre,\(costo.cierre)
        Botón,\(costo.boton)
        Remaches,\(costo.remaches)
        Etiquetas,\(costo.etiquetas)
        Flete,\(costo.fleteYCajas)
        TOTAL,\(total)
        """

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CostoMezclilla.xlsx")

        try? csv.data(using: .utf8)?.write(to: url)
        itemsShare = [url]
        mostrarShare = true
    }

    private func imprimir() {
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Costo Mezclilla"
        controller.printInfo = info

        let view = UIHostingController(rootView:
            ScrollView { VStack { encabezado; seccionTela; seccionPoquetin; seccionProcesos; seccionTotales }.padding() }
        ).view!

        controller.printFormatter = view.viewPrintFormatter()
        controller.present(animated: true)
    }
}

// MARK: - ShareSheet
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
