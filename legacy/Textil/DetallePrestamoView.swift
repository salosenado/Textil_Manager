//
//  DetallePrestamoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  DetallePrestamoView.swift
//  Textil
//
import SwiftUI
import SwiftData
import UIKit

struct DetallePrestamoView: View {

    @Environment(\.modelContext) private var context

    @State private var showingPagoSheet = false
    @State private var pagoAEliminar: PagoPrestamo?
    @State private var mostrandoPasswordAlert = false
    @State private var password = ""
    @State private var mostrandoErrorPassword = false
    
    @Query(filter: #Predicate<Empresa> { $0.activo == true })
    private var empresasActivas: [Empresa]


    private let adminPassword = "1234"

    @Bindable var prestamo: Prestamo

    var body: some View {

        ScrollView {

            VStack(spacing: 20) {

                // =========================
                // BOTÓN IMPRIMIR GRANDE
                // =========================

                Button {
                    imprimirPrestamo()
                } label: {
                    HStack {
                        Image(systemName: "printer.fill")
                        Text("Imprimir Detalle del Préstamo")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }

                // =========================
                // RESUMEN GENERAL
                // =========================

                VStack(alignment: .leading, spacing: 12) {

                    Text("Resumen General")
                        .font(.headline)

                    fila("Tipo",
                         prestamo.esPersonaMoral ? "Persona Moral" : "Persona Física")

                    fila("Capital Pendiente",
                         formatoMoneda(prestamo.capitalPendiente),
                         .blue)

                    fila("Costo Diario",
                         formatoMoneda(prestamo.costoDiarioActual),
                         .orange)

                    fila("Interés Próximo Pago",
                         formatoMoneda(prestamo.interesParaVencimiento(offset: 0)))

                    fila("Estado",
                         prestamo.estaAtrasado ? "Atrasado" : "Al día",
                         prestamo.estaAtrasado ? .red : .green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)

                // =========================
                // PRÓXIMOS 3 PAGOS
                // =========================

                VStack(alignment: .leading, spacing: 12) {

                    Text("Próximos 3 Pagos de Intereses")
                        .font(.headline)

                    ForEach(0..<3, id: \.self) { index in

                        if let fecha = proximoPago(index: index) {

                            HStack {
                                Text(fecha.formatted(date: .abbreviated,
                                                     time: .omitted))

                                Spacer()

                                Text(
                                    formatoMoneda(
                                        prestamo.interesParaVencimiento(offset: index)
                                    )
                                )
                                .fontWeight(.bold)
                                .foregroundColor(index == 0 ? .blue : .secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)

                // =========================
                // TOTALES ACUMULADOS
                // =========================

                VStack(alignment: .leading, spacing: 12) {

                    Text("Totales Acumulados")
                        .font(.headline)

                    fila("Total Pagado Intereses",
                         formatoMoneda(prestamo.totalInteresPagado),
                         .orange)

                    fila("Total Pagado Capital",
                         formatoMoneda(totalCapitalPagado()),
                         .blue)

                    Divider()

                    fila("Total Pagado General",
                         formatoMoneda(prestamo.totalInteresPagado + totalCapitalPagado()),
                         .green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)

                // =========================
                // HISTORIAL DE PAGOS
                // =========================

                VStack(alignment: .leading, spacing: 0) {

                    Text("Historial de Pagos")
                        .font(.headline)
                        .padding()

                    if prestamo.pagos.isEmpty {
                        Text("No hay pagos registrados")
                            .foregroundColor(.secondary)
                            .padding()
                    }

                    ForEach(
                        prestamo.pagos
                            .filter { !$0.eliminado }   // 👈 SOLO ACTIVOS
                            .sorted(by: { $0.fecha > $1.fecha })
                    ) { pago in

                        HStack {

                            VStack(alignment: .leading, spacing: 4) {

                                Text(pago.esCapital ? "Pago a Capital" : "Pago a Intereses")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if pago.eliminado {
                                    Text("⚠️ PAGO ELIMINADO")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }

                                Text(pago.fecha.formatted(date: .abbreviated,
                                                          time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(formatoMoneda(pago.monto))
                                .fontWeight(.bold)
                                .foregroundColor(
                                    pago.eliminado
                                    ? .gray
                                    : (pago.esCapital ? .blue : .orange)
                                )

                            if !pago.eliminado {
                                Button {
                                    pagoAEliminar = pago
                                    mostrandoPasswordAlert = true
                                } label: {
                                    Image(systemName: "trash.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            pago.eliminado
                            ? Color.gray.opacity(0.05)
                            : Color.white
                        )

                        Divider()
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)

                // =========================
                // RESUMEN VISUAL MOVIMIENTOS
                // =========================

                VStack(alignment: .leading, spacing: 12) {

                    Text("Resumen de Movimientos")
                        .font(.headline)

                    ForEach(prestamo.pagos.sorted(by: { $0.fecha > $1.fecha })) { pago in

                        HStack(spacing: 12) {

                            ZStack {
                                Circle()
                                    .fill(
                                        pago.eliminado
                                        ? Color.gray.opacity(0.2)
                                        : (pago.esCapital
                                            ? Color.blue.opacity(0.2)
                                            : Color.orange.opacity(0.2))
                                    )
                                    .frame(width: 40, height: 40)

                                Image(systemName: pago.esCapital ? "banknote.fill" : "percent")
                                    .foregroundColor(
                                        pago.eliminado
                                        ? .gray
                                        : (pago.esCapital ? .blue : .orange)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 4) {

                                Text(pago.esCapital ? "Capital" : "Interés")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                if pago.eliminado {
                                    Text("⚠️ PAGO ELIMINADO")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }

                                Text("Usuario: \(pago.usuario)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(
                                    pago.fecha.formatted(
                                        .dateTime.day().month().year().hour().minute()
                                    )
                                )
                                .font(.caption2)
                                .foregroundColor(.gray)
                            }

                            Spacer()

                            Text(formatoMoneda(pago.monto))
                                .bold()
                                .foregroundColor(pago.eliminado ? .gray : .primary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 3)

            }
            .padding(.horizontal)
            .padding(.top)
        }
        .background(Color(.systemGray6))
        .navigationTitle(prestamo.nombre)
        .toolbar {

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingPagoSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingPagoSheet) {
            AgregarPagoView(prestamo: prestamo)
        }
        .alert("Contraseña requerida",
               isPresented: $mostrandoPasswordAlert) {

            SecureField("Contraseña", text: $password)

            Button("Eliminar", role: .destructive) {

                if password == adminPassword,
                   let pago = pagoAEliminar {

                    // Si era capital, devolver capital pendiente
                    if pago.esCapital {
                        prestamo.capitalPendiente += pago.monto
                    }

                    // SOLO marcar como eliminado
                    pago.eliminado = true

                    try? context.save()
                }

                password = ""
            }

            Button("Cancelar", role: .cancel) {
                password = ""
            }
        }
    }

    // =========================
    // FUNCIONES
    // =========================

    private func imprimirPrestamo() {

        let empresa = empresasActivas.first

        // Convertir logo a base64
        var logoHTML = ""
        if let logoData = empresa?.logoData {
            let base64 = logoData.base64EncodedString()
            logoHTML = """
            <img src="data:image/png;base64,\(base64)" width="90" />
            """
        }

        let pagosActivos = prestamo.pagos
            .filter { !$0.eliminado }
            .sorted(by: { $0.fecha < $1.fecha })

        let pagosHTML = pagosActivos.map {
            """
            <tr>
                <td>\($0.fecha.formatted(date: .abbreviated, time: .shortened))</td>
                <td>\($0.esCapital ? "Capital" : "Interés")</td>
                <td>\($0.usuario)</td>
                <td style="text-align:right;">\(formatoMoneda($0.monto))</td>
            </tr>
            """
        }.joined()

        let totalCapital = pagosActivos
            .filter { $0.esCapital }
            .map { $0.monto }
            .reduce(0, +)

        let totalInteres = pagosActivos
            .filter { !$0.esCapital }
            .map { $0.monto }
            .reduce(0, +)

        let totalGeneral = totalCapital + totalInteres

        let proximosHTML = (0..<3).compactMap { index -> String? in
            guard let fecha = proximoPago(index: index) else { return nil }
            return """
            <tr>
                <td>\(fecha.formatted(date: .abbreviated, time: .omitted))</td>
                <td style="text-align:right;">\(formatoMoneda(prestamo.interesParaVencimiento(offset: index)))</td>
            </tr>
            """
        }.joined()

        let html = """
        <html>
        <head>
        <style>
            body { font-family: -apple-system; padding: 25px; color:#333; }
            .header { background:#f1f3f4; padding:15px; border-radius:8px; }
            .empresa { display:flex; align-items:center; gap:15px; }
            h1 { margin:0; font-size:22px; }
            h2 { margin-top:25px; font-size:18px; border-bottom:1px solid #ddd; padding-bottom:5px; }
            table { width:100%; border-collapse: collapse; margin-top:10px; }
            th { background:#e5e7eb; text-align:left; padding:8px; font-size:13px; }
            td { padding:8px; border-bottom:1px solid #eee; font-size:13px; }
            .totales td { font-weight:bold; background:#f9fafb; }
            .resaltado { font-size:15px; font-weight:bold; color:#1e3a8a; }
            footer { margin-top:40px; font-size:12px; color:#777; text-align:center; }
        </style>
        </head>
        <body>

        <div class="header">
            <div class="empresa">
                <div>
                    \(logoHTML)
                </div>
                <div>
                    <h1>\(empresa?.nombre ?? "")</h1>
                    <div>RFC: \(empresa?.rfc ?? "")</div>
                    <div>\(empresa?.direccion ?? "")</div>
                    <div>Tel: \(empresa?.telefono ?? "")</div>
                </div>
            </div>
        </div>

        <h2>Información del Cliente</h2>
        <p><strong>Nombre:</strong> \(prestamo.nombre)</p>
        <p><strong>Tipo:</strong> \(prestamo.esPersonaMoral ? "Persona Moral" : "Persona Física")</p>
        <p><strong>Tasa Anual:</strong> \(prestamo.tasaAnual)%</p>
        <p><strong>Monto Otorgado:</strong> \(formatoMoneda(prestamo.montoPrestado))</p>
        <p><strong>Plazo:</strong> \(prestamo.plazoMeses) meses</p>

        <h2>Estado Financiero Actual</h2>
        <p class="resaltado">Capital Pendiente: \(formatoMoneda(prestamo.capitalPendiente))</p>
        <p>Intereses Pendientes: \(formatoMoneda(prestamo.interesesPendientes))</p>

        <h2>Próximos Intereses</h2>
        <table>
            <tr>
                <th>Fecha</th>
                <th style="text-align:right;">Monto</th>
            </tr>
            \(proximosHTML)
        </table>

        <h2>Historial de Pagos</h2>
        <table>
            <tr>
                <th>Fecha</th>
                <th>Tipo</th>
                <th>Usuario</th>
                <th style="text-align:right;">Monto</th>
            </tr>
            \(pagosHTML)
            <tr class="totales">
                <td colspan="3">Total Capital</td>
                <td style="text-align:right;">\(formatoMoneda(totalCapital))</td>
            </tr>
            <tr class="totales">
                <td colspan="3">Total Intereses</td>
                <td style="text-align:right;">\(formatoMoneda(totalInteres))</td>
            </tr>
            <tr class="totales">
                <td colspan="3">Total General</td>
                <td style="text-align:right;">\(formatoMoneda(totalGeneral))</td>
            </tr>
        </table>

        <footer>
            Documento generado el \(Date().formatted(date: .long, time: .shortened))<br>
            \(empresa?.nombre ?? "") · RFC \(empresa?.rfc ?? "")<br>
            Sistema Textil Manager
        </footer>

        </body>
        </html>
        """

        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general

        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    private func totalCapitalPagado() -> Double {
        prestamo.pagos
            .filter { $0.esCapital && !$0.eliminado }
            .map { $0.monto }
            .reduce(0, +)
    }

    private func proximoPago(index: Int) -> Date? {
        guard let base = prestamo.proximoVencimiento else { return nil }
        return Calendar.current.date(byAdding: .month, value: index, to: base)
    }

    private func fila(_ titulo: String,
                      _ valor: String,
                      _ color: Color = .primary) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text(valor)
                .bold()
                .foregroundColor(color)
        }
    }

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
