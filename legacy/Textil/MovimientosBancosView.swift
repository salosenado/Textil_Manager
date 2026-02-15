//
//  MovimientosBancosView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct MovimientosBancosView: View {

    @Environment(\.modelContext) private var context

    @Query private var empresas: [Empresa]
    @Query(sort: \MovimientoBanco.fecha, order: .reverse)
    private var movimientos: [MovimientoBanco]

    @State private var empresaSeleccionada: Empresa?
    @State private var mostrarNuevo = false
    @State private var movimientoEditar: MovimientoBanco?

    @State private var password = ""
    @State private var mostrarPassword = false
    @State private var accion: Accion?

    private let passwordCorrecto = "1234"

    enum Accion {
        case crear
        case editar(MovimientoBanco)
        case eliminar(MovimientoBanco)
    }

    // 🔥 FILTRO
    var movimientosFiltrados: [MovimientoBanco] {
        if let empresaSeleccionada {
            return movimientos.filter { $0.empresa == empresaSeleccionada }
        } else {
            return movimientos
        }
    }

    // 🔥 SALDOS
    var saldoActual: Double {
        movimientosFiltrados.reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoSemana: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return movimientosFiltrados
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoMes: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .month, for: Date()) else { return 0 }
        return movimientosFiltrados
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var saldoAnio: Double {
        guard let intervalo = Calendar.current.dateInterval(of: .year, for: Date()) else { return 0 }
        return movimientosFiltrados
            .filter { intervalo.contains($0.fecha) }
            .reduce(0) { $0 + $1.montoFirmado }
    }

    var body: some View {

        NavigationStack {

            ZStack {

                List {

                    // 🔥 PICKER EMPRESA
                    Section {
                        Picker("Empresa", selection: $empresaSeleccionada) {
                            Text("Todas").tag(Empresa?.none)
                            ForEach(empresas) { empresa in
                                Text(empresa.nombre)
                                    .tag(Optional(empresa))
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    ForEach(movimientosFiltrados) { movimiento in

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
                                Text("Cliente: \(movimiento.cliente?.nombreComercial ?? "")")
                                    .font(.caption)
                            } else {
                                Text("Proveedor: \(movimiento.proveedor?.nombre ?? "")")
                                    .font(.caption)
                            }
                        }
                        .swipeActions {

                            Button {
                                accion = .editar(movimiento)
                                mostrarPassword = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                accion = .eliminar(movimiento)
                                mostrarPassword = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                    }

                    Spacer().frame(height: 120)
                }
                .listStyle(.insetGrouped)

                // 🔥 TARJETA FLOTANTE
                VStack {
                    Spacer()
                    saldoCard
                        .padding()
                }
            }
            .navigationTitle("Bancos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        accion = .crear
                        mostrarPassword = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $movimientoEditar) { movimiento in
                NuevoMovimientoBancoView(movimientoEditar: movimiento)
            }
            .sheet(isPresented: $mostrarNuevo) {
                NuevoMovimientoBancoView()
            }
            .alert("Contraseña requerida", isPresented: $mostrarPassword) {
                SecureField("Contraseña", text: $password)
                Button("Aceptar") {
                    validarPassword()
                }
                Button("Cancelar", role: .cancel) {
                    password = ""
                }
            }
        }
    }

    private func validarPassword() {

        guard password == passwordCorrecto else {
            password = ""
            return
        }

        switch accion {
        case .crear:
            mostrarNuevo = true

        case .editar(let movimiento):
            movimientoEditar = movimiento

        case .eliminar(let movimiento):
            context.delete(movimiento)

        case .none:
            break
        }

        password = ""
    }

    // 🔥 TARJETA
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
