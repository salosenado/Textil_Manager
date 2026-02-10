//
//  EmpresaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  EmpresaFormView.swift
//  Textil
//

import SwiftUI
import SwiftData
import PhotosUI

struct EmpresaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var empresa: Empresa
    let esNueva: Bool

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // EMPRESA
                    FormSection(title: "Empresa") {
                        TextField("Nombre", text: $empresa.nombre)
                        Divider()
                        TextField("RFC", text: $empresa.rfc)
                        Divider()
                        TextField("Dirección", text: $empresa.direccion)
                        Divider()
                        TextField("Teléfono", text: $empresa.telefono)
                    }

                    // LOGO
                    FormSection(title: "Logo") {
                        PhotosPicker(
                            selection: $selectedItem,
                            matching: .images
                        ) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Seleccionar logo")
                                Spacer()
                            }
                            .foregroundColor(.blue)
                        }

                        if let data = empresa.logoData,
                           let image = ImageFromData(data: data) {
                            Divider()
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .cornerRadius(12)
                        }
                    }

                    // ESTADO
                    FormSection(title: "") {
                        Toggle("Activo", isOn: $empresa.activo)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNueva ? "Nueva empresa" : "Editar empresa")
            .toolbar {

                ToolbarItem(placement: .navigation) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem {
                    Button("Guardar") {
                        guardar()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                cargarLogo(from: newItem)
            }
        }
    }

    private func cargarLogo(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                empresa.logoData = data
            }
        }
    }

    private func guardar() {
        if esNueva {
            context.insert(empresa)
        }
        dismiss()
    }
}

// MARK: - Helper Imagen multiplataforma
@ViewBuilder
private func ImageFromData(data: Data) -> Image? {
    #if os(iOS)
    if let uiImage = UIImage(data: data) {
        Image(uiImage: uiImage)
    }
    #elseif os(macOS)
    if let nsImage = NSImage(data: data) {
        Image(nsImage: nsImage)
    }
    #else
    nil
    #endif
}
