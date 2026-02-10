//
//  TelaFormView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  TelaFormView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct TelaFormView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var tela: Tela
    let esNueva: Bool

    @State private var preciosTemp: [String: String] = [:]

    private let tiposPrecio = [
        "Blanco",
        "Claro",
        "Medio",
        "Obscuro",
        "Jaspe",
        "Negro",
        "Único precio"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // INFORMACIÓN
                    FormSection(title: "Información") {
                        TextField("Nombre de la tela", text: $tela.nombre)
                        Divider()
                        TextField("Composición (ej. 100% Algodón)", text: $tela.composicion)
                        Divider()
                        TextField("Proveedor", text: $tela.proveedor)
                        Divider()
                        TextField("Descripción", text: $tela.descripcion, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    // PRECIOS
                    FormSection(title: "Precios de referencia (MX)") {
                        ForEach(tiposPrecio, id: \.self) { tipo in
                            HStack {
                                Text(tipo)
                                Spacer()
                                Text("MX $")
                                    .foregroundColor(.secondary)

                                TextField(
                                    "0.00",
                                    text: Binding(
                                        get: { preciosTemp[tipo] ?? "" },
                                        set: { preciosTemp[tipo] = $0 }
                                    )
                                )
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 90)
                            }

                            if tipo != tiposPrecio.last {
                                Divider()
                            }
                        }
                    }

                    // ESTADO
                    FormSection(title: "Estado") {
                        Toggle("Activa", isOn: $tela.activa)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle(esNueva ? "Nueva tela" : "Editar tela")
            .toolbar {

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        guardarPrecios()
                        if esNueva {
                            context.insert(tela)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Guardar historial de precios
    private func guardarPrecios() {
        for (tipo, valor) in preciosTemp {
            if let precio = Double(valor.replacingOccurrences(of: ",", with: "")) {
                let nuevoPrecio = PrecioTela(
                    tipo: tipo,
                    precio: precio,
                    fecha: .now
                )
                tela.precios.append(nuevoPrecio)
            }
        }
    }
}
