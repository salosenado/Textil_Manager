//
//  RegistrarCobroView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  RegistrarCobroView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct RegistrarCobroView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let venta: VentaCliente

    @Query private var cobros: [CobroVenta]

    @State private var pagos: [MovimientoTemp] = []

    // MARK: - COBROS DE ESTA VENTA

    var cobrosDeEstaVenta: [CobroVenta] {
        cobros.filter {
            $0.venta == venta && $0.fechaEliminacion == nil
        }
    }

    // MARK: - CÁLCULOS

    var subtotal: Double {
        venta.detalles.reduce(0) {
            $0 + Double($1.cantidad) * $1.costoUnitario
        }
    }

    var iva: Double {
        venta.aplicaIVA ? subtotal * 0.16 : 0
    }

    var totalVenta: Double {
        subtotal + iva
    }

    var totalCobrado: Double {
        cobrosDeEstaVenta.reduce(0) { $0 + $1.monto }
    }

    var saldo: Double {
        totalVenta - totalCobrado
    }

    // MARK: - BODY

    var body: some View {

        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    resumenView()

                    // 🔵 COBROS EXISTENTES
                    if !cobrosDeEstaVenta.isEmpty {

                        VStack(alignment: .leading, spacing: 12) {

                            Text("Cobros registrados")
                                .font(.headline)

                            ForEach(cobrosDeEstaVenta) { cobro in

                                VStack(alignment: .leading, spacing: 10) {

                                    HStack {
                                        Text("MX$ \(formatear(cobro.monto))")
                                            .font(.headline)

                                        Spacer()

                                        Text(
                                            cobro.fechaCobro.formatted(
                                                date: .abbreviated,
                                                time: .omitted
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }

                                    HStack(spacing: 16) {

                                        Button {
                                            editarCobro(cobro)
                                        } label: {
                                            Label("Editar", systemImage: "pencil")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.bordered)

                                        Button {
                                            eliminarCobro(cobro)
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)

                                        Spacer()
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }

                    // 🔵 NUEVO COBRO
                    movimientosView()
                }
                .padding()
            }
            .navigationTitle("Registrar Cobro")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { guardar() }
                }
            }
        }
    }

    // MARK: - RESUMEN

    func resumenView() -> some View {
        VStack(alignment: .leading, spacing: 8) {

            filaInfo("Venta #", venta.folio)

            if !venta.numeroFactura.isEmpty {
                filaInfo("Factura / Nota", venta.numeroFactura)
            }

            Divider()

            resumenRow("Subtotal", subtotal)
            resumenRow("IVA", iva)
            resumenRow("Total Venta", totalVenta, bold: true)

            Divider()

            resumenRow(
                "Cobrado",
                totalCobrado,
                color: .green
            )

            resumenRow(
                "Saldo",
                saldo,
                color: saldo > 0 ? .red : .green,
                bold: true
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    // MARK: - NUEVO COBRO

    func movimientosView() -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Text("Nuevo cobro")
                    .font(.headline)

                Spacer()

                Button {
                    pagos.append(MovimientoTemp())
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            ForEach(pagos.indices, id: \.self) { index in

                VStack(spacing: 8) {

                    HStack {
                        Spacer()
                        Button {
                            pagos.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }

                    HStack {
                        Text("MX$")
                            .bold()

                        TextField(
                            "0.00",
                            text: $pagos[index].montoTexto
                        )
                        .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                    )

                    DatePicker(
                        "Fecha",
                        selection: $pagos[index].fecha,
                        displayedComponents: .date
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3))
                )
                .cornerRadius(14)
            }
        }
    }

    // MARK: - GUARDAR

    func guardar() {

        for item in pagos where item.monto > 0 {

            let cobro = CobroVenta(
                fechaCobro: item.fecha,
                monto: item.monto,
                referencia: "",
                observaciones: "",
                venta: venta
            )

            context.insert(cobro)
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }

        pagos.removeAll()
    }

    // MARK: - ELIMINAR

    func eliminarCobro(_ cobro: CobroVenta) {
        cobro.fechaEliminacion = Date()
        try? context.save()
    }

    // MARK: - EDITAR (seguro)

    func editarCobro(_ cobro: CobroVenta) {

        pagos.append(
            MovimientoTemp(
                montoTexto: String(format: "%.2f", cobro.monto),
                fecha: cobro.fechaCobro
            )
        )

        eliminarCobro(cobro)
    }

    // MARK: - HELPERS

    func filaInfo(_ titulo: String, _ valor: String) -> some View {
        HStack {
            Text(titulo)
                .foregroundStyle(.secondary)
            Spacer()
            Text(valor)
                .fontWeight(.semibold)
        }
    }

    func resumenRow(
        _ titulo: String,
        _ valor: Double,
        color: Color = .primary,
        bold: Bool = false
    ) -> some View {

        HStack {
            Text(titulo)
            Spacer()
            Text("MX$ \(formatear(valor))")
                .foregroundStyle(color)
                .fontWeight(bold ? .bold : .regular)
        }
    }

    func formatear(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ","
        formatter.decimalSeparator = "."
        return formatter.string(from: NSNumber(value: valor)) ?? "0.00"
    }
}

// MARK: - TEMP MODEL

struct MovimientoTemp: Identifiable {

    let id = UUID()
    var montoTexto: String = ""
    var fecha: Date = Date()

    var monto: Double {
        Double(montoTexto.replacingOccurrences(of: ",", with: "")) ?? 0
    }
}
