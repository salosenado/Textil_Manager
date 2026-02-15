//
//  SaldosFacturasView.swift
//  Textil
//
//  Created by Salomon Senado on 2/15/26.
//
import SwiftUI
import SwiftData

struct SaldosFacturasView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \SaldoFacturaAdelantada.fecha, order: .reverse)
    private var facturas: [SaldoFacturaAdelantada]

    @State private var mostrarNueva = false
    @State private var busqueda = ""
    @State private var filtroStatus = "Todos"

    private let opcionesStatus = ["Todos", "Pendiente", "Parcial", "Finalizado"]

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // 🔎 BUSCADOR
                TextField("Buscar empresa o número de factura...", text: $busqueda)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()

                // 🎛 PICKER STATUS
                HStack {
                    Text("Status")
                    Spacer()

                    Picker("", selection: $filtroStatus) {
                        ForEach(opcionesStatus, id: \.self) { opcion in
                            Text(opcion)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                ScrollView {

                    VStack(spacing: 16) {

                        resumenGlobal   // 🔥 ahora sí se muestra
                        resumenPorEmpresa

                        ForEach(facturasFiltradas) { factura in
                            NavigationLink {
                                DetalleSaldoFacturaView(factura: factura)
                            } label: {
                                tarjetaFactura(factura)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Saldos Facturas")
            .toolbar {
                Button {
                    mostrarNueva = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $mostrarNueva) {
                NuevaFacturaAdelantadaView()
            }
        }
    }

    // MARK: - FILTROS

    private var facturasFiltradas: [SaldoFacturaAdelantada] {

        facturas.filter { factura in

            let coincideBusqueda =
                busqueda.isEmpty ||
                factura.empresaNombre.localizedCaseInsensitiveContains(busqueda) ||
                factura.numeroFactura.localizedCaseInsensitiveContains(busqueda)

            let coincideStatus =
                filtroStatus == "Todos" ||
                factura.estado == filtroStatus

            return coincideBusqueda && coincideStatus
        }
    }

    // MARK: - RESUMEN GLOBAL

    private var resumenGlobal: some View {

        let totalGeneral = facturasFiltradas.map { $0.total }.reduce(0, +)
        let totalPagado = facturasFiltradas.map { $0.totalPagado }.reduce(0, +)
        let totalSaldo = facturasFiltradas.map { $0.saldoPendiente }.reduce(0, +)

        return VStack(spacing: 8) {

            fila("Total General Facturado", totalGeneral)

            fila("Total Pagado", totalPagado, color: .green)

            Divider()

            filaTotal("Total Saldo Pendiente", totalSaldo, color: .red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
        )
    }

    // MARK: - RESUMEN POR EMPRESA ACREEDORA

    private var resumenPorEmpresa: some View {

        let agrupadas = Dictionary(grouping: facturasFiltradas) { $0.empresaAcreedor }

        return VStack(alignment: .leading, spacing: 12) {

            Text("Resumen por Empresa Acreedora")
                .font(.headline)

            ForEach(agrupadas.keys.sorted(), id: \.self) { empresa in

                let facturasEmpresa = agrupadas[empresa] ?? []

                let totalFacturado = facturasEmpresa.map { $0.total }.reduce(0, +)
                let totalPagado = facturasEmpresa.map { $0.totalPagado }.reduce(0, +)
                let saldo = totalFacturado - totalPagado

                VStack(alignment: .leading, spacing: 8) {

                    // 🔥 NUEVA LÍNEA
                    Text("Empresa: \(empresa)")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Divider()

                    fila("Total Facturado", totalFacturado)
                    fila("Total Pagado", totalPagado, color: .green)
                    filaTotal("Saldo", saldo, color: .red)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
            }
        }
    }

    // MARK: - TARJETA

    private func tarjetaFactura(_ factura: SaldoFacturaAdelantada) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {

                    Text("Factura #\(factura.numeroFactura)")
                        .font(.headline)

                    Text("Empresa emisora:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(factura.empresaNombre)

                    Text("Se debe a:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(factura.empresaAcreedor)
                }

                Spacer()

                estadoBadge(factura)
            }

            Divider()

            fila("Subtotal", factura.subtotal)
            fila("IVA 16%", factura.iva)
            filaTotal("Total", factura.total)

            Divider()

            fila("Pagado", factura.totalPagado, color: .green)
            filaTotal("Saldo Pendiente", factura.saldoPendiente, color: .red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
    }

    // MARK: - HELPERS FILAS

    private func fila(_ titulo: String, _ valor: Double, color: Color = .primary) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(formatoMoneda(valor))
                .foregroundColor(color)
        }
    }

    private func filaTotal(_ titulo: String, _ valor: Double, color: Color = .primary) -> some View {
        HStack {
            Text(titulo)
                .fontWeight(.bold)
            Spacer()
            Text(formatoMoneda(valor))
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }

    // MARK: - BADGE

    private func estadoBadge(_ factura: SaldoFacturaAdelantada) -> some View {

        let color: Color =
            factura.estado == "Finalizado" ? .blue :
            factura.estado == "Parcial" ? .orange : .red

        return Text(factura.estado.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    // MARK: - FORMATO MONEDA

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
