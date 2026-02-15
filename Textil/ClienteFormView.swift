//
//  ClienteFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ClienteFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ClienteFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var cliente: Cliente
    let esNuevo: Bool

    @State private var plazoTexto: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // INFORMACIÓN
                    FormSection(title: "Información") {
                        TextField("Nombre comercial", text: $cliente.nombreComercial)
                        Divider()
                        TextField("Razón social", text: $cliente.razonSocial)
                        Divider()
                        TextField("RFC", text: $cliente.rfc)
                    }

                    // CRÉDITO (YA SIN CEROS)
                    FormSection(title: "Crédito") {

                        // PLAZO
                        HStack {
                            Text("Plazo (días)")
                            Spacer()
                            TextField("Ej. 30", text: $plazoTexto)
                                .multilineTextAlignment(.trailing)
                        }
                        .onChange(of: plazoTexto) { _, newValue in
                            cliente.plazoDias = Int(newValue) ?? 0
                        }

                        Divider()

                        // LÍMITE DE CRÉDITO
                        HStack {
                            Text("Límite de crédito")
                            Spacer()
                            Text("MX $")
                                .foregroundColor(.secondary)

                            NumericTextField(
                                placeholder: "Ej. 25,000.00",
                                value: $cliente.limiteCredito
                            )
                            .frame(width: 140)
                        }
                    }

                    // CONTACTO
                    FormSection(title: "Contacto") {
                        TextField("Contacto", text: $cliente.contacto)
                        Divider()
                        TextField("Teléfono", text: $cliente.telefono)
                        Divider()
                        TextField("Email", text: $cliente.email)
                    }

                    // DIRECCIÓN
                    FormSection(title: "Dirección") {
                        TextField("Calle", text: $cliente.calle)
                        Divider()
                        TextField("Número", text: $cliente.numero)
                        Divider()
                        TextField("Colonia", text: $cliente.colonia)
                        Divider()
                        TextField("Ciudad", text: $cliente.ciudad)
                        Divider()
                        TextField("Estado", text: $cliente.estado)
                        Divider()
                        TextField("País", text: $cliente.pais)
                        Divider()
                        TextField("Código Postal", text: $cliente.codigoPostal)
                    }

                    // OBSERVACIONES
                    FormSection(title: "Observaciones") {
                        TextEditor(text: $cliente.observaciones)
                            .frame(height: 100)
                    }

                    // ACTIVO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $cliente.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(esNuevo ? "Nuevo cliente" : "Editar cliente")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar Cliente") {
                        if esNuevo {
                            context.insert(cliente)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if cliente.plazoDias > 0 {
                    plazoTexto = String(cliente.plazoDias)
                }
            }
        }
    }
}
