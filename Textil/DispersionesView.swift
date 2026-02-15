//
//  DispersionesView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//
//
//  DispersionesView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//

import SwiftUI
import SwiftData

struct DispersionesView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Dispersion.fechaMovimiento, order: .reverse)
    private var dispersions: [Dispersion]

    // MARK: - Estados principales

    @State private var wara = ""
    @State private var empresa = ""
    @State private var montoTexto = ""
    @State private var porcentajeTexto = ""
    @State private var fechaMovimiento = Date()
    @State private var concepto = ""
    @State private var observaciones = ""

    // MARK: - Estados salidas

    @State private var conceptoSalida = ""
    @State private var nombreSalida = ""
    @State private var cuentaSalida = ""
    @State private var montoSalidaTexto = ""

    @State private var salidasTemp: [SalidaUI] = []

    // MARK: - Filtros resumen mensual

    @State private var empresaFiltro = ""
    @State private var mesSeleccionado = Calendar.current.component(.month, from: Date())
    @State private var anioSeleccionado = Calendar.current.component(.year, from: Date())

    // MARK: - Conversión

    var monto: Double { Double(montoTexto) ?? 0 }
    var porcentaje: Double { Double(porcentajeTexto) ?? 0 }
    var montoSalida: Double { Double(montoSalidaTexto) ?? 0 }

    // MARK: - Fórmula fiscal

    var baseSinIVA: Double { monto / 1.16 }
    var comisionBase: Double { baseSinIVA * (porcentaje / 100) }
    var comisionFinal: Double { comisionBase * 1.16 }
    var netoCalculado: Double { monto - comisionFinal }

    // MARK: - Salidas en vivo

    var totalSalidas: Double {
        salidasTemp.map(\.monto).reduce(0, +)
    }

    var saldoRestante: Double {
        netoCalculado - totalSalidas
    }

    // MARK: - Filtro mensual

    var dispersionsFiltradas: [Dispersion] {

        dispersions.filter { d in

            let mes = Calendar.current.component(.month, from: d.fechaMovimiento)
            let anio = Calendar.current.component(.year, from: d.fechaMovimiento)

            let empresaMatch =
                empresaFiltro.isEmpty ||
                d.empresa.localizedCaseInsensitiveContains(empresaFiltro)

            return mes == mesSeleccionado &&
                   anio == anioSeleccionado &&
                   empresaMatch
        }
    }

    var totalDepositosMes: Double {
        dispersionsFiltradas.reduce(0) { $0 + $1.monto }
    }

    var totalComisionesMes: Double {
        dispersionsFiltradas.reduce(0) { $0 + $1.comision }
    }

    var totalNetoMes: Double {
        dispersionsFiltradas.reduce(0) { $0 + $1.neto }
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 24) {

                bloqueCaptura
                bloqueResumen
                bloqueSalidas
                botonGuardar
                bloqueResumenMensual
                historial
            }
            .padding()
        }
        .navigationTitle("Dispersión")
    }
}

//////////////////////////////////////////////////////////
// MARK: - CAPTURA
//////////////////////////////////////////////////////////

extension DispersionesView {

