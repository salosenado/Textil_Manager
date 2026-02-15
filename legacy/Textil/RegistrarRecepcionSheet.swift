//
//  RegistrarRecepcionSheet.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
import SwiftUI

struct RegistrarRecepcionSheet: View {

    // MARK: - STATE

    @State private var pzPrimera = ""
    @State private var pzSaldo = ""
    @State private var numeroFactura = ""
    @State private var observaciones = ""

    // MARK: - CALLBACK
    // primera, saldo, observaciones, numeroFactura
    let onGuardar: (Int, Int, String?, String?) -> Void

    // MARK: - BODY

    var body: some View {
        NavigationStack {
            Form {

                // =========================
                // RECEPCIÓN
                // =========================
                Section("Recepción") {

                    TextField("Pz primera", text: $pzPrimera)
                        .keyboardType(.numberPad)

                    TextField("Pz saldo", text: $pzSaldo)
                        .keyboardType(.numberPad)
                }

                // =========================
                // NOTA / FACTURA
                // =========================
                Section("Nota / Factura") {

                    TextField("Número de nota o factura", text: $numeroFactura)
                        .textInputAutocapitalization(.characters)
                }

                // =========================
                // OBSERVACIONES
                // =========================
                Section("Observaciones") {

                    TextField("Observaciones", text: $observaciones)
                }
            }
            .navigationTitle("Registrar recepción")
            .toolbar {

                // CANCELAR
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        // ❌ el padre controla el dismiss
                    }
                }

                // GUARDAR
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {

                        onGuardar(
                            Int(pzPrimera) ?? 0,
                            Int(pzSaldo) ?? 0,
                            observaciones.isEmpty ? nil : observaciones,
                            numeroFactura.isEmpty ? nil : numeroFactura
                        )

                        // 🔥 LIMPIAR ESTADO (CLAVE)
                        pzPrimera = ""
                        pzSaldo = ""
                        numeroFactura = ""
                        observaciones = ""
                    }
                }
            }
        }
    }
}
