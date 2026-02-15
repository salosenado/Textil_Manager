//
//  AltaDepartamentoView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI
import SwiftData

struct AltaDepartamentoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var nombre = ""
    @State private var activo = true

    var body: some View {
        Form {
            TextField("Nombre", text: $nombre)
            Toggle("Activo", isOn: $activo)

            Button("Guardar") {
                guardar()
            }
            .disabled(nombre.isEmpty)
        }
        .navigationTitle("Nuevo Departamento")
    }

    private func guardar() {
        let departamento = Departamento()
        departamento.nombre = nombre
        departamento.activo = activo

        context.insert(departamento)
        dismiss()
    }
}
