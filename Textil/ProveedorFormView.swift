//
//  ProveedorFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  ProveedorFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct ProveedorFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var proveedor: Proveedor
    let esNuevo: Bool

    @State private var plazoTexto: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // PROVEEDOR
                    FormSection(title: "Proveedor") {
                        TextField("Nombre", text: $proveedor.nombre)
                        Divider()
                        TextField("Contacto", text: $proveedor.contacto)
                        Divider()
                        TextField("RFC", text: $proveedor.rfc)
                    }

                    // CONDICIONES DE PAGO (SIN 0)
                    FormSection(title: "Condiciones de pago") {
                        HStack {
                            Text("Plazo de pago")
                            Spacer()
                            TextField("Ej. 30", text: $plazoTexto)
                                .multilineTextAlignment(.trailing)
                            Text("días")
                                .foregroundColor(.secondary)
                        }
                        .onChange(of: plazoTexto) { _, newValue in
                            proveedor.plazoPagoDias = Int(newValue) ?? 0
                        }
                    }

                    // DIRECCIÓN
                    FormSection(title: "Dirección") {
                        TextField("Calle", text: $proveedor.calle)
                        Divider()
                        TextField("No. exterior", text: $proveedor.numeroExterior)
                        Divider()
                        TextField("No. interior", text: $proveedor.numeroInterior)
                        Divider()
                        TextField("Colonia", text: $proveedor.colonia)
                        Divider()
                        TextField("Ciudad", text: $proveedor.ciudad)
                        Divider()
                        TextField("Estado", text: $proveedor.estado)
                        Divider()
                        TextField("Código postal", text: $proveedor.codigoPostal)
                    }

                    // CONTACTO
                    FormSection(title: "Contacto") {
                        TextField("Teléfono principal", text: $proveedor.telefonoPrincipal)
                        Divider()
                        TextField("Teléfono secundario", text: $proveedor.telefonoSecundario)
                        Divider()
                        TextField("Email", text: $proveedor.email)
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $proveedor.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNuevo ? "Nuevo proveedor" : "Editar proveedor")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem {
                    Button("Guardar") {
                        guardar()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Cargar valor solo si existe
                if proveedor.plazoPagoDias > 0 {
                    plazoTexto = String(proveedor.plazoPagoDias)
                }
            }
        }
    }

    private func guardar() {
        if esNuevo {
            context.insert(proveedor)
        }
        dismiss()
    }
}

#Preview {
    ProveedorFormView(proveedor: Proveedor(), esNuevo: true)
}
