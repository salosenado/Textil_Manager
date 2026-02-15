//
//  PerfilView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//
//  PerfilView.swift
//  Textil
//

import SwiftUI

struct PerfilView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // =========================
                // 👤 INFO USUARIO
                // =========================
                VStack(alignment: .leading, spacing: 12) {

                    fila(titulo: "Nombre", valor: authVM.perfil?.nombre ?? "—")
                    fila(titulo: "Email", valor: authVM.perfil?.email ?? "—")
                    fila(titulo: "Rol", valor: authVM.perfil?.rol.capitalized ?? "—")

                    fila(
                        titulo: "Empresa",
                        valor: authVM.perfil?.empresa?.nombre ?? "—"
                    )

                    Divider()

                    fila(
                        titulo: "Estado",
                        valor: authVM.perfil?.activo == true ? "Activo" : "Inactivo",
                        color: authVM.perfil?.activo == true ? .green : .red
                    )
                }

                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                // =========================
                // 🔐 CERRAR SESIÓN
                // =========================
                Button(role: .destructive) {
                    Task {
                        await authVM.signOut()
                    }
                } label: {
                    Text("Cerrar sesión")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Perfil")
        }
    }

    // =========================
    // COMPONENTE FILA
    // =========================
    @ViewBuilder
    private func fila(
        titulo: String,
        valor: String,
        color: Color = .primary
    ) -> some View {
        HStack {
            Text(titulo)
                .foregroundColor(.secondary)
            Spacer()
            Text(valor)
                .foregroundColor(color)
                .bold()
        }
    }
}
