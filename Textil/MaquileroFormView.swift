//
//  MaquileroFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  MaquileroFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct MaquileroFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var maquilero: Maquilero
    let esNuevo: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    FormSection(title: "Maquilero") {
                        TextField("Nombre", text: $maquilero.nombre)
                        Divider()
                        TextField("Contacto", text: $maquilero.contacto)
                    }

                    FormSection(title: "Dirección") {
                        TextField("Calle", text: $maquilero.calle)
                        Divider()
                        TextField("No. exterior", text: $maquilero.numeroExterior)
                        Divider()
                        TextField("No. interior", text: $maquilero.numeroInterior)
                        Divider()
                        TextField("Colonia", text: $maquilero.colonia)
                        Divider()
                        TextField("Ciudad", text: $maquilero.ciudad)
                        Divider()
                        TextField("Estado", text: $maquilero.estado)
                        Divider()
                        TextField("Código postal", text: $maquilero.codigoPostal)
                    }

                    FormSection(title: "Contacto") {
                        TextField("Teléfono principal", text: $maquilero.telefonoPrincipal)
                        Divider()
                        TextField("Teléfono secundario", text: $maquilero.telefonoSecundario)
                    }

                    FormSection(title: "Estado") {
                        Toggle("Activo", isOn: $maquilero.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(esNuevo ? "Nuevo maquilero" : "Editar maquilero")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        if esNuevo {
                            context.insert(maquilero)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