    var bloqueCaptura: some View {

        VStack(spacing: 16) {

            TextField("Wara", text: $wara)
            TextField("Empresa", text: $empresa)

            TextField("Monto (MX$)", text: $montoTexto)
                .keyboardType(.decimalPad)

            TextField("% Comisión", text: $porcentajeTexto)
                .keyboardType(.decimalPad)

            DatePicker("Fecha movimiento",
                       selection: $fechaMovimiento,
                       displayedComponents: .date)

            TextField("Concepto", text: $concepto)
            TextField("Observaciones", text: $observaciones)
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

//////////////////////////////////////////////////////////
// MARK: - RESUMEN
//////////////////////////////////////////////////////////

extension DispersionesView {

    var bloqueResumen: some View {

        VStack(spacing: 10) {
            fila("DEPÓSITO", monto)
            fila("BASE SIN IVA", baseSinIVA)
            fila("COMISIÓN (\(porcentajeTexto)%)", comisionBase)
            fila("COMISIÓN + IVA", comisionFinal)
            fila("REGRESO NETO", netoCalculado, esTotal: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    func fila(_ titulo: String, _ valor: Double, esTotal: Bool = false) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(formatoMX(valor))
                .font(esTotal ? .headline : .subheadline)
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - SALIDAS
//////////////////////////////////////////////////////////

extension DispersionesView {

    var bloqueSalidas: some View {

        VStack(spacing: 14) {

            HStack {
                Text("Salidas").font(.headline)
                Spacer()
                Button {
                    agregarSalida()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }

            Group {
                TextField("Concepto", text: $conceptoSalida)
                TextField("Nombre", text: $nombreSalida)
                TextField("Cuenta", text: $cuentaSalida)
                TextField("Monto (MX$)", text: $montoSalidaTexto)
                    .keyboardType(.decimalPad)
            }
            .textFieldStyle(.roundedBorder)

            Divider()

            ForEach(salidasTemp) { salida in
                HStack {
                    VStack(alignment: .leading) {
                        Text(salida.concepto)
                        Text(salida.nombre)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(formatoMX(salida.monto))
                        .foregroundColor(.red)
                }
            }

            Divider()

            HStack {
                Text("Total salidas")
                Spacer()
                Text(formatoMX(totalSalidas))
                    .foregroundColor(.red)
            }

            HStack {
                Text("Saldo restante")
                Spacer()
                Text(formatoMX(saldoRestante))
                    .font(.headline)
                    .foregroundColor(
                        saldoRestante == 0 ? .blue :
                        saldoRestante > 0 ? .green : .red
                    )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    func agregarSalida() {

        guard montoSalida > 0 else { return }
        guard montoSalida <= saldoRestante else { return }

        let nueva = SalidaUI(
            concepto: conceptoSalida,
            nombre: nombreSalida,
            cuenta: cuentaSalida,
            monto: montoSalida
        )

        salidasTemp.append(nueva)

        conceptoSalida = ""
        nombreSalida = ""
        cuentaSalida = ""
        montoSalidaTexto = ""
    }
}

//////////////////////////////////////////////////////////
// MARK: - GUARDAR
//////////////////////////////////////////////////////////

extension DispersionesView {

    var botonGuardar: some View {

        Button {

            let nueva = Dispersion(
                wara: wara,
                empresa: empresa,
                monto: monto,
                porcentajeComision: porcentaje,
                comision: comisionFinal,
                iva: comisionFinal - comisionBase,
                neto: netoCalculado,
                fechaMovimiento: fechaMovimiento,
                concepto: concepto,
                observaciones: observaciones
            )

            for salida in salidasTemp {
                let salidaReal = DispersionSalida(
                    concepto: salida.concepto,
                    nombre: salida.nombre,
                    cuenta: salida.cuenta,
                    monto: salida.monto
                )
                nueva.salidas.append(salidaReal)
            }

            context.insert(nueva)
            try? context.save()

            limpiarFormulario()

        } label: {

            Text("Guardar Dispersión")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
        .disabled(monto <= 0 || porcentaje <= 0)
    }

    func limpiarFormulario() {
        wara = ""
        empresa = ""
        montoTexto = ""
        porcentajeTexto = ""
        concepto = ""
        observaciones = ""
        fechaMovimiento = Date()
        salidasTemp.removeAll()
    }
}

//////////////////////////////////////////////////////////
// MARK: - RESUMEN MENSUAL
//////////////////////////////////////////////////////////

extension DispersionesView {

    var bloqueResumenMensual: some View {

        VStack(spacing: 18) {

            HStack {
                Text("Resumen Mensual")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {

                Picker("", selection: $mesSeleccionado) {
                    ForEach(1...12, id: \.self) { mes in
                        Text(nombreMes(mes)).tag(mes)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)

                Picker("", selection: $anioSeleccionado) {
                    ForEach(2020...2035, id: \.self) { anio in
                        Text(String(anio)).tag(anio)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }

            TextField("Filtrar por empresa (opcional)",
                      text: $empresaFiltro)
                .textFieldStyle(.roundedBorder)

            Divider()

            filaResumenMensual("Total Depositado", totalDepositosMes, .blue)
            filaResumenMensual("Total Comisiones", totalComisionesMes, .red)
            filaResumenMensual("Total Regreso", totalNetoMes, .green)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }

    func nombreMes(_ mes: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.monthSymbols[mes - 1].capitalized
    }

    func filaResumenMensual(_ titulo: String,
                            _ valor: Double,
                            _ color: Color) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text(formatoMX(valor))
                .foregroundColor(color)
                .font(.headline)
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - HISTORIAL
//////////////////////////////////////////////////////////

extension DispersionesView {

    var historial: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text("Historial")
                .font(.headline)

            ForEach(dispersions) { d in

                NavigationLink {
                    DispersionDetalleView(dispersion: d)
                } label: {

                    VStack(alignment: .leading, spacing: 10) {

                        HStack {
                            VStack(alignment: .leading) {
                                Text(d.wara)
                                    .font(.headline)
                                Text(d.empresa)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(formatoMX(d.neto))
                                .font(.headline)
                                .foregroundColor(.green)
                        }

                        Divider()

                        HStack {
                            Label(d.fechaMovimiento.formatted(date: .abbreviated, time: .omitted),
                                  systemImage: "calendar")
                                .font(.caption)

                            Spacer()

                            Label("\(d.salidas.count) salidas",
                                  systemImage: "arrow.up.circle")
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(18)
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - FORMATO MX$
//////////////////////////////////////////////////////////

extension DispersionesView {

    func formatoMX(_ valor: Double) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "MX$"
        formatter.locale = Locale(identifier: "es_MX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}

//////////////////////////////////////////////////////////
// MARK: - MODELO UI TEMPORAL
//////////////////////////////////////////////////////////

struct SalidaUI: Identifiable {
    let id = UUID()
    var concepto: String
    var nombre: String
    var cuenta: String
    var monto: Double
}
