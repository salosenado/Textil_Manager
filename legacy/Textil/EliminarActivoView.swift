//
//  EliminarActivoView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
import SwiftUI
import SwiftData

struct EliminarActivoView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let activo: ActivoEmpresa
    @State private var password = ""

    var body: some View {

        VStack(spacing: 24) {

            Text("Eliminar Activo")
                .font(.title2)
                .bold()

            SecureField("Contraseña", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            Button("Eliminar", role: .destructive) {
                if password == "1234" {

                    // 1️⃣ Cerrar el sheet primero
                    dismiss()

                    // 2️⃣ Esperar a que SwiftUI lo desmonte
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        context.delete(activo)
                        try? context.save()
                    }
                }
            }

            Button("Cancelar") {
                dismiss()
            }
        }
        .padding()
    }
}
