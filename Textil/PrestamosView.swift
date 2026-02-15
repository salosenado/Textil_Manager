//
//  PrestamosView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
import SwiftUI
import SwiftData

struct PrestamosView: View {

    @Environment(\.modelContext) private var context
    @Query private var prestamos: [Prestamo]

    @State private var busqueda = ""

    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                // 🔍 BUSCADOR ARRIBA
                TextField("Buscar persona o empresa...", text: $busqueda)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()

                ScrollView {

                    VStack(spacing: 16) {

                        resumenGlobal

                        ForEach(clientesAgrupados, id: \.key) { nombre, prestamosCliente in

                            resumenCliente(nombre: nombre,
                                           prestamosCliente: prestamosCliente)

                            ForEach(prestamosCliente) { prestamo in
                                NavigationLink {
                                    DetallePrestamoView(prestamo: prestamo)
                                } label: {
                                    tarjetaPrestamo(prestamo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray5))
            }
            .navigationTitle("Creditos")
            .toolbar {
                NavigationLink {
                    NuevoPrestamoView()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - AGRUPACIÓN

    private var clientesAgrupados: [(key: String, value: [Prestamo])] {

        let filtrados = prestamos.filter {
            busqueda.isEmpty ||
            $0.nombre.localizedCaseInsensitiveContains(busqueda)
        }

        let agrupados = Dictionary(grouping: filtrados) { $0.nombre }

        return agrupados.sorted { $0.key < $1.key }
    }

    // MARK: - TARJETA BLANCA

    private func tarjetaPrestamo(_ prestamo: Prestamo) -> some View {

        let proximoInteres = prestamo.interesParaVencimiento(offset: 0)

        return VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text(prestamo.esPersonaMoral ? "Empresa" : "Persona")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                estadoBadge(prestamo)
            }

            Text(prestamo.nombre)
                .font(.headline)

            HStack {
                Text("Capital pendiente:")
                Spacer()
                Text(formatoMoneda(prestamo.capitalPendiente))
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }

            HStack {
                Text("Próximo pago (Intereses):")
                Spacer()
                Text(formatoMoneda(proximoInteres))
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
            }

            HStack {
                Text("Deuda total actual:")
                    .fontWeight(.bold)
                Spacer()
                Text(formatoMoneda(prestamo.capitalPendiente + proximoInteres))
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
    }

    // MARK: - RESUMEN CLIENTE

    private func resumenCliente(nombre: String,
                                 prestamosCliente: [Prestamo]) -> some View {

        let totalCapital = prestamosCliente.map { $0.capitalPendiente }.reduce(0, +)
        let totalIntereses = prestamosCliente.map { $0.interesesPendientes }.reduce(0, +)

        return VStack(alignment: .leading, spacing: 6) {

            Text(nombre)
                .font(.title3)
                .fontWeight(.bold)

            HStack {
                Text("Capital Total")
                Spacer()
                Text(formatoMoneda(totalCapital))
                    .foregroundColor(.red)
            }

            HStack {
                Text("Intereses Totales")
                Spacer()
                Text(formatoMoneda(totalIntereses))
                    .foregroundColor(.orange)
            }

            HStack {
                Text("Deuda Total")
                    .fontWeight(.bold)
                Spacer()
                Text(formatoMoneda(totalCapital + totalIntereses))
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - RESUMEN GLOBAL

    private var resumenGlobal: some View {

        let totalPrestado = prestamos.map { $0.montoPrestado }.reduce(0, +)
        let totalCapitalPendiente = prestamos.map { $0.capitalPendiente }.reduce(0, +)
        let totalInteresesPendientes = prestamos.map { $0.interesesPendientes }.reduce(0, +)

        return VStack(spacing: 8) {

            HStack {
                Text("Total Prestado")
                Spacer()
                Text(formatoMoneda(totalPrestado))
            }

            HStack {
                Text("Capital Pendiente")
                Spacer()
                Text(formatoMoneda(totalCapitalPendiente))
                    .foregroundColor(.red)
            }

            HStack {
                Text("Intereses Pendientes")
                Spacer()
                Text(formatoMoneda(totalInteresesPendientes))
                    .foregroundColor(.orange)
            }

            Divider()

            HStack {
                Text("Deuda General")
                    .fontWeight(.bold)
                Spacer()
                Text(formatoMoneda(totalCapitalPendiente + totalInteresesPendientes))
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - BADGE

    private func estadoBadge(_ prestamo: Prestamo) -> some View {

        Text(prestamo.estaAtrasado ? "ATRASADO" : "AL DÍA")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(prestamo.estaAtrasado ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    // MARK: - FORMATO

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
