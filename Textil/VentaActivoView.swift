//
//  VentaActivoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct VentaActivoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let activo: ActivoEmpresa
    @State private var precioVenta = ""

    var body: some View {

        VStack(spacing: 24) {

            Text("Registrar Venta")
                .font(.title2)
                .bold()

            Text("Activo: \(activo.articulo)")
                .foregroundStyle(.secondary)

            TextField("Precio de venta", text: $precioVenta)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            Button("Confirmar Venta") {

                guard
                    let venta = Double(precioVenta),
                    venta > 0
                else { return }

                activo.vendido = true
                activo.precioVenta = venta
                activo.fechaVenta = Date()

                try? context.save()

                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(Double(precioVenta) ?? 0 <= 0)

            Button("Cancelar") {
                dismiss()
            }
        }
        .padding()
    }
}
