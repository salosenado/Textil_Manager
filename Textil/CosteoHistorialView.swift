//
//  CosteoHistorialView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CosteoHistorialView.swift
//  Textil
//
//  CosteoHistorialView.swift
//  Textil
//

import SwiftUI
import SwiftData
import UIKit

struct CosteoHistorialView: View {

    let modelo: String

    @Query(sort: \CostoGeneralEntity.fecha)
    private var costosGenerales: [CostoGeneralEntity]

    @Query(sort: \CostoMezclillaEntity.fecha)
    private var costosMezclilla: [CostoMezclillaEntity]

    // MARK: - Exportación
    @State private var mostrarShare = false
    @State private var archivoURL: URL?

    enum TipoCosteo {
        case general
        case mezclilla
    }

    struct Movimiento: Identifiable {
        let id = UUID()
        let fecha: Date
        let monto: Double
        let tipo: TipoCosteo
    }

    // MARK: - Historial unificado
    private var movimientos: [Movimiento] {
        let gen = costosGenerales
            .filter { $0.modelo == modelo }
            .map {
                Movimiento(
                    fecha: $0.fecha,
                    monto: $0.totalConGastos,
                    tipo: .general
                )
            }

        let mez = costosMezclilla
            .filter { $0.modelo == modelo }
            .map {
                Movimiento(
                    fecha: $0.fecha,
                    monto: $0.totalConGastos,
                    tipo: .mezclilla
                )
            }

        return (gen + mez).sorted { $0.fecha < $1.fecha }
    }

    // MARK: - UI
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {

                if movimientos.isEmpty {
                    ContentUnavailableView(
                        "Sin historial",
                        systemImage: "clock",
                        description: Text("No hay registros para este modelo")
                    )
                    .padding(.top, 60)
                }

                ForEach(movimientos.indices, id: \.self) { index in
                    let actual = movimientos[index]
                    let anterior = index > 0 ? movimientos[index - 1] : nil

                    HStack {

                        VStack(alignment: .leading, spacing: 4) {
                            Text(actual.tipo == .general ? "Costo General" : "Costo Mezclilla")
                                .font(.headline)

                            Text(actual.fecha.formatted(.dateTime.day().month(.abbreviated).year()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(actual.monto, format: .currency(code: "MXN"))
                                .fontWeight(.semibold)

                            if let anterior {
                                let diff = actual.monto - anterior.monto
                                let percent = (diff / anterior.monto) * 100
                                Text(String(format: "%+.2f %%", percent))
                                    .font(.caption)
                                    .foregroundStyle(percent >= 0 ? .green : .red)
                            } else {
                                Text("—")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 4)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Historial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            // 🧾 EXPORTAR (MENÚ CLARO)
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Exportar PDF") {
                        exportarPDF()
                    }

                    Button("Exportar Excel") {
                        exportarCSV()
                    }

                    Button("Imprimir") {
                        imprimir()
                    }
                } label: {
                    Label("Exportar", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $mostrarShare) {
            if let archivoURL {
                ShareSheet(activityItems: [archivoURL])
            }
        }
    }

    // MARK: - EXPORTAR PDF
    func exportarPDF() {

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 595, height: 842)
        )

        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            let title: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]

            let body: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]

            var y: CGFloat = 40

            "Historial de Costos – \(modelo)"
                .draw(at: CGPoint(x: 40, y: y), withAttributes: title)

            y += 40

            for mov in movimientos {
                let tipo = mov.tipo == .general ? "General" : "Mezclilla"
                let linea =
                "\(mov.fecha.formatted(date: .abbreviated, time: .omitted)),\(tipo),\(String(format: "%.2f", mov.monto))"

                linea.draw(at: CGPoint(x: 40, y: y), withAttributes: body)
                y += 20

                if y > 800 {
                    ctx.beginPage()
                    y = 40
                }
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Historial_\(modelo).pdf")

        try? data.write(to: url)
        archivoURL = url
        mostrarShare = true
    }

    // MARK: - EXPORTAR CSV (EXCEL REAL)
    func exportarCSV() {

        var csv = "Fecha,Tipo,Monto\n"

        for mov in movimientos {
            let tipo = mov.tipo == .general ? "General" : "Mezclilla"
            let linea =
            "\(mov.fecha.formatted(date: .numeric, time: .omitted)),\(tipo),\(mov.monto)\n"
            csv.append(linea)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Historial_\(modelo).csv")

        try? csv.write(to: url, atomically: true, encoding: .utf8)
        archivoURL = url
        mostrarShare = true
    }

    // MARK: - IMPRIMIR (YA FUNCIONAL)
    func imprimir() {

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: 595, height: 842)
        )

        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            var y: CGFloat = 40

            for mov in movimientos {
                let tipo = mov.tipo == .general ? "General" : "Mezclilla"
                let linea =
                "\(mov.fecha.formatted(date: .abbreviated, time: .omitted))  \(tipo)  MX$\(String(format: "%.2f", mov.monto))"

                linea.draw(
                    at: CGPoint(x: 40, y: y),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 12)]
                )
                y += 20

                if y > 800 {
                    ctx.beginPage()
                    y = 40
                }
            }
        }

        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)

        info.jobName = "Historial \(modelo)"
        info.outputType = .general

        controller.printInfo = info
        controller.printingItem = data
        controller.present(animated: true)
    }
}

//
// MARK: - Share Sheet
//

struct ShareSheet: UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
