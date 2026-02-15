//
//  DispersionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

//
//  DispersionDetalleView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

import SwiftUI

struct DispersionDetalleView: View {

    let dispersion: Dispersion

    // MARK: - Totales

    var totalSalidas: Double {
        dispersion.salidas.reduce(0) { $0 + $1.monto }
    }

    var saldoFinal: Double {
        dispersion.neto - totalSalidas
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                // MARK: - Header

                VStack(spacing: 8) {
                    Text("Detalle del Movimiento")
                        .font(.title2)
                        .bold()

                    Text(dispersion.fechaMovimiento.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: - Información General

                VStack(spacing: 12) {

                    detalleFila("Wara", dispersion.wara)
                    detalleFila("Empresa", dispersion.empresa)
                    detalleFila("Depósito", formatoMX(dispersion.monto))
                    detalleFila("% Comisión", "\(formatoPorcentaje(dispersion.porcentajeComision))")
                    detalleFila("Comisión Final", formatoMX(dispersion.comision))
                    detalleFila("Neto Recibido", formatoMX(dispersion.neto))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)

                // MARK: - Totales Visuales

                VStack(spacing: 14) {

                    totalFila("Total Recibido", dispersion.neto, .blue)
                    totalFila("Total Salidas", totalSalidas, .red)
                    totalFila("Saldo Final", saldoFinal,
                              saldoFinal >= 0 ? .green : .red)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.06),
                                 Color.green.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
                .cornerRadius(20)

                // MARK: - Salidas

                VStack(alignment: .leading, spacing: 16) {

                    Text("Salidas")
                        .font(.headline)

                    ForEach(dispersion.salidas) { salida in

                        VStack(alignment: .leading, spacing: 8) {

                            HStack {
                                Text(salida.concepto)
                                    .font(.headline)
                                Spacer()
                                Text(formatoMX(salida.monto))
                                    .foregroundColor(.red)
                                    .bold()
                            }

                            Text("Nombre: \(salida.nombre)")
                                .font(.subheadline)

                            Text("Cuenta: \(salida.cuenta)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.04),
                                radius: 4,
                                x: 0,
                                y: 2)
                    }
                }

                Color.clear.frame(height: 40)
            }
            .padding()
        }
        .navigationTitle("Dispersión")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Filas

    func detalleFila(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
                .foregroundColor(.secondary)
            Spacer()
            Text(valor)
                .bold()
        }
    }

    func totalFila(_ titulo: String,
                   _ valor: Double,
                   _ color: Color) -> some View {

        HStack {
            Text(titulo)
                .font(.headline)
            Spacer()
            Text(formatoMX(valor))
                .font(.title3)
                .bold()
                .foregroundColor(color)
        }
    }

    // MARK: - Formatos

    func formatoMX(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "MX$"
        formatter.locale = Locale(identifier: "es_MX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }

    func formatoPorcentaje(_ valor: Double) -> String {
        String(format: "%.2f%%", valor)
    }
}
