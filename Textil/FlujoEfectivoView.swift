//
//  FlujoEfectivoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  FlujoEfectivoView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct FlujoEfectivoView: View {

    @Environment(\.modelContext) private var context

    @Query(sort: \MovimientoCaja.fecha, order: .reverse)
    private var movimientos: [MovimientoCaja]

    @State private var mostrarNuevo = false
    @State private var mostrarPasswordNuevo = false
    @State private var mostrarPasswordEliminar = false

    @State private var password = ""
    @State private var movimientoEliminar: MovimientoCaja?

    private let passwordCorrecto = "1234"

    // MARK: - CÁLCULOS

    var saldoActual: Double {
        movimientos.reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoSemana: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return movimientos
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoMes: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .month, for: Date()) else { return 0 }
        return movimientos
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoAnio: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .year, for: Date()) else { return 0 }
        return movimientos
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var body: some View {

        NavigationStack {

            ZStack {

                List {
                    ForEach(movimientos) { movimiento in
                        VStack(alignment: .leading, spacing: 6) {

                            HStack {
                                Text(movimiento.esIngreso ? "Ingreso" : "Egreso")
                                    .font(.headline)

                                Spacer()

                                Text("MX$ \(movimiento.monto.formatted(.number.precision(.fractionLength(2))))")
                                    .foregroundStyle(movimiento.esIngreso ? .green : .red)
                                    .bold()
                            }

                            Text(movimiento.fecha.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)

                            if movimiento.esIngreso {
                                Text("Cliente: \(movimiento.cliente ?? "")")
                                    .font(.caption)
                            } else {
                                Text("Razón: \(movimiento.razon ?? "")")
                                    .font(.caption)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                movimientoEliminar = movimiento
                                mostrarPasswordEliminar = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    Spacer().frame(height: 120)
                }
                .listStyle(.insetGrouped)

                VStack {
                    Spacer()
                    saldoCard
                        .padding()
                }
            }
            .navigationTitle("Flujo de Efectivo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        mostrarPasswordNuevo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostrarNuevo) {
                NuevoMovimientoView()
            }
            .alert("Contraseña requerida", isPresented: $mostrarPasswordNuevo) {
                SecureField("Contraseña", text: $password)
                Button("Aceptar") {
                    if password == passwordCorrecto {
                        mostrarNuevo = true
                    }
                    password = ""
                }
                Button("Cancelar", role: .cancel) {
                    password = ""
                }
            }
            .alert("Eliminar movimiento", isPresented: $mostrarPasswordEliminar) {
                SecureField("Contraseña", text: $password)
                Button("Eliminar", role: .destructive) {
                    if password == passwordCorrecto,
                       let movimiento = movimientoEliminar {
                        context.delete(movimiento)
                    }
                    password = ""
                    movimientoEliminar = nil
                }
                Button("Cancelar", role: .cancel) {
                    password = ""
                    movimientoEliminar = nil
                }
            }
        }
    }

    // MARK: - TARJETA

    var saldoCard: some View {
        VStack(spacing: 8) {

            Text("Saldo Actual")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("MX$ \(saldoActual.formatted(.number.precision(.fractionLength(2))))")
                .font(.title2)
                .bold()
                .foregroundStyle(saldoActual >= 0 ? .green : .red)

            Divider()

            HStack {
                resumenMini("Semana", saldoSemana)
                resumenMini("Mes", saldoMes)
                resumenMini("Año", saldoAnio)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(radius: 10)
    }

    func resumenMini(_ titulo: String, _ valor: Double) -> some View {
        VStack {
            Text(titulo)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("MX$ \(valor.formatted(.number.precision(.fractionLength(0))))")
                .font(.caption)
                .bold()
                .foregroundStyle(valor >= 0 ? .green : .red)
        }
        .frame(maxWidth: .infinity)
    }
}
