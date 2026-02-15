//
//  NuevoPrestamoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
import SwiftUI
import SwiftData

struct NuevoPrestamoView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // EMPRESAS
    @Query(sort: \Empresa.nombre) private var empresas: [Empresa]
    @State private var empresaSeleccionada: Empresa?

    // CLIENTE
    @State private var nombre = ""
    @State private var esPersonaMoral = false
    @State private var representante = ""
    @State private var telefono = ""
    @State private var correo = ""

    // FINANCIERO
    @State private var tasaAnualTexto = ""
    @State private var montoTexto = ""
    @State private var plazoMeses = 12
    @State private var fechaInicio = Date()
    @State private var primeraFechaPago =
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    // CONTROL PICKERS
    @State private var mostrandoPickerInicio = false
    @State private var mostrandoPickerPago = false

    // EXTRA
    @State private var notas = ""

    var body: some View {

        NavigationStack {

            Form {

                // MARK: EMPRESA
                Section("Empresa que otorga el préstamo") {

                    Picker("Seleccionar Empresa", selection: $empresaSeleccionada) {

                        Text("Seleccionar...")
                            .tag(nil as Empresa?)

                        ForEach(empresas) { empresa in
                            Text(empresa.nombre)
                                .tag(empresa as Empresa?)
                        }
                    }
                }

                // MARK: CLIENTE
                Section("Información del Cliente") {

                    TextField("Nombre o Razón Social", text: $nombre)

                    Toggle("Persona Moral", isOn: $esPersonaMoral)

                    if esPersonaMoral {
                        TextField("Representante / Dueño", text: $representante)
                    }

                    TextField("Teléfono", text: $telefono)
                        .keyboardType(.phonePad)

                    TextField("Correo Electrónico", text: $correo)
                        .keyboardType(.emailAddress)
                }

                // MARK: CONDICIONES
                Section("Condiciones del Préstamo") {

                    HStack {
                        Text("Monto").fontWeight(.medium)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("MX$").foregroundColor(.secondary)
                            TextField("0.00", text: Binding(
                                get: { montoTexto },
                                set: { montoTexto = formatearNumero($0) }
                            ))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                        }
                        .frame(width: 180)
                    }

                    HStack {
                        Text("Tasa Anual").fontWeight(.medium)
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("0.00", text: $tasaAnualTexto)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text("%").foregroundColor(.secondary)
                        }
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Plazo").fontWeight(.medium)
                        Spacer()
                        Stepper("\(plazoMeses) meses",
                                value: $plazoMeses,
                                in: 1...240)
                    }

                    Button {
                        mostrandoPickerInicio = true
                    } label: {
                        HStack {
                            Text("Fecha Inicio")
                            Spacer()
                            Text(formatoFechaLarga(fechaInicio))
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        mostrandoPickerPago = true
                    } label: {
                        HStack {
                            Text("Primera Fecha de Pago")
                            Spacer()
                            Text(formatoFechaLarga(primeraFechaPago))
                        }
                    }
                    .buttonStyle(.plain)
                }

                // MARK: RESUMEN
                Section("Resumen Automático") {

                    HStack {
                        Text("Interés Primer Periodo (\(diasPrimerPeriodo) días)")
                        Spacer()
                        Text(formatoMoneda(interesPrimerPeriodo()))
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Pago Mensual Intereses")
                        Spacer()
                        Text(formatoMoneda(pagoMensual()))
                            .bold()
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Total Intereses del Préstamo")
                        Spacer()
                        Text(formatoMoneda(totalInteresesPrestamo()))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total a Pagar Intereses y Capital")
                            .bold()
                        Spacer()
                        Text(formatoMoneda(montoDouble + totalInteresesPrestamo()))
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                Section("Observaciones") {
                    TextField("Notas adicionales",
                              text: $notas,
                              axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("Nuevo Préstamo")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { guardarPrestamo() }
                        .disabled(
                            empresaSeleccionada == nil ||
                            nombre.isEmpty ||
                            montoDouble <= 0 ||
                            tasaDouble <= 0 ||
                            primeraFechaPago <= fechaInicio
                        )
                }
            }
            .sheet(isPresented: $mostrandoPickerInicio) {
                DatePicker("Fecha Inicio",
                           selection: $fechaInicio,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
            }
            .sheet(isPresented: $mostrandoPickerPago) {
                DatePicker("Primera Fecha de Pago",
                           selection: $primeraFechaPago,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
            }
        }
    }

    // MARK: FUNCIONES

    private func formatoFechaLarga(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: fecha)
    }

    private var diasPrimerPeriodo: Int {
        Calendar.current.dateComponents(
            [.day],
            from: fechaInicio,
            to: primeraFechaPago
        ).day ?? 0
    }

    private func formatearNumero(_ texto: String) -> String {
        let limpio = texto.replacingOccurrences(of: ",", with: "")
        guard let numero = Double(limpio) else { return "" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: numero)) ?? ""
    }

    private var montoDouble: Double {
        Double(montoTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private var tasaDouble: Double {
        Double(tasaAnualTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func pagoMensual() -> Double {
        montoDouble * (tasaDouble / 100) / 12
    }

    private func interesPrimerPeriodo() -> Double {
        let interesDiario = (tasaDouble / 100) / 360
        return montoDouble * interesDiario * Double(diasPrimerPeriodo)
    }

    private func totalInteresesPrestamo() -> Double {
        montoDouble * (tasaDouble / 100) * Double(plazoMeses) / 12
    }

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }

    private func guardarPrestamo() {

        guard let empresaSeleccionada else { return }

        let nuevo = Prestamo(
            nombre: nombre,
            esPersonaMoral: esPersonaMoral,
            tasaAnual: tasaDouble,
            montoPrestado: montoDouble,
            plazoMeses: plazoMeses,
            telefono: telefono,
            correo: correo,
            representante: representante,
            notas: notas,
            primeraFechaPago: primeraFechaPago,
            fechaInicio: fechaInicio,
            empresa: empresaSeleccionada
        )

        context.insert(nuevo)
        try? context.save()
        dismiss()
    }
}
