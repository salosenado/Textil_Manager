//
//  ServicioFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ServicioFormView.swift
//  ProduccionTextilClean
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ServicioFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

struct ServicioFormView: View {

    // MARK: - CONTEXTO
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - MODELO
    @Bindable var servicio: Servicio
    private let isNew: Bool

    // MARK: - UI STATE
    @State private var plazoTexto: String = ""

    // INIT NUEVO
    init() {
        let nuevo = Servicio()
        self.servicio = nuevo
        self.isNew = true
    }

    // INIT EDITAR
    init(servicio: Servicio) {
        self.servicio = servicio
        self.isNew = false
        _plazoTexto = State(initialValue: servicio.plazoPagoDias > 0 ? "\(servicio.plazoPagoDias)" : "")
    }

    var body: some View {
        NavigationStack {
            Form {

                // SERVICIO
                Section("Servicio") {
                    TextField("Nombre del servicio", text: $servicio.nombre)
                }

                // CONDICIONES
                Section("Condiciones") {
                    HStack {
                        Text("Plazo de pago")
                        Spacer()
                        TextField("Días", text: $plazoTexto)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)

                        Text("días")
                            .foregroundStyle(.secondary)
                    }
                }

                // ESTADO
                Section {
                    Toggle("Activo", isOn: $servicio.activo)
                }
            }
            .navigationTitle(isNew ? "Nuevo servicio" : "Editar servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // CANCELAR
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                // GUARDAR
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardar()
                    }
                    .disabled(servicio.nombre.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if servicio.plazoPagoDias > 0 {
                    plazoTexto = "\(servicio.plazoPagoDias)"
                }
            }
        }
    }

    // MARK: - GUARDAR
    private func guardar() {
        servicio.plazoPagoDias = Int(plazoTexto) ?? 0

        if isNew {
            context.insert(servicio)
        }

        do {
            try context.save()
            dismiss()
        } catch {
            print("❌ Error guardando servicio:", error)
        }
    }
}
