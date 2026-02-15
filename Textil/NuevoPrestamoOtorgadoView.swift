//
//  NuevoPrestamoOtorgadoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  NuevoPrestamoOtorgadoView.swift
//  Textil
//

import SwiftUI
import SwiftData
import UIKit

struct NuevoPrestamoOtorgadoView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Empresa.nombre)
    private var empresas: [Empresa]

    @State private var empresaSeleccionada: Empresa?

    // RECEPTOR
    @State private var nombre = ""
    @State private var apellido = ""
    @State private var esEmpleado = true
    @State private var numeroEmpleado = ""
    @State private var direccion = ""
    @State private var telefono = ""
    @State private var correo = ""

    // FINANCIERO
    @State private var montoTexto = ""
    @State private var tasaTexto = ""
    @State private var plazoMeses = 12
    @State private var fechaInicio = Date()
    @State private var fechaPrimerPago =
        Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    @State private var periodicidad = "Mensual"
    
    @State private var firmaEmpresa: Data?
    @State private var firmaReceptor: Data?

    @State private var mostrarFirmaEmpresa = false
    @State private var mostrarFirmaReceptor = false


    let opcionesPeriodicidad = ["Semanal","Quincenal","Mensual","Bimestral"]

    @State private var notas = ""

    var body: some View {

        NavigationStack {

            Form {

                // EMPRESA
                Section("Empresa que Otorga el Préstamo") {
                    Picker("Seleccionar Empresa", selection: $empresaSeleccionada) {
                        Text("Seleccionar...").tag(nil as Empresa?)
                        ForEach(empresas) { empresa in
                            Text(empresa.nombre).tag(empresa as Empresa?)
                        }
                    }
                }

                // RECEPTOR
                Section("Información del Receptor") {

                    TextField("Nombre", text: $nombre)
                    TextField("Apellido", text: $apellido)

                    Picker("Tipo", selection: $esEmpleado) {
                        Text("Empleado").tag(true)
                        Text("Particular").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if esEmpleado {
                        TextField("Número de Empleado", text: $numeroEmpleado)
                    }

                    TextField("Dirección", text: $direccion)
                    TextField("Teléfono", text: $telefono)
                        .keyboardType(.phonePad)

                    TextField("Correo", text: $correo)
                        .keyboardType(.emailAddress)
                }

                // CONDICIONES
                Section("Condiciones Financieras") {

                    HStack {
                        Text("Monto")
                        Spacer()

                        HStack(spacing: 4) {
                            Text("MX$")
                                .foregroundColor(.secondary)

                            TextField("0.00", text: $montoTexto)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .onChange(of: montoTexto) { newValue in
                                    let limpio = newValue.replacingOccurrences(of: ",", with: "")
                                    if let numero = Double(limpio) {
                                        montoTexto = NumberFormatter.localizedString(
                                            from: NSNumber(value: numero),
                                            number: .decimal
                                        )
                                    }
                                }
                        }
                    }

                    HStack {
                        Text("Tasa Anual")
                        Spacer()
                        TextField("0.00", text: $tasaTexto)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("%")
                    }

                    Stepper("Plazo: \(plazoMeses) meses",
                            value: $plazoMeses,
                            in: 1...240)

                    DatePicker("Fecha Inicio",
                               selection: $fechaInicio,
                               displayedComponents: .date)

                    DatePicker("Primer Pago",
                               selection: $fechaPrimerPago,
                               displayedComponents: .date)

                    Picker("Periodicidad", selection: $periodicidad) {
                        ForEach(opcionesPeriodicidad, id: \.self) {
                            Text($0)
                        }
                    }
                }

                // MARK: RESUMEN
                Section("Resumen Automático") {

                    HStack {
                        Text("Pago por Periodo")
                        Spacer()
                        Text(formatoMoneda(pagoPorPeriodo()))
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Total Intereses")
                        Spacer()
                        Text(formatoMoneda(totalIntereses()))
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("Total a Recuperar")
                            .bold()
                        Spacer()
                        Text(formatoMoneda(montoDouble + totalIntereses()))
                            .bold()
                            .foregroundColor(.green)
                    }
                }

                // MARK: OBSERVACIONES
                Section("Observaciones") {
                    TextField("Notas", text: $notas, axis: .vertical)
                        .lineLimit(3)
                }

                // MARK: FIRMAS
                Section("Firmas") {

                    Button("Firmar Empresa") {
                        mostrarFirmaEmpresa = true
                    }

                    if firmaEmpresa != nil {
                        Text("Firma empresa guardada ✅")
                            .font(.caption)
                            .foregroundColor(.green)
                    }

                    
                    Button("Firmar Receptor") {
                        mostrarFirmaReceptor = true
                    }
                    
                    if firmaReceptor != nil {
                        Text("Firma receptor guardada ✅")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // MARK: CONTRATO
                Section {

                    Button {
                        generarContrato()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Generar Contrato", systemImage: "doc.text.fill")
                            Spacer()
                        }
                    }
                }
                }
                .navigationTitle("Nuevo Préstamo Otorgado")
                .toolbar {

                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancelar") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Guardar") {
                            guardar()
                        }
                        .disabled(
                            nombre.isEmpty ||
                            montoDouble <= 0 ||
                            empresaSeleccionada == nil
                        )
                    }
                }
            
                .sheet(isPresented: $mostrarFirmaEmpresa) {
                    VStack {
                        SignatureView(data: $firmaEmpresa)
                            .padding()

                        Button("Cerrar") {
                            mostrarFirmaEmpresa = false
                        }
                        .padding()
                    }
                }

                .sheet(isPresented: $mostrarFirmaReceptor) {
                    VStack {
                        SignatureView(data: $firmaReceptor)
                            .padding()

                        Button("Cerrar") {
                            mostrarFirmaReceptor = false
                        }
                        .padding()
                    }
            
                }
                }
                }

    // MARK: CALCULOS

    private var montoDouble: Double {
        Double(montoTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    private var fechaVencimiento: Date {
        Calendar.current.date(byAdding: .month, value: plazoMeses, to: fechaInicio) ?? fechaInicio
    }

    private var tasaDouble: Double {
        Double(tasaTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private func periodosPorAño() -> Double {

        if esEmpleado && periodicidad == "Semanal" {
            return 48 // 🔥 EMPLEADO SOBRE 4 SEMANAS
        }

        switch periodicidad {
        case "Semanal": return 52
        case "Quincenal": return 24
        case "Mensual": return 12
        case "Bimestral": return 6
        default: return 12
        }
    }

    private func pagoPorPeriodo() -> Double {
        if tasaDouble == 0 {
            return montoDouble / (Double(plazoMeses) * periodosPorAño() / 12)
        }
        return montoDouble * (tasaDouble / 100) / periodosPorAño()
    }

    private func totalIntereses() -> Double {
        let años = Double(plazoMeses) / 12
        return montoDouble * (tasaDouble / 100) * años
    }

    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }

    private func imagenBase64(_ data: Data?) -> String {
        guard let data else { return "" }
        return "data:image/png;base64,\(data.base64EncodedString())"
    }
    
    // MARK: GUARDAR

    private func guardar() {

        guard let empresaSeleccionada else { return }

        let nuevo = PrestamoOtorgado(
            empresaNombre: empresaSeleccionada.nombre,
            nombre: nombre,
            apellido: apellido,
            esEmpleado: esEmpleado,
            numeroEmpleado: esEmpleado ? numeroEmpleado : nil,
            direccion: direccion,
            telefono: telefono,
            correo: correo,
            montoPrestado: montoDouble,
            tasaAnual: tasaDouble,
            plazoMeses: plazoMeses,
            fechaInicio: fechaInicio,
            fechaPrimerPago: fechaPrimerPago,
            periodicidad: periodicidad,
            notas: notas
        )

        context.insert(nuevo)

        do {
            try context.save()
        } catch {
            print("Error guardando préstamo:", error)
        }

        dismiss()
    }

    // MARK: CONTRATO AUTOMATICO

    private func generarContrato(prestamo: PrestamoOtorgado) {

        let html = """
        <html>
        <body style="font-family:-apple-system; padding:30px;">

        <h2>CONTRATO DE PRÉSTAMO</h2>

        <p><strong>Empresa:</strong> \(prestamo.empresaNombre)</p>
        <p><strong>Receptor:</strong> \(prestamo.nombre) \(prestamo.apellido)</p>
        <p><strong>Monto:</strong> \(formatoMoneda(prestamo.montoPrestado))</p>
        <p><strong>Tasa Anual:</strong> \(prestamo.tasaAnual)%</p>
        <p><strong>Plazo:</strong> \(prestamo.plazoMeses) meses</p>
        <p><strong>Periodicidad:</strong> \(prestamo.periodicidad)</p>

        <br><br><br>

        ___________________________<br>
        Firma Empresa

        <br><br><br>

        ___________________________<br>
        Firma Receptor

        </body>
        </html>
        """
        
        let formatter = UIMarkupTextPrintFormatter(markupText: html)
        let controller = UIPrintInteractionController.shared
        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    private func generarContrato() {

        let nombreCompleto = nombre + " " + apellido
        let contratoNotarial = !esEmpleado

        let html = contratoNotarial
            ? contratoParticular(nombreCompleto: nombreCompleto)
            : contratoEmpleado(nombreCompleto: nombreCompleto)

        let formatter = UIMarkupTextPrintFormatter(markupText: html)

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general

        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printFormatter = formatter
        controller.present(animated: true)
    }

    private func contratoEmpleado(nombreCompleto: String) -> String {
    """
    <html>
    <body style="font-family:-apple-system; padding:25px; font-size:13px;">

    <h2 style="text-align:center;">CONTRATO DE PRÉSTAMO INTERNO</h2>

    <p>
    La empresa <b>\(empresaSeleccionada?.nombre ?? "")</b> otorga al empleado
    <b>\(nombreCompleto)</b> un préstamo por la cantidad de
    <b>\(formatoMoneda(montoDouble))</b>.
    </p>

    <p>
    Tasa anual: \(String(format: "%.2f", tasaDouble))%<br>
    Plazo: \(plazoMeses) meses<br>
    Inicio: \(fechaInicio.formatted(date: .long, time: .omitted))<br>
    Vencimiento: \(fechaVencimiento.formatted(date: .long, time: .omitted))<br>
    Periodicidad: \(periodicidad)
    </p>

    <br><br>

    <div style="margin-top:30px; display:flex; justify-content:space-between;">

    <div style="width:45%; text-align:center;">
    \(firmaEmpresa != nil ? "<img src='\(imagenBase64(firmaEmpresa))' style='height:80px;' />" : "")
    <div style="border-top:1px solid black; margin-top:8px;">
    \(empresaSeleccionada?.nombre ?? "")
    </div>
    </div>

    <div style="width:45%; text-align:center;">
    \(firmaReceptor != nil ? "<img src='\(imagenBase64(firmaReceptor))' style='height:80px;' />" : "")
    <div style="border-top:1px solid black; margin-top:8px;">
    \(nombreCompleto)
    </div>
    </div>

    </div>

    </body>
    </html>
    """
    }

    private func contratoParticular(nombreCompleto: String) -> String {
    """
    <html>
    <body style="font-family:Times New Roman; padding:25px; line-height:1.5; font-size:13px;">

    <h2 style="text-align:center;">CONTRATO DE MUTUO CON INTERÉS</h2>

    <p>
    En la fecha \(Date().formatted(date: .long, time: .omitted)),
    comparecen por una parte <b>\(empresaSeleccionada?.nombre ?? "")</b>,
    en su carácter de <b>EL PRESTAMISTA</b>,
    y por otra parte <b>\(nombreCompleto)</b>,
    en su carácter de <b>EL ACREDITADO</b>.
    </p>

    <p>
    Monto: <b>\(formatoMoneda(montoDouble))</b><br>
    Tasa anual fija: <b>\(String(format: "%.2f", tasaDouble))%</b><br>
    Inicio: \(fechaInicio.formatted(date: .long, time: .omitted))<br>
    Vencimiento: \(fechaVencimiento.formatted(date: .long, time: .omitted))<br>
    Plazo: \(plazoMeses) meses<br>
    Pagos: \(periodicidad.lowercased())
    </p>

    <p>
    El acreditado se obliga a pagar el capital más intereses en los términos pactados.
    </p>

    <br><br>

    <div style="margin-top:30px; display:flex; justify-content:space-between;">

    <div style="width:45%; text-align:center;">
    \(firmaEmpresa != nil ? "<img src='\(imagenBase64(firmaEmpresa))' style='height:80px;' />" : "")
    <div style="border-top:1px solid black; margin-top:8px;">
    \(empresaSeleccionada?.nombre ?? "")
    <br>EL PRESTAMISTA
    </div>
    </div>

    <div style="width:45%; text-align:center;">
    \(firmaReceptor != nil ? "<img src='\(imagenBase64(firmaReceptor))' style='height:80px;' />" : "")
    <div style="border-top:1px solid black; margin-top:8px;">
    \(nombreCompleto)
    <br>EL ACREDITADO
    </div>
    </div>

    </div>

    </body>
    </html>
    """
    }
    }
